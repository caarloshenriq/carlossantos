+++
title = "BIP 78 & BIP 77: Understanding Payjoin from the Ground Up"
date = 2026-05-17
draft = false
tags = ["bitcoin", "privacy", "payjoin", "bip78", "bip77", "psbt", "rust"]
description = "A deep dive into Bitcoin's Payjoin protocol — how BIP 78 and BIP 77 work, what problems they solve, and the cryptographic primitives that make them possible."
+++

> I wrote this article while studying BIP 77 and BIP 78 as part of my contributions to the
> [`rust-payjoin`](https://github.com/payjoin/rust-payjoin) project. These are my notes turned
> into a structured explanation. If something feels like it's being explained to someone learning
> it for the first time — that's because it was.

## The Privacy Problem with Ordinary Bitcoin Transactions

When Alice sends bitcoin to Bob in a typical transaction, the structure is simple and predictable:

```
Inputs:
  - Alice's UTXO: 5,000 sats

Outputs:
  - Bob receives:    2,000 sats
  - Alice's change:  2,998 sats  (fee: 2 sats)
```

This looks clean. But to a blockchain analyst, it's an open book.

Two heuristics immediately apply:

**1. Common Input Ownership Heuristic**
All inputs in a transaction are assumed to belong to the same person. If Alice spends two UTXOs
in one transaction, an analyst assumes both came from her wallet — and now they can link multiple
addresses to her identity.

**2. Change Output Heuristic**
The output that looks like "change" (an odd amount, or the one going back to a known address
pattern) gets identified as belonging to the sender. Now the analyst knows Alice's change address
and can follow her funds into the next transaction.

These two heuristics together allow surveillance companies to build detailed transaction graphs,
tracing where money came from and where it's going across the entire blockchain.

Payjoin was designed to break both of them.

---

## What is Payjoin?

Payjoin is a protocol where **both the sender and the receiver contribute inputs** to the same
transaction. Instead of Alice being the only one spending UTXOs, Bob also puts one of his UTXOs
into the mix.

The resulting transaction looks like this:

```
Inputs:
  - Alice's UTXO:  5,000 sats   ← signed by Alice
  - Bob's UTXO:    1,000 sats   ← signed by Bob

Outputs:
  - Bob receives:  3,994 sats   (2,000 payment + 1,000 Bob's own UTXO back - fee)
  - Alice's change: 1,998 sats
```

Now an analyst looking at this transaction faces a problem:

- Who owns the inputs? There are two — they could belong to two different people.
- Which output is the payment? Which is change? It's no longer obvious.
- The common input ownership heuristic breaks. The change heuristic breaks.

The transaction is indistinguishable from a normal two-party spend. **Privacy is achieved without
any new cryptography, without Lightning, without any alteration to the base Bitcoin protocol.**

And as a bonus: Bob just consolidated UTXOs into one, saving on future transaction fees.

---

## Before Going Further: What is a PSBT?

To understand how Payjoin works mechanically, you need to understand **PSBT — Partially Signed
Bitcoin Transaction** (defined in BIP 174).

A regular Bitcoin transaction that gets broadcast to the network must have **all inputs fully
signed** by the private keys of their respective owners. But what if you need to build a
transaction collaboratively, with multiple parties each signing only their own inputs?

That's exactly what PSBT enables.

A PSBT is a **structured container** that holds:

- The transaction being constructed (inputs, outputs, amounts)
- Metadata needed to sign each input (UTXO data, redeem scripts, derivation paths)
- Partial signatures — each party signs only the inputs they own

Think of it as a **shared document that gets passed around** until everyone has signed their part,
after which it gets finalized and broadcast.

```
┌─────────────────────────────────────────────┐
│                    PSBT                     │
│                                             │
│  Global:  unsigned transaction skeleton     │
│                                             │
│  Input 0: UTXO info + Alice's signature     │
│  Input 1: UTXO info + [Bob signs here]      │
│                                             │
│  Output 0: 3,994 sats → Bob                 │
│  Output 1: 1,998 sats → Alice (change)      │
└─────────────────────────────────────────────┘
```

Key properties:

- **No party ever holds another party's private key.** Each signs only what's theirs.
- **The PSBT can be serialized** (base64 encoded) and passed over HTTP, QR codes, files, etc.
- **It can be partially finalized** — some inputs signed, others not yet.

This is the foundation on which Payjoin is built.

---

## BIP 78 — Synchronous Payjoin (V1)

BIP 78, authored by Nicolas Dorier, is the original Payjoin specification. It defines a simple
HTTP-based protocol where Alice (sender) and Bob (receiver) collaborate to build a Payjoin
transaction in real time.

### The BIP 21 URI

Everything starts with a **BIP 21 payment URI** — the same format used by wallets like BlueWallet
to encode a payment request as a QR code. BIP 78 extends this URI with a new parameter: `pj=`.

```
bitcoin:bc1qbob...?amount=0.00002&pj=https://bob-server.com/payjoin
```

- `amount`: how much Alice should pay (2,000 sats in our example)
- `pj`: the HTTPS endpoint on Bob's server that handles Payjoin

When Alice's wallet scans this QR code, it knows two things: the amount to pay and that Bob
supports Payjoin.

### The Full Flow — Step by Step

```
Alice's Wallet                          Bob's Server
      │                                       │
      │  1. Scan QR → parse BIP 21 URI        │
      │                                       │
      │  2. Build Original PSBT               │
      │     Inputs:  Alice's UTXOs            │
      │     Outputs: 2,000 sats → Bob         │
      │              change → Alice           │
      │     Signs her own inputs              │
      │                                       │
      │──── POST Original PSBT ──────────────▶│
      │                                       │  3. Bob receives PSBT
      │                                       │  4. Bob validates Alice's proposal
      │                                       │  5. Bob adds his own UTXOs as inputs
      │                                       │  6. Bob adjusts outputs (consolidates)
      │                                       │  7. Bob signs his inputs only
      │                                       │
      │◀─── Payjoin Proposal PSBT ────────────│
      │                                       │
      │  8. Alice validates the proposal:     │
      │     - Is she still paying 2,000 sats? │
      │     - Did Bob add unexpected outputs? │
      │     - Are her inputs still intact?    │
      │                                       │
      │  9. Alice re-signs her inputs         │
      │ 10. Alice broadcasts to the network   │
      │                                       │
```

### What Bob Can and Cannot Do

BIP 78 defines strict rules for what Bob is allowed to modify in the Payjoin Proposal PSBT:

**Bob MUST:**

- Keep all of Alice's inputs from the Original PSBT
- Keep all outputs not belonging to him
- Only sign his own added inputs

**Bob MAY:**

- Add his own UTXOs as additional inputs
- Add, replace, or consolidate his own output (unless output substitution is disabled)
- Slightly adjust the fee

**Bob MUST NOT:**

- Remove or modify Alice's inputs
- Change the amount Alice is paying
- Shuffle the order of inputs/outputs in a detectable pattern
- Finalize Alice's inputs (he doesn't have her private key)

Alice enforces all of this before she re-signs. If Bob violates any rule, Alice aborts and falls
back to broadcasting the Original PSBT as a regular transaction — no Payjoin, but also no loss
of funds.

### The Consolidation Benefit in Detail

Let's say Bob has accumulated some dust UTXOs from previous payments:

```
Bob's wallet BEFORE Payjoin:
  UTXO A:  500 sats
  UTXO B:  500 sats
  (plus whatever he's about to receive)

Alice wants to pay Bob 2,000 sats.
Bob adds both UTXOs to the Payjoin transaction:

Inputs:
  - Alice's UTXO:  5,000 sats  ← Alice signs
  - Bob's UTXO A:    500 sats  ← Bob signs
  - Bob's UTXO B:    500 sats  ← Bob signs

Outputs:
  - Bob receives:  2,994 sats  (2,000 payment + 500 + 500 - 6 sats fee)
  - Alice change:  2,994 sats

Bob's wallet AFTER Payjoin:
  UTXO:  2,994 sats  ← one clean UTXO instead of three
```

Three UTXOs became one. Bob paid almost nothing for this consolidation — Alice's payment covered
most of the transaction fee. In periods of high mempool congestion, this is enormously valuable
because small UTXOs can become uneconomical to spend on their own (the fee to spend them exceeds
their value).

### The Critical Limitation of BIP 78

For this protocol to work, **Bob must be running a live HTTPS server at the exact moment Alice
sends her PSBT.**

This is a serious constraint:

- Bob must have a publicly reachable domain or Tor hidden service
- Bob's server must be online and responsive in real time
- Bob must respond to Alice's HTTP POST within a short timeout window

In practice, this means **only merchants with dedicated infrastructure** (like BTCPay Server) can
be Payjoin receivers under BIP 78. A regular user wanting to receive a private payment on their
phone simply cannot participate.

This is the problem BIP 77 was designed to solve.

---

## BIP 78 vs Regular Transaction — Privacy Comparison

```
Regular transaction (what an analyst sees):
┌─────────────────────────────────────────────┐
│ Input:  5,000 sats                          │
│                          ┌──▶ 2,000 sats    │  ← payment (obvious)
│                          └──▶ 2,998 sats    │  ← change  (obvious)
└─────────────────────────────────────────────┘
Conclusion: Alice paid Bob exactly 2,000 sats. Alice has 2,998 sats left.
            Alice's change address is now known. Her funds can be tracked.

Payjoin transaction (what an analyst sees):
┌─────────────────────────────────────────────┐
│ Input:  5,000 sats  ← whose?                │
│ Input:  1,000 sats  ← whose?                │
│                          ┌──▶ 3,994 sats    │  ← payment? change? unclear
│                          └──▶ 1,998 sats    │  ← payment? change? unclear
└─────────────────────────────────────────────┘
Conclusion: ??? Two inputs from possibly two different people.
            Could be a coinjoin. Could be a merchant batch payment.
            Both heuristics fail. The analyst cannot proceed with confidence.
```

---

## BIP 77 — Async Payjoin (V2)

BIP 77, authored by Dan Gould and Yuval Kogman, is the evolution of BIP 78 that removes the
server requirement entirely by introducing an asynchronous, end-to-end encrypted messaging layer.

### The Core Insight

The PSBT exchange between Alice and Bob doesn't need to happen in real time. Bob doesn't need
to be online when Alice sends her PSBT — as long as there's a place to leave the message, Bob
can pick it up later and respond when he's ready.

BIP 77 introduces the **Payjoin Directory**: a simple store-and-forward server that acts as a
mailbox between Alice and Bob.

```
Alice                  Directory               Bob
  │                       │                     │
  │── deposit PSBT ──────▶│                     │
  │                       │◀─── poll ───────────│
  │                       │─── return PSBT ────▶│
  │                       │                     │ (Bob adds inputs, signs)
  │◀─── poll ─────────────│                     │
  │── pick up response ───│◀── deposit reply ───│
  │                       │                     │
  │ (Alice verifies, signs, broadcasts)         │
```

This is the same logical flow as BIP 78 — but now it's **asynchronous**. Alice and Bob don't
need to be online at the same time. Bob doesn't need to host a server. The analogy is apt:
BIP 78 is a phone call. BIP 77 is email.

The BIP 21 URI still looks similar, but now the `pj=` parameter points to the Directory mailbox:

```
bitcoin:bc1qbob...?amount=0.00002&pj=https://directory.payjoin.org/<bob-short-id>
```

### Why Trusting the Directory is Safe

Here's the elegant part: **the Directory is explicitly untrusted.** It's designed to be run by
anyone, and the protocol doesn't require you to trust whoever operates it. This is achieved
through two cryptographic mechanisms: **HPKE** and **OHTTP**.

---

## HPKE — Hybrid Public Key Encryption

HPKE (defined in RFC 9180) is the encryption scheme used to ensure that only Alice and Bob can
read each other's messages — not the Directory, not anyone else on the network.

### Why "Hybrid"?

Asymmetric cryptography (public/private key pairs) is powerful but computationally expensive for
encrypting large payloads. Symmetric cryptography (a single shared key) is fast and efficient
but has a bootstrap problem: how do two parties agree on a shared secret without already having
a secure channel?

HPKE solves this by combining both:

1. **Use asymmetric crypto** to securely derive a shared symmetric key
2. **Use symmetric crypto** to encrypt the actual payload with that key

You get the security guarantees of asymmetric crypto with the performance of symmetric crypto.

### How It Works in BIP 77

When Bob generates his BIP 21 URI, he also generates a **key pair** and embeds his public key
in the URI (encoded alongside the mailbox URL in the `pj=` parameter).

```
Bob generates:
  sk_bob  →  private key  (stays on Bob's device, never shared)
  pk_bob  →  public key   (embedded in the BIP 21 URI, public)
```

When Alice wants to send her PSBT to Bob:

```
Alice:
  1. Generates an ephemeral key pair (one-time use, discarded after):
       sk_eph, pk_eph

  2. Uses pk_bob + sk_eph to derive a shared symmetric key:
       shared_key = HPKE_Extract(pk_bob, sk_eph)

  3. Encrypts the PSBT with shared_key using an AEAD cipher:
       ciphertext = AEAD_Encrypt(shared_key, psbt)

  4. Sends to Directory:
       { pk_eph, ciphertext }
```

When Bob fetches his mailbox:

```
Bob:
  1. Receives { pk_eph, ciphertext }

  2. Uses sk_bob + pk_eph to derive the SAME shared symmetric key:
       shared_key = HPKE_Extract(sk_bob, pk_eph)
       (ECDH guarantees both sides arrive at the same key)

  3. Decrypts:
       psbt = AEAD_Decrypt(shared_key, ciphertext)
```

The Directory only ever sees `{ pk_eph, ciphertext }` — an ephemeral public key and an encrypted
blob it cannot open. Without Bob's private key, it cannot derive the shared key.

### Domain Separation

HPKE in BIP 77 uses an **application-specific info string** when deriving the shared key — a
context label that uniquely identifies this as a Payjoin V2 message. This property means:

- A ciphertext encrypted for Payjoin V2 cannot be replayed or reused in a different protocol context
- Even if an attacker intercepts a message and tries to use it elsewhere, decryption will fail

This is a subtle but important security property against cross-protocol attacks.

---

## OHTTP — Oblivious HTTP

HPKE ensures the **content** of messages is private. But there's still a metadata problem.

Even if the Directory can't read Alice's PSBT, it can still see **Alice's IP address** every
time she connects. It can correlate: "IP 203.0.113.42 deposited a message, then IP 198.51.100.7
picked it up — these two are doing a Payjoin together."

This is where **OHTTP (Oblivious HTTP, defined in RFC 9458)** comes in.

### The Core Idea

OHTTP separates **who is making a request** from **who processes the request** by routing
traffic through two servers with different and complementary views:

```
Alice/Bob ──▶ OHTTP Relay ──▶ OHTTP Gateway ──▶ Payjoin Directory
  (real IP)    (sees IP,        (sees content,
                not content)     not IP)
```

- **Relay**: Knows Alice's IP, but only sees an encrypted blob. Has no idea what's inside
  or which final destination it's for.
- **Gateway**: Knows what's inside and where to forward it, but only sees the Relay's IP,
  not Alice's original IP.

Neither server has the full picture alone. And crucially, they are operated by **different
entities** — so collusion would be required to deanonymize Alice, which is the same trust model
as Tor's two-hop design.

### How the Encryption Works

Alice encrypts her HTTP request using the **Gateway's public key** before sending anything to
the Relay:

```
Alice:
  1. Obtains Gateway's public key (published out-of-band)
  2. Encrypts her HTTP request using Gateway's pubkey:
       encapsulated_req = HPKE_Seal(gateway_pk, http_request)
  3. Sends encapsulated_req to the Relay

Relay:
  - Receives encapsulated_req
  - Sees Alice's IP address
  - Cannot read the content (encrypted for Gateway)
  - Forwards encapsulated_req to the known Gateway

Gateway:
  - Decrypts encapsulated_req using its private key
  - Sees the actual HTTP request (POST /mailbox/bob-id, body: ciphertext)
  - Does NOT see Alice's IP — only sees the Relay's IP
  - Forwards the request to the Directory
  - Encrypts the Directory's response and sends it back through the Relay to Alice
```

### The Complete Privacy Stack

```
What the Relay sees:
┌──────────────────────────────────────────────┐
│ Source IP: 203.0.113.42  (Alice)             │
│ Destination: Gateway                         │
│ Body: [OHTTP encapsulated blob, unreadable]  │
└──────────────────────────────────────────────┘

What the Gateway sees:
┌──────────────────────────────────────────────┐
│ Source IP: Relay's IP  (not Alice's)         │
│ Request: POST /mailbox/bob-short-id          │
│ Body: [HPKE ciphertext meant for Bob]        │
└──────────────────────────────────────────────┘

What the Directory sees:
┌──────────────────────────────────────────────┐
│ Source IP: Gateway's IP  (not Alice's)       │
│ Mailbox: bob-short-id                        │
│ Body: [HPKE ciphertext, can't decrypt]       │
└──────────────────────────────────────────────┘
```

OHTTP hides **who** is communicating. HPKE hides **what** is being communicated. Together, the
Directory is completely blind — it cannot link messages to identities, cannot read content, and
cannot forge or tamper with payloads.

---

## BIP 77 Full Flow — Everything Together

```
┌──────────────────────────────────────────────────────────────────────┐
│                            SETUP                                     │
│                                                                      │
│  Bob generates keypair: (sk_bob, pk_bob)                             │
│  Bob registers a mailbox on the Directory → gets a Short ID          │
│  Bob creates BIP 21 URI with pj= pointing to mailbox + pk_bob        │
│  Bob shares URI as QR code or payment link                           │
└──────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         ALICE SENDS                                  │
│                                                                      │
│  1. Alice scans QR → extracts mailbox URL + pk_bob                   │
│  2. Alice builds Original PSBT (her inputs, signs them)              │
│  3. Alice HPKE-encrypts PSBT using pk_bob → ciphertext               │
│  4. Alice wraps HTTP request in OHTTP (Gateway's pubkey)             │
│  5. Alice sends: Alice → Relay → Gateway → Directory → Bob's mailbox │
└──────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        BOB PROCESSES                                 │
│                                                                      │
│  6. Bob polls his mailbox via OHTTP GET (whenever he comes online)   │
│  7. Directory returns the encrypted blob                             │
│  8. Bob HPKE-decrypts using sk_bob → recovers Original PSBT          │
│  9. Bob validates Alice's proposal per BIP 78 checklist              │
│ 10. Bob adds his UTXOs as inputs, adjusts outputs, signs his inputs  │
│ 11. Bob HPKE-encrypts Proposal PSBT → deposits reply via OHTTP       │
└──────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       ALICE FINALIZES                                │
│                                                                      │
│ 12. Alice polls for Bob's response via OHTTP                         │
│ 13. Alice HPKE-decrypts → recovers Proposal PSBT                    │
│ 14. Alice validates: correct amount? inputs intact? no extra outputs?│
│ 15. Alice re-signs her inputs on the Proposal PSBT                   │
│ 16. Alice broadcasts the finalized transaction to the Bitcoin network │
└──────────────────────────────────────────────────────────────────────┘
```

No real-time coordination required. Bob doesn't need a server. The Directory never sees the
content. Nobody sees both sides of the conversation.

---

## BIP 78 vs BIP 77 — Side by Side

| Property              | BIP 78 (V1)                       | BIP 77 (V2)                    |
| --------------------- | --------------------------------- | ------------------------------ |
| Bob needs a server    | Yes — HTTPS or Tor hidden service | No                             |
| Communication model   | Synchronous (like a phone call)   | Asynchronous (like email)      |
| Who can be a receiver | Merchants with infrastructure     | Any wallet, including mobile   |
| Content encrypted     | No                                | Yes — HPKE end-to-end          |
| IPs protected         | No                                | Yes — OHTTP                    |
| Directory required    | No                                | Yes, but explicitly untrusted  |
| Backwards compatible  | N/A                               | Partially (with `pjos=0`)      |
| Fallback behavior     | Alice broadcasts Original PSBT    | Alice broadcasts Original PSBT |

---

## Backwards Compatibility

BIP 77 is designed to be partially backwards-compatible with BIP 78. A sender that only supports
BIP 78 can still POST directly to a BIP 77 mailbox endpoint — it just won't get HPKE encryption
or OHTTP protection.

In this backwards-compatible mode, BIP 78's `pjos=0` flag **must** be set, which disables output
substitution. Since the payload isn't encrypted in this path, a malicious Directory could
theoretically tamper with outputs — `pjos=0` closes that attack surface.

---

## Why This Matters

Payjoin is one of the few Bitcoin privacy improvements that:

1. **Requires no protocol changes** — it works on Bitcoin exactly as it exists today
2. **Provides plausible deniability** — Payjoin transactions are indistinguishable from regular
   two-party spends on-chain
3. **Benefits both parties** — privacy for Alice, UTXO consolidation for Bob
4. **Doesn't require trust** — the cryptographic design ensures no third party can interfere or surveil

BIP 77 specifically removes the last major practical barrier: the server requirement. With async
Payjoin, any mobile wallet can be a Payjoin receiver — which is the prerequisite for meaningful
adoption at scale.

The more wallets adopt BIP 77, the larger the anonymity set becomes. Every Payjoin transaction
makes every other Bitcoin transaction harder to analyze — because analysts can no longer be
certain which transactions are Payjoins and which aren't. Privacy becomes a property of the
network, not just of individual users who opt in.

---

## Further Reading

- [BIP 78 Specification](https://bips.dev/78/) — Nicolas Dorier
- [BIP 77 Specification](https://bips.dev/77/) — Dan Gould, Yuval Kogman
- [BIP 174 — PSBT](https://bips.dev/174/) — Andrew Chow
- [RFC 9180 — HPKE](https://www.rfc-editor.org/rfc/rfc9180)
- [RFC 9458 — OHTTP](https://www.rfc-editor.org/rfc/rfc9458)
- [payjoin.org](https://payjoin.org) — Protocol documentation and wallet integration guides
- [`rust-payjoin`](https://github.com/payjoin/rust-payjoin) — Reference implementation in Rust
