---
title: "Payjoin POC: Implementing no_std on payjoin ecosystem"
date: 2026-03-24
draft: false
description: "This logbook documents my journey through the Vinteum Bitcoin Developer Launchpad PoC."
---

When I started this POC through the Vinteum Bitcoin Developer Launchpad, the goal was straightforward: make the `payjoin` crate compile and run correctly in a `no_std` environment. What followed was a deep dive into Rust's feature system, embedded targets, and the subtle ways that `std` leaks into code you think is clean.

## The problem

Most Rust crates are written with `std` as an implicit assumption. Strings, collections, error traits, I/O — all of it silently pulls in the standard library. For hardware signers and embedded environments, this is a hard blocker. The `payjoin` crate needed to work without it.

The goal: make `cargo build -p payjoin --no-default-features --features "v2,alloc"` pass cleanly.

## First attempts

The early builds failed in expected ways. The `wasm32-unknown-unknown` target broke immediately because `getrandom` doesn't support it without specific flags. Switching to `thumbv7em-none-eabihf` got further, but hit a wall at `secp256k1-sys`, which requires `arm-none-eabi-gcc` to compile its C bindings.

The pattern became clear early: dependency graphs are deep, and `std` assumptions hide everywhere — in `openssl-sys`, in `serde_json`, in anything that touches I/O or time.

## Isolating std

The core approach was systematic replacement:

- `std::string::String` → `alloc::string::String`
- `std::vec::Vec` → `alloc::vec::Vec`
- `std::collections::BTreeMap` → `alloc::collections::BTreeMap`
- `std::error::Error` → `core::error::Error`

Any module touching I/O, HTTP, JSON, OHTTP, or system time got gated behind `#[cfg(feature = "std")]`. In `no_std` builds, those paths return a clear implementation error instead of silently failing or pulling in unwanted dependencies.

## The tests lie

One of the most important lessons: **passing tests don't guarantee `no_std` compatibility.**

The test harness implicitly enables `std`. A build that passes `cargo test` can still fail `cargo build --no-default-features`. The only way to verify real `no_std` compatibility is to run the build directly, without the test harness enabling `std` behind the scenes.

This led to a validation script that became the standard check throughout the POC:
```bash
clear && \
cargo build -p payjoin --no-default-features --features "v2,alloc" && \
cargo build -p payjoin --no-default-features --features "std,v2" && \
cargo test  -p payjoin --no-default-features --features "alloc,v2" && \
cargo test  -p payjoin --no-default-features --features "std,v2"
```

## Feature gating and the URI parser

The V1/V2 URI parser required careful feature gating. V1 (BIP 78) uses only `OH1` in the fragment. V2 (BIP 77) requires `RK1+OH1+EX1`. When running with only `--features "v2"`, the entire V1 code path is removed from compilation — tests that referenced `PjParam::V1` simply didn't compile.

The fix was adding `#[cfg(feature = "v1")]` to 9 tests and `#[cfg(all(feature = "v1", feature = "v2"))]` to tests covering the V2→V1 fallback path. After gating, 142 tests ran clean on V2-only builds and 163 on V1+V2.

## Architectural decision

Functions that depend on I/O, HTTP parsing, JSON, or system time are `std`-only. There's no stub, no workaround. In `no_std` builds, those paths fail explicitly. This keeps the core protocol — state machine, fallback transaction, PSBT handling, URI parsing — genuinely portable without hidden compromises.

## What works in no_std

By the end of the POC, the following were fully functional under `no_std + alloc`:

- State machine for V2 sessions
- Fallback transaction parsing and processing
- URI parsing with V2 parameters
- Core collections and type handling via `alloc`

## Commit history

The final step was a full interactive rebase to clean the commit tree. Two months of "broke and fixed" commits were squashed into a coherent narrative showing the real progression of `no_std` support. The branch `poc/no-std-payjoin` reflects the work as it should be read, not as it was written.

## Takeaways

- `no_std` compatibility requires explicit architecture decisions, not just `#[cfg]` patches
- Feature flags in Cargo remove code completely — design around that, don't fight it  
- The test harness enables `std`; always verify with a direct build
- `core::error::Error` is available in recent Rust without `std`
- Dependency graphs carry `std` assumptions deep — audit early
