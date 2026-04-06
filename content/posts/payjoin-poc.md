---
title: "Payjoin POC: Implementing no_std on the payjoin ecosystem"
date: 2026-03-24
draft: false
description: "This logbook documents my journey through the Vinteum Bitcoin Developer Launchpad PoC."
---

When I started this POC through the Vinteum Bitcoin Developer Launchpad, the goal was straightforward: make the payjoin crate compile and run correctly in a `no_std` environment. What followed was a deep dive into Rust's feature system, embedded targets, and the subtle ways that `std` leaks into code you think is clean.

## The problem

Most Rust crates are written with `std` as an implicit assumption. Strings, collections, error traits, I/O — all of it silently pulls in the standard library. For hardware signers and embedded environments running on targets like `thumbv7em-none-eabihf`, this is a hard blocker. The payjoin crate needed to work without it.

The goal: make `cargo build -p payjoin --no-default-features --features "v2,alloc" --target thumbv7em-none-eabihf` pass cleanly.

## First attempts

The early builds failed in expected ways. The `wasm32-unknown-unknown` target broke immediately because `getrandom` doesn't support it without specific flags. Switching to `thumbv7em-none-eabihf` got further, but dependencies like `serde`, `log`, `once_cell`, and `parking_lot` don't support `no_std` on that target at all — these simply can't be pulled in from the workspace in a `no_std` build.

The key insight was that the correct command is always `-p payjoin`, not a bare workspace build. `payjoin-ffi`, `payjoin-cli`, and `payjoin-fuzz` are inherently `std`-only crates and were never meant to run on embedded targets.

## Isolating std

The core approach was systematic replacement across the entire crate:

- `std::string::String` → `alloc::string::String`
- `std::vec::Vec` → `alloc::vec::Vec`
- `std::collections::BTreeMap` → `alloc::collections::BTreeMap`
- `std::fmt` → `core::fmt`
- `std::str::from_utf8` → `core::str::from_utf8`
- `std::error::Error` → `core::error::Error` (available since Rust 1.81 without `std`)

Any module touching I/O, HTTP, JSON, OHTTP, or system time got gated behind `#[cfg(feature = "std")]` or `#[cfg(feature = "v2-std")]`. In `no_std` builds, those paths return a clear `ImplementationError::std_required()` instead of silently failing or pulling in unwanted dependencies.

A new feature hierarchy was established:

```toml
alloc = []
std = ["alloc", "bitcoin/rand-std", ...]
v2 = ["_core", "directory"]           # no_std compatible
v2-std = ["v2", "std", "dep:url", "dep:hpke", "dep:ohttp", "dep:bhttp", "dep:http"]
v2-ohttp = ["v2-std", ...]            # full networking stack
```

## The tests lie

One of the most important lessons: **passing tests don't guarantee `no_std` compatibility.**

The test harness implicitly enables `std`. A build that passes `cargo test` can still fail `cargo build --no-default-features`. The only way to verify real `no_std` compatibility is to build directly against the embedded target, without the test harness enabling `std` behind the scenes.

This led to a validation command that became the standard check throughout the POC:

```bash
cargo build -p payjoin --no-default-features --features "v2,alloc" --target thumbv7em-none-eabihf && \
cargo build -p payjoin --no-default-features --features "std,v2" && \
./contrib/lint.sh && \
./contrib/test.sh
```

## The persist layer: adding save_async

A significant part of the work was extending the persistence layer. The `AsyncSessionPersister` trait's `load` method was missing a `+ Send` bound on its return type, causing type mismatches across the codebase:

```rust
// Before
Box<dyn Iterator<Item = Self::SessionEvent>>

// After
Box<dyn Iterator<Item = Self::SessionEvent> + Send>
```

Beyond that, five transition types were missing `save_async` implementations entirely — `MaybeFatalTransition`, `MaybeTransientTransition`, `MaybeSuccessTransitionWithNoResults`, `MaybeFatalTransitionWithNoResults`, and `MaybeFatalOrSuccessTransition`. Each followed the same pattern as the existing `MaybeSuccessTransition`:

```rust
#[cfg(feature = "std")]
pub async fn save_async<P>(self, persister: &P) -> Result<...>
where
    P: AsyncSessionPersister<SessionEvent = Event>,
    Err: core::error::Error + Send,
    // + Send bounds for each generic that appears in the return type
{
    let (actions, outcome) = self.deconstruct();
    actions.execute_async(persister).await.map_err(InternalPersistedError::Storage)?;
    Ok(outcome.map_err(InternalPersistedError::Api)?)
}
```

The rule is simple: copy the return type from the synchronous `save`, swap `SessionPersister` for `AsyncSessionPersister`, and add `Send` bounds for every generic that appears in the return.

## Feature gating and the URI parser

The V1/V2 URI parser required careful feature gating. `DeserializeParams` and `SerializeParams` implementations for `MaybePayjoinExtras` were gated as `v2-std`-only, which broke `v1` builds that also need URI parsing. The fix was expanding the gates:

```rust
// Before
#[cfg(feature = "v2-std")]
impl bitcoin_uri::de::DeserializeParams<'_> for MaybePayjoinExtras { ... }

// After
#[cfg(any(feature = "v1", feature = "v2-std"))]
impl bitcoin_uri::de::DeserializeParams<'_> for MaybePayjoinExtras { ... }
```

Similarly, `status_code()` on `JsonReply` was gated as `v2-std`-only but used by the `v1` CLI. The same pattern applied — widen the gate to `any(feature = "v1", feature = "v2-std")`.

## The HPKE bug

The most subtle bug in the entire process was in `ohttp.rs`. During the `no_std` refactor, `process_ohttp_res` was changed to use a new `ohttp_decapsulate_bytes` helper that skipped bhttp parsing:

```rust
// Broken: skips bhttp parsing, returns raw bytes without status code
let res = ohttp_decapsulate_bytes(ohttp_context, response_array.to_vec())?;
Ok(http::Response::new(res))
```

The original correctly parsed the bhttp response including the HTTP status code:

```rust
// Correct: full bhttp parsing preserves status code and body structure
ohttp_decapsulate(ohttp_context, response_array)
    .map_err(|e| match e {
        OhttpEncapsulationError::Ohttp(e) => DirectoryResponseError::OhttpDecapsulation(e),
        _ => DirectoryResponseError::InvalidSize(0),
    })
```

Without the status code, the sender couldn't distinguish between a successful response and an error response, causing the HPKE decryption to fail with `OpenError` — the key used to encrypt didn't match what was expected on the other side.

A related bug: `ResponseError::from_slice` was parsing zero-padded plaintext directly. The original code in `send/v2/mod.rs` stripped null bytes before JSON parsing:

```rust
let trimmed_bytes = bytes.split(|&byte| byte == 0).next().unwrap_or(bytes);
```

Without this trim, `serde_json::from_slice` would fail on the padding zeros, falling through to `Psbt::deserialize` which then returned `InvalidMagic`.

## Architectural decision

Functions that depend on I/O, HTTP parsing, JSON, or system time are `std`-only. There's no stub, no workaround. In `no_std` builds, those paths fail explicitly with `ImplementationError::std_required()`. This keeps the core protocol — state machine, fallback transaction, PSBT handling, URI parsing — genuinely portable without hidden compromises.

## What works in no_std

By the end of the POC, the following were fully functional under `no_std + alloc`:

- State machine for V2 sessions
- Fallback transaction parsing and processing
- URI parsing with V2 parameters (RK1, OH1, EX1)
- Core collections and type handling via `alloc`
- PSBT validation and processing

## Takeaways

- `no_std` compatibility requires explicit architecture decisions, not just `#[cfg]` patches
- Feature flags in Cargo remove code completely — design around that, don't fight it
- The test harness enables `std`; always verify with a direct build against the embedded target
- `core::error::Error` is available in recent Rust without `std`
- Dependency graphs carry `std` assumptions deep — audit early
- A missing `+ Send` bound or a missing `save_async` causes cascading type errors — start from the core trait and work outward
- The `--locked` flag in CI requires your lock files to stay in sync with your `Cargo.toml` after any dependency changes
