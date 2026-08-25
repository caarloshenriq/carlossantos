+++
title = "Cryptography from First Principles: From Ancient Ciphers to Modern Security"
date= 2026-06-23
draft = false
description = "An introduction to cryptography through its history, core security goals, classical ciphers, and the foundations of modern cryptographic systems."
tags = ["cryptography"]
+++

## What Is Cryptography and Why Was It Invented

The word cryptography comes from the Greek: _kryptós_ (κρυπτός), "hidden", and _gráphein_ (γράφειν), "to write". Literally, hidden writing.

Every civilization that developed writing eventually developed ciphers. This is no coincidence. Writing is an extraordinary technology: for the first time in history, information could travel without its original carrier, survive the death of its author, and be copied at scale. Each of these properties is, simultaneously, an attack vector. A message that travels without its sender can be intercepted. A message that outlives its author can be discovered centuries later. Cryptography emerged as the natural defense against the vulnerability of writing.

**Confidentiality** is the original and primary objective: ensuring that only the correct recipient can read the message. It is what the Spartans wanted when they wrapped leather around the scytale. **Integrity** guarantees that the message was not altered in transit, since a message modified by an adversary is just as dangerous as one read by them. **Authenticity** answers the question of who actually sent the message, with digital signatures being the modern mechanism for this. And **non-repudiation** prevents the sender from denying having sent a message, a critical property in legal and financial contexts.

## The Spartan Scytale

### Context

To understand the scytale, one must understand Sparta. The city-state the Greeks called _Lakedaímon_ was governed by two kings simultaneously, but with real power concentrated in the _ephors_, five magistrates elected annually. This arrangement created an urgent logistical problem: military commanders operated at great distances from the ephors who held supreme authority. During the Peloponnesian Wars (431 to 404 BC), generals such as Lysander, Clearchus, and Agesilaus conducted campaigns in Asia Minor and the Aegean, hundreds of kilometers from Sparta. How did the ephors send secret orders to these commanders without dishonest messengers or Persian spies reading them?

The answer was the scytale.

### What It Is

The scytale (from the Greek σκυτάλη, _skytálē_, "staff" or "cylinder") is considered the first known cryptographic device in history. It consists of a wooden cylinder around which a narrow strip of leather or papyrus is wound in a spiral. The message is written along the length of the staff, letter by letter. When the strip is unwound, the letters are distributed in an apparently random fashion: the text becomes illegible. The recipient, who possesses an identical staff, rewinds the strip and the message emerges again.

In modern terms, the scytale performed a **transposition cipher**: the characters of the original text are preserved, but their order is rearranged. No letter is substituted for another; all are present, merely out of place. The cryptographic key of the system was the diameter of the staff.

### How It Came to Be

The earliest known mention comes from the poet Archilochus of Paros in the 7th century BC, who references the object as a messenger's staff, still without explicitly cryptographic context. The most complete technical description comes from Plutarch, in his _Parallel Lives_, specifically in the _Life of Lysander_ (Lysander 19.5 to 7), written in the 1st century AD:

> _"He, when he receives it, cannot make out any sense of the letters, which have no connection, but are scrambled, unless he takes his own scytale and winds the strip of parchment around it, so that, when its spiral course is recovered perfectly, and what comes after is joined to what came before, he reads around the staff and so discovers the continuity of the message."_

The most concrete episode Plutarch narrates is the sending of a scytale from the ephors to general Lysander, who was in Asia Minor plundering the territories of the Persian satrap Pharnabazus. The message summoned him back to Sparta, under penalty of death. The fact that the message caused palpable distress in Lysander suggests its content was specific and unambiguous, characteristics of a ciphered message rather than a simple authentication object.

It is worth noting that not all historians agree on the cryptographic use of the scytale. Thomas Kelly, in 1998, argued that it served primarily as an authentication staff for the messenger, not the content. The most robust response to this position came from Martine Diepenbroek's doctoral dissertation at the University of Bristol (2020), which, after exhaustive analysis of all classical Greek and Latin sources, concludes that the scytale most likely served multiple purposes and that its cryptographic use in a wartime context is technically plausible and historically supported.

### The Legacy

The scytale established a principle that would remain central to cryptography for the next 2,600 years: the idea of a shared key. Without a staff of the correct diameter, the message remains unintelligible. The staff _is_ the key. All security of the system rests on its possession, not on the secrecy of the mechanism itself. This intuition would be formalized two millennia later by Auguste Kerckhoffs, and reformulated by Claude Shannon. But the Spartans were already operating according to it in the 5th century BC.

## The Caesar Cipher

### How It Came to Be

The history of the Caesar cipher begins in the turbulent final decades of the Roman Republic, when Julius Caesar was becoming one of the most influential military commanders in history. Born around 100 BC, Caesar conducted campaigns across vast territories far from Rome, and the logistical problem was severe: intercepted messages could cost lives, battles, and entire campaigns.

The Roman historian Suetonius documented Caesar's encryption method in his biographical work _The Lives of the Twelve Caesars_, written around 121 AD. According to Suetonius, Caesar used a shift of three positions to encode his most sensitive military dispatches, ensuring that even if a messenger were intercepted, the content of the message would remain unintelligible to the enemy.

One important historical detail: Caesar himself never discussed the use of this cipher in any of his surviving works, such as _The Gallic War_ and _The Civil War_. The only descriptions we know come from Aulus Gellius, Cassius Dio, and Suetonius, all writing in the 2nd century AD. According to these authors, Caesar appears to have used his cipher to communicate with trusted individuals on private matters, and with his generals in the field.

### How It Worked

The Caesar cipher is a **monoalphabetic substitution cipher**: each letter of the original text is replaced by another letter, shifted a fixed number of positions in the alphabet. That number is the key. In Caesar's case, the key was 3.

**Example with key 3:**

| Plaintext  | A   | T   | A   | Q   | U   | E   |
| ---------- | --- | --- | --- | --- | --- | --- |
| Ciphertext | D   | W   | D   | T   | X   | H   |

The full alphabet shifted by 3 positions:

| Plain  | A   | B   | C   | D   | E   | F   | G   | H   | I   | J   | K   | L   | M   | N   | O   | P   | Q   | R   | S   | T   | U   | V   | W   | X   | Y   | Z   |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Cipher | D   | E   | F   | G   | H   | I   | J   | K   | L   | M   | N   | O   | P   | Q   | R   | S   | T   | U   | V   | W   | X   | Y   | Z   | A   | B   | C   |

The mathematical formula describing encryption is:

```
C = (P + s) mod 26
```

Where `P` is the letter's position in the alphabet (A=0, B=1 ... Z=25), `s` is the shift (the key), and `C` is the resulting encrypted letter. To decrypt, simply reverse:

```
P = (C - s + 26) mod 26
```

### The Problem With the Caesar Cipher

The cipher worked for a very simple reason: its elegance lay partly in the low literacy rates of the era and the vast expanse of the Roman Empire, meaning that intercepting a message alone was not sufficient to decipher its content. In other words, security depended more on the adversary's ignorance than on the mathematical strength of the system.

And therein lies the fatal structural weakness: with only 25 possible keys (shifts of 1 to 25), anyone with patience can try them all and find the original message in seconds. Furthermore, each letter is always replaced by the same ciphered letter, which preserves the frequency patterns of the language. An adversary who knows that the most frequent letter in the ciphertext is "X" can infer it represents "E" (the most common letter in Latin or English) and reconstruct the cipher through statistical analysis.

## The Vigenère Cipher

### How It Came to Be (and the Historical Confusion)

The cipher that bears Vigenère's name has a tortuous authorship history worth understanding.

The cipher we know today as Vigenère was originally described by Giovan Battista Bellaso in his 1553 book _La cifra del Sig. Giovan Battista Bellaso_. He built on Trithemius's _tabula recta_, but added a repeated "countersign" (a keyword) to switch cipher alphabets with each letter.

For centuries, the cipher was attributed to the French diplomat and cryptographer Blaise de Vigenère (1523 to 1596), who actually developed a different and stronger variant in 1586. The confusion was solidified in the 19th century when historians erroneously associated Vigenère's name with Bellaso's method, and the name stuck.

The context in which the cipher emerged is also relevant. Diplomats and other government officials of the era made frequent use of codes and ciphers to send messages they hoped would give their country some advantage in relations with other states. The Caesar cipher had dominated for over a thousand years, but any reasonably skilled cryptanalyst could break it. Something more robust was needed.

### How It Worked

Bellaso's great innovation was simple but devastating for any attacker: instead of using a single fixed shift for all letters, the Vigenère cipher uses a **keyword**, and each letter of the message is encrypted with a different shift, determined by the corresponding letter of the key. The key repeats throughout the entire message.

**Example with key "BRAVE":**

First, each letter of the key defines a shift (A=0, B=1, C=2 ... Z=25):

| Key   | B   | R   | A   | V   | E   |
| ----- | --- | --- | --- | --- | --- |
| Value | 1   | 17  | 0   | 21  | 4   |

Now we apply these shifts cyclically to the plaintext:

| Plaintext  | A   | T   | T   | A   | C   | K   | A   | T   | D   | A   |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Key        | B   | R   | A   | V   | E   | B   | R   | A   | V   | E   |
| Shift      | 1   | 17  | 0   | 21  | 4   | 1   | 17  | 0   | 21  | 4   |
| Ciphertext | B   | K   | T   | V   | G   | L   | R   | T   | Y   | E   |

The _tabula recta_, or Vigenère square, is the visual tool that organizes these shifts. Each row is the alphabet shifted one position more than the previous:

|       | A   | B   | C   | D   | E   | F   | G   | H   | I   | J   | ... |
| ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **A** | A   | B   | C   | D   | E   | F   | G   | H   | I   | J   | ... |
| **B** | B   | C   | D   | E   | F   | G   | H   | I   | J   | K   | ... |
| **C** | C   | D   | E   | F   | G   | H   | I   | J   | K   | L   | ... |
| **D** | D   | E   | F   | G   | H   | I   | J   | K   | L   | M   | ... |
| **E** | E   | F   | G   | H   | I   | J   | K   | L   | M   | N   | ... |

To encrypt, find the row of the key letter and the column of the plaintext letter. Their intersection is the ciphertext letter.

The formula is a direct extension of the Caesar cipher, but with a variable key:

```
C_i = (P_i + K_i) mod 26
P_i = (C_i - K_i + 26) mod 26
```

Where `K_i` is the numerical value of the i-th letter of the key (repeated cyclically).

### Why It Was So Hard to Break

The cipher resisted all decryption attempts for three centuries, earning it the title of _le chiffre indéchiffrable_ (the indecipherable cipher) in French. The reason is straightforward: since the same plaintext letter can be encrypted in different ways depending on its position, the frequency patterns of the language are masked. Frequency analysis, which demolished any simple substitution cipher, becomes ineffective.

The mathematician and author Lewis Carroll called the Vigenère cipher unbreakable in his 1868 text "The Alphabet Cipher" in a children's magazine. In 1917, _Scientific American_ described it as "impossible to translate."

The fall came only in 1863, when Prussian officer Friedrich Kasiski published the first general decryption method. The central idea is that if the key repeats, identical fragments of plaintext tend to produce identical fragments in the ciphertext, revealing the key length. With the key length in hand, the problem reduces to several independent Caesar ciphers, each breakable by frequency analysis.

## Symmetric Cryptography

Symmetric cryptography is the most direct model: a single secret key is used both to encrypt and to decrypt the message. Sender and recipient must share this key in advance, and all security of the system rests on keeping it secret.

```
Plaintext  ──► [ Algorithm + Secret Key ] ──► Ciphertext
Ciphertext ──► [ Algorithm + Secret Key ] ──► Plaintext
```

The flow is symmetric precisely because the same key operates in both directions. This brings an important structural advantage: symmetric algorithms are computationally cheap and very fast, making them the natural choice for encrypting large volumes of data.

The central limitation is the **key distribution problem**: how does Alice send the secret key to Bob without an adversary intercepting it? If the communication channel were secure enough to send the key, it would probably be secure enough to send the message directly. This paradox remained without a satisfying solution for centuries, until the emergence of asymmetric cryptography.

The two most historically significant examples of modern symmetric cryptography are DES and AES.

### DES — Data Encryption Standard

#### How It Came to Be

DES was developed by IBM in the early 1970s, based on an earlier cipher called Lucifer, in response to a public request from the National Bureau of Standards (now NIST). It was adopted as a US federal standard in 1977.

The politics behind the adoption of DES are notable. It is known that the NSA encouraged, if not persuaded, IBM to reduce the key size from 128 to 64 bits, and then to 56 bits. This is frequently interpreted as an indication that the NSA already possessed enough computing power to break keys of that length even in the mid-1970s.

#### How It Worked

DES is a symmetric block cipher that operates on 64-bit (8-byte) blocks. It uses a 56-bit key and applies 16 rounds of a Feistel network structure to transform plaintext into ciphertext.

The encryption process can be summarized as follows:

```
Plaintext (64 bits)
        │
        ▼
  Initial Permutation
        │
        ▼
┌───────────────────────────────┐
│     16 Feistel rounds         │
│  ┌─────────┐   ┌─────────┐   │
│  │  Left   │   │  Right  │   │
│  │  half   │   │  half   │   │
│  └────┬────┘   └────┬────┘   │
│       │    f(R,K)   │        │
│       └──── XOR ────┘        │
│         Subkey Ki (48 bits)   │
└───────────────────────────────┘
        │
        ▼
  Final Permutation
        │
        ▼
Ciphertext (64 bits)
```

In each round, a 48-bit subkey is derived from the original 56-bit key. The right half of the block goes through an expansion function, XOR with the subkey, S-box substitution, and permutation, and the result is combined with the left half. The halves then swap and the process repeats for 16 rounds.

| Property         | DES                 |
| ---------------- | ------------------- |
| Block size       | 64 bits             |
| Key size         | 56 bits (effective) |
| Number of rounds | 16                  |
| Structure        | Feistel network     |
| Current status   | Broken, obsolete    |

#### The Fall of DES

The fatal weakness of DES is its 56-bit key length. In 1977, this size was considered sufficiently large by the NSA, but Whitfield Diffie and Martin Hellman publicly argued at the time that it was too short for long-term security. They were right.

In January 1999, a DES key was publicly broken in just 22 hours and 15 minutes through a collaborative effort between distributed.net and the Electronic Frontier Foundation. The EFF built a dedicated machine called "Deep Crack" for approximately $250,000. With 2⁵⁶ possible keys (roughly 72 quadrillion combinations), the search space seemed enormous in 1977, but not for 1999 hardware.

NIST officially withdrew DES as a federal standard on May 19, 2005. As an interim measure during the transition, Triple DES (3DES) applied the algorithm three times with independent keys, achieving an effective key length of 168 bits.

### AES — Advanced Encryption Standard

#### How It Came to Be

With DES broken and 3DES being merely a stopgap, NIST launched an open, international competition in 1997 to define a new standard. Researchers from 12 different countries worked on developing advanced encoding methods during the global competition. NIST invited the worldwide cryptographic community to "attack" the encryption formulas in an effort to break the codes.

Rijndael was the surprise winner of the contest. The surprise arose because many observers, and even some participants, expressed skepticism that the US government would adopt as an encryption standard any algorithm not designed by American citizens. Yet NIST ran an open, international selection process that should serve as a model for other standards organizations.

The name Rijndael was formed as a combination of the names of its two developers, Vincent Rijmen and Joan Daemen. The two Belgian cryptographers won the competition over finalists from RSA Security, IBM, and Counterpane. AES was standardized by NIST in FIPS 197 in 2001 and is today the most widely deployed symmetric encryption algorithm in the world.

#### How It Works

AES operates on 128-bit data blocks and supports symmetric keys of 128, 192, or 256 bits. Its structure employs a Substitution-Permutation Network (SPN) that iteratively transforms plaintext into ciphertext through a series of mathematical operations.

The 128-bit block is organized as a 4×4 matrix of bytes:

```
┌────┬────┬────┬────┐
│ b0 │ b4 │ b8 │ b12│
├────┼────┼────┼────┤
│ b1 │ b5 │ b9 │ b13│
├────┼────┼────┼────┤
│ b2 │ b6 │ b10│ b14│
├────┼────┼────┼────┤
│ b3 │ b7 │ b11│ b15│
└────┴────┴────┴────┘
```

In each round, four transformations are applied to this matrix:

| Step        | What it does                                             |
| ----------- | -------------------------------------------------------- |
| SubBytes    | Each byte is replaced by another via the S-box table     |
| ShiftRows   | The matrix rows are cyclically rotated                   |
| MixColumns  | Columns are mixed via multiplication in GF(2⁸)           |
| AddRoundKey | The matrix undergoes XOR with the current round's subkey |

The number of rounds depends on the key size:

| Key size | Rounds |
| -------- | ------ |
| 128 bits | 10     |
| 192 bits | 12     |
| 256 bits | 14     |

The final round omits MixColumns. Decryption simply reverses each operation in the opposite order.

| Property         | AES                              |
| ---------------- | -------------------------------- |
| Block size       | 128 bits                         |
| Key size         | 128, 192, or 256 bits            |
| Number of rounds | 10, 12, or 14                    |
| Structure        | Substitution-Permutation Network |
| Current status   | Secure, world standard           |

## Asymmetric Cryptography

Asymmetric cryptography solves the problem that plagued symmetric cryptography for millennia: how can two parties establish a shared secret key without ever having met before, over a channel that may be monitored by an adversary?

The answer is elegant: **there is no single shared key**. Instead, each participant holds a mathematically linked pair of keys: a **public key**, which can be openly distributed to anyone, and a **private key**, which never leaves its owner's control.

```
                     Bob's Public Key
                     (known to everyone)
                            │
Alice ──► [ Encrypt with Bob's PubKey ] ──► Ciphertext ──► Bob
                                                            │
                                     Bob ──► [ Decrypt with Bob's PrivKey ] ──► Plaintext
```

What was encrypted with Bob's public key **can only be decrypted by Bob's private key**. No one else, not even Alice, can decrypt the message she herself sent.

Asymmetric cryptography tends to be slower than symmetric and uses larger keys. RSA, for example, typically uses 2048 to 4096-bit keys. For this reason, in practice, asymmetric and symmetric cryptography work together: asymmetric is used to securely exchange the symmetric key, and symmetric does the heavy lifting of encrypting the data. This is exactly how TLS (the protocol behind HTTPS) works.

### RSA

#### How It Came to Be

The historical development of public-key cryptography traces back to the mid-1970s, a period considered a critical turning point in the history of cryptography. In 1976, Whitfield Diffie and Martin Hellman published their landmark paper "New Directions in Cryptography," which first proposed the conceptual framework for asymmetric encryption.

In 1977, three people who would make the single most spectacular contribution to public-key cryptography took up the challenge of producing a full-fledged public-key cryptosystem: Ronald Rivest, Adi Shamir, and Leonard Adleman. The process lasted several months, during which Rivest proposed approaches, Adleman attacked them, and Shamir did some of each. In May 1977 they were rewarded with success: they had discovered how a simple piece of classical number theory could solve the problems.

#### How It Works

The security of RSA rests on a problem that is simple to state and extremely difficult to solve: given a very large number n that is the product of two primes p and q, find p and q knowing only n.

The RSA algorithm relies on a simple mathematical asymmetry: multiplying two large prime numbers together is fast, but factoring the resulting product back into its prime components is computationally infeasible at sufficient key lengths.

**Key generation (simplified example with small numbers):**

```
1. Choose two primes: p = 61, q = 53
2. Compute n = p × q = 3233   (public modulus)
3. Compute φ(n) = (p-1)(q-1) = 60 × 52 = 3120
4. Choose e such that 1 < e < φ(n) and gcd(e, φ(n)) = 1
   → e = 17  (public exponent)
5. Compute d such that e × d ≡ 1 (mod φ(n))
   → d = 2753  (private exponent)

Public key:   (n = 3233, e = 17)
Private key:  (n = 3233, d = 2753)
```

**Encryption and decryption:**

```
Encrypt:  C = M^e mod n
Decrypt:  M = C^d mod n
```

| Variable | Meaning             | Visibility                       |
| -------- | ------------------- | -------------------------------- |
| n        | Modulus (p × q)     | Public                           |
| e        | Encryption exponent | Public                           |
| d        | Decryption exponent | Private                          |
| p, q     | Prime factors of n  | Private (destroyed after keygen) |

In real production, p and q have hundreds or thousands of digits. The NSA recommends using RSA with at least 3072 bits for asymmetric encryption.

| Property           | RSA                                                          |
| ------------------ | ------------------------------------------------------------ |
| Type               | Asymmetric                                                   |
| Key size           | 2048 to 4096 bits (recommended)                              |
| Underlying problem | Integer factorization                                        |
| Primary uses       | Key exchange, digital signatures, TLS certificates           |
| Current status     | Secure at 2048+ bits; vulnerable to future quantum computers |

## IND-CPA: The Formal Definition of Security

Up to this point we have studied algorithms: the Caesar cipher, AES, RSA. But how do we know that an encryption scheme is _really_ secure? Intuition is not enough. Modern cryptography demands **formal security proofs**, and IND-CPA is the most fundamental of them.

IND-CPA stands for _Indistinguishability under Chosen Plaintext Attack_. It is a property that an encryption scheme must satisfy to be considered secure against an adversary who can have the system encrypt messages of their own choosing.

### The Indistinguishability Game

Security in terms of indistinguishability is normally presented as a game, where the cryptosystem is considered secure if no adversary can win the game with significantly greater probability than an adversary who must guess randomly.

The IND-CPA game has two players: an **adversary** (Eve) and a **challenger** (Alice, representing the honest system). The central idea is simple: if the scheme is secure, Eve should not be able to distinguish the encryption of one message from the encryption of another, even if she can request encryptions of any message she wants.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         IND-CPA GAME                                │
│                                                                     │
│  CHALLENGER                              ADVERSARY (Eve)            │
│                                                                     │
│  1. Generate key pair (pk, sk)           │                          │
│     Publish pk ─────────────────────────►│                          │
│                                          │                          │
│  2. [Learning phase]                     │                          │
│     Eve may request encryptions of      │                          │
│     any messages she chooses ◄───────────│                          │
│     Challenger responds with Enc(pk, m) ─►│                          │
│                                          │                          │
│  3. [Challenge phase]                    │                          │
│     Eve submits two messages ────────────►│                          │
│     m₀ and m₁ of equal length           │                          │
│     Challenger flips a coin: b ∈ {0,1}  │                          │
│     Sends C* = Enc(pk, m_b) ─────────────►│                          │
│                                          │                          │
│  4. [Guessing phase]                     │                          │
│     Eve guesses: b' = ? ◄────────────────│                          │
│                                          │                          │
│  Eve WINS if b' = b                      │                          │
└─────────────────────────────────────────────────────────────────────┘
```

The scheme is **IND-CPA secure** if no efficient adversary (running in polynomial time) can win this game with probability significantly greater than 1/2, i.e., better than a random guess.

Formally, the adversary's advantage is defined as:

```
Adv_IND-CPA(A) = | Pr[A wins] - 1/2 |
```

A scheme is IND-CPA secure if this advantage is **negligible** for all efficient adversaries.

### The Immediate Consequence: Deterministic Encryption Is Insecure

A deterministic encryption scheme is not IND-CPA secure because encrypting the same message twice always produces the same result, which causes information leakage.

The attack against any deterministic cipher is trivial:

```
Learning phase:
  Eve requests the encryption of m₀  →  obtains C₀ = Enc(k, m₀)

Challenge phase:
  Eve submits m₀ and m₁ to the challenger
  Receives C* = Enc(k, m_b)

Guessing phase:
  If C* == C₀ → b' = 0   (Eve wins with probability 1)
  If C* != C₀ → b' = 1   (Eve wins with probability 1)
```

This means that AES alone, without a mode of operation, **is not IND-CPA secure**. ECB mode (_Electronic Code Book_), which encrypts each 128-bit block independently and identically, is the most famous example of this failure. The Penguin Attack illustrates this visually: encrypting a penguin image with AES-ECB preserves the visual patterns of the original image entirely in the ciphertext, because identical pixel blocks produce identical ciphertext blocks.

For AES to be IND-CPA secure, a mode of operation that introduces randomness is required: **CBC** (_Cipher Block Chaining_) and **CTR** (_Counter_) mode accomplish this through a random **initialization vector** (IV) that differs on every encryption.

```
ECB (NOT secure):  Enc(k, m)  =  always the same result  → BROKEN

CBC (secure):      Random IV ──► Enc(k, IV ⊕ m)  =  different result each time
CTR (secure):      Random nonce ──► Enc(k, nonce || counter) ⊕ m  =  different result each time
```

| Mode | IND-CPA secure?    | Reason                                  |
| ---- | ------------------ | --------------------------------------- |
| ECB  | No                 | Deterministic: same input → same output |
| CBC  | Yes (random IV)    | Random IV guarantees non-determinism    |
| CTR  | Yes (unique nonce) | Unique nonce guarantees non-determinism |

### IND-CCA and IND-CCA2

IND-CPA is the weakest property in the indistinguishability security hierarchy. The most common definitions are IND-CPA, IND-CCA1, and IND-CCA2. Security under either of the latter definitions implies security under the previous ones: an IND-CCA2 secure scheme is automatically IND-CCA1 and IND-CPA secure.

| Level    | The adversary can...                                        | Strength |
| -------- | ----------------------------------------------------------- | -------- |
| IND-CPA  | Request encryptions of any messages                         | Weak     |
| IND-CCA1 | Request both encryptions and decryptions (before challenge) | Medium   |
| IND-CCA2 | Request decryptions both before and after the challenge     | Strong   |

For real-world protocols like TLS, the goal is IND-CCA2. RSA without padding (known as _textbook RSA_) is deterministic and therefore not even IND-CPA secure. OAEP (_Optimal Asymmetric Encryption Padding_) is the padding that makes RSA IND-CCA2 secure in practice.

## Cryptographic Hash Functions

A cryptographic hash function takes an input of arbitrary size and produces a fixed-size output, called a **digest** or **hash**. The process is one-way: given the hash, it is computationally infeasible to find the original input.

```
"password123"     ──► SHA-256 ──► a665a45920422f9d...  (64 hex chars = 256 bits)
"password124"     ──► SHA-256 ──► 5e179a5b6277e2de...  (completely different)
"Homer's Iliad"   ──► SHA-256 ──► 3b4c9d1f...          (still 256 bits)
```

That last line is the key point: an input of any size, whether an 8-character password or the complete text of the Iliad, always produces a fixed-size output. This compression property has profound mathematical consequences.

### The Three Fundamental Properties

**Preimage resistance** (one-way): given a hash h, it must be computationally infeasible to find any input m such that `hash(m) = h`. This is the one-way property that prevents a password hash from leaking the original password.

**Second preimage resistance**: given an input m₁, it must be infeasible to find a second input m₂ (different from m₁) such that `hash(m₁) = hash(m₂)`. This prevents an adversary from substituting a valid document for a forged one with the same hash.

**Collision resistance**: it must be infeasible to find _any_ pair (m₁, m₂) with m₁ ≠ m₂ such that `hash(m₁) = hash(m₂)`. This is the strongest property: collisions always exist mathematically (infinitely many inputs map to a finite output space), but finding them must be computationally impossible.

| Property             | Question it answers                   | Brute force complexity    |
| -------------------- | ------------------------------------- | ------------------------- |
| Preimage resistance  | Given h, find m such that H(m) = h?   | 2ⁿ                        |
| Second preimage res. | Given m₁, find m₂ with H(m₁) = H(m₂)? | 2ⁿ                        |
| Collision resistance | Find any (m₁, m₂) with H(m₁) = H(m₂)? | 2^(n/2) — birthday attack |

The birthday attack reduces the difficulty of finding collisions to the square root of the hash space. This is why 128-bit hashes (like MD5) offer only 2⁶⁴ security against collisions, and modern hashes need at least 256 bits.

### The Avalanche Effect

An important property of good hash functions is the **avalanche effect**: a small change in the input (even a single bit) must produce a drastically different output. Without this, information about the input would leak through the hash.

```
SHA-256("password123")  → a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
SHA-256("password124")  → 5e179a5b6277e2de95de5cd12e27a01bdc0dd3c13e8da2c4498bae7cc55e0e83
```

The outputs are completely different despite the inputs differing by only one character.

### MD5, SHA-1, and the Evolution to SHA-256

MD5 and SHA-1 were for a long time the closest thing to a de facto standard for hashing. This changed in 2004 and 2005, when researchers showed that finding collisions for MD5 could be easy, and substantially reduced the work needed to find SHA-1 collisions to 2⁶⁹, far less than the expected 2⁸⁰.

In 2017, a practical collision in SHA-1 was demonstrated, driving the adoption of longer hash algorithms like SHA-256 and SHA-3. As of 2025, no practical collisions have been demonstrated for SHA-256 or SHA-3.

| Algorithm | Output   | Status        | Effective collision resistance               |
| --------- | -------- | ------------- | -------------------------------------------- |
| MD5       | 128 bits | Broken        | Collisions found in seconds                  |
| SHA-1     | 160 bits | Broken (2017) | Practical collision demonstrated (SHAttered) |
| SHA-256   | 256 bits | Secure        | 2¹²⁸ (birthday attack)                       |
| SHA-3     | 256 bits | Secure        | 2¹²⁸ (different structure from SHA-2)        |

### Hashes Are Not For Passwords

Here lies one of the most dangerous misconceptions in software security: using SHA-256 directly to store passwords.

SHA-256 was designed to be **extremely fast**. On modern hardware, it is possible to compute billions of SHA-256 hashes per second. An attacker with a reasonable GPU can test an entire password dictionary in a matter of minutes.

Password hash functions need to be **intentionally slow** and **memory-intensive**. That is what bcrypt and Argon2 are for.

## Bcrypt

The problem bcrypt came to solve has an eloquent history. In 1976, the UNIX `crypt` function could process fewer than 4 passwords per second. The developers of the time considered this more than sufficient to prevent brute force. Twenty years later, with optimized hardware, the same function processed 200,000 passwords per second. Security evaporated without the algorithm changing a single line.

Bcrypt was designed by Niels Provos and David Mazières in 1999, based on the Blowfish block cipher, and published in their paper "A Future-Adaptable Password Scheme" at the USENIX Annual Technical Conference. The central motivation was to address vulnerabilities in existing password hashing schemes, such as DES, which were susceptible to hardware-accelerated attacks due to their low computational cost.

### How It Works

Provos and Mazières, the designers of bcrypt, used the expensive key setup phase of the Blowfish cipher to develop a new key setup algorithm called "eksblowfish," which stands for "expensive key schedule Blowfish."

Bcrypt operates in three stages:

```
1. Generate a random 128-bit salt
        │
        ▼
2. EksBlowfishSetup(cost, salt, password)
   → Expands the key 2^cost times
   → Each increment in cost doubles the time
        │
        ▼
3. Encrypt the string "OrpheanBeholderScryDoubt" 64 times with the derived key
        │
        ▼
4. Output: "$2b$cost$22-char-salt31-char-hash"
```

The bcrypt output has a standardized, self-contained format:

```
$2b$12$LJ3m4ys3Lg5Ey1j3ABCDEF.rH9sMvLjl5gvHQ3MQjHzJqPLvO1JiW
 │   │  └──────────────────┘ └─────────────────────────────────┘
 │   │       22-char salt            31-char hash
 │   └── cost (work factor)
 └── algorithm version
```

The salt is embedded in the hash itself. This is crucial: even two users with the same password will have completely different hashes because each call generates a new random salt.

### The Work Factor

The cost factor design — increase the parameter, increase the work — set the template that every later algorithm followed.

| Cost | Iterations (2^n) | Approximate time (2026 hardware) |
| ---- | ---------------- | -------------------------------- |
| 10   | 1,024            | ~100ms                           |
| 12   | 4,096            | ~400ms                           |
| 13   | 8,192            | ~800ms                           |
| 14   | 16,384           | ~1.6s                            |

In 2026, cost factor 12 is the floor. Cost 13 or 14 is common in security-conscious production.

### The Limitation of Bcrypt: Memory

Bcrypt uses Blowfish's S-boxes internally, which occupy approximately 4KB. This is small enough to fit in a modern processor's L1 cache, which is exactly the problem. GPUs have thousands of cores that can compute bcrypt in parallel, with each core keeping its 4KB of state in cache.

This did not make bcrypt insecure, but it left room for a stronger algorithm.

## Argon2id

In 2013, the cryptographic community organized the **Password Hashing Competition** (PHC), an open competition with the explicit goal of identifying a modern, secure password hashing algorithm that could supersede legacy options. Argon2 was selected as the winner in 2015, and was designed by Alex Biryukov, Daniel Dinu, and Dmitry Khovratovich from the University of Luxembourg.

RFC 9106 standardized Argon2 in September 2021. The OWASP 2024 Password Storage Cheat Sheet update moved Argon2id to the top recommendation.

### The Three Variants

Argon2 exists in three variants that differ in how they access memory. Argon2d maximizes resistance to GPU cracking attacks using password-dependent memory access. Argon2i uses password-independent memory access, optimized to resist side-channel attacks. Argon2id is a hybrid version: it follows Argon2i for the first half pass over memory and Argon2d for the rest.

| Variant  | GPU resistance | Side-channel resistance | Recommended use          |
| -------- | -------------- | ----------------------- | ------------------------ |
| Argon2d  | Maximum        | None                    | Proof-of-work, offline   |
| Argon2i  | Moderate       | Full                    | Specialized contexts     |
| Argon2id | High           | High                    | Everything — general use |

### The Three Parameters

Unlike bcrypt, which has only one parameter (the cost), Argon2id exposes three independent dimensions of security:

```
argon2id(password, salt, t, m, p)

t  → time cost:    number of iterations (CPU cost)
m  → memory cost:  amount of RAM used (memory cost, in KiB)
p  → parallelism:  number of parallel threads
```

The `m` parameter is the major innovation. If each Argon2id computation requires 64MB of RAM, then a GPU with 8GB of memory can run at most ~128 operations in parallel, not millions. The cost of brute-force attack becomes proportional to the attacker's memory hardware, not just their processing capacity.

```
GPU attack without memory-hardness (bcrypt, cost 12):
  RTX 4090 → ~15,000 hashes/second

GPU attack with Argon2id (m=64MB, t=3):
  RTX 4090 → ~500 hashes/second (limited by memory, not processor)
```

### The Output Format

Argon2id produces a hash in the PHC (_Password Hashing Competition_) format, self-contained with all parameters:

```
$argon2id$v=19$m=65536,t=3,p=4$c29tZXNhbHQ$RdescudvJCsgt3ub+b+dWRWJT...
│          │   └──────────────┘ └──────────┘ └────────────────────────────┘
│          │    parameters       salt (base64)  hash (base64)
│          └── version
└── variant
```

This means the server does not need to store the parameters separately: they are all embedded in the hash itself. To verify, simply re-read the parameters from the stored hash and re-run the algorithm.

### OWASP 2025 Recommendations

OWASP recommends Argon2id with a minimum configuration of 19 MiB of memory, 2 iterations, and 1 degree of parallelism. For systems with more available resources, the alternative configuration is 46 MiB, 1 iteration, 1 parallelism.

| Profile         | Memory (m) | Iterations (t) | Parallelism (p) | Approx. time |
| --------------- | ---------- | -------------- | --------------- | ------------ |
| Minimum (OWASP) | 19 MiB     | 2              | 1               | ~50ms        |
| Recommended     | 64 MiB     | 3              | 4               | ~300ms       |
| High security   | 128 MiB    | 4              | 4               | ~600ms       |
| Paranoid        | 256 MiB    | 5              | 8               | >1s          |

### Bcrypt vs Argon2id: The Summary

| Property                | bcrypt                  | Argon2id                         |
| ----------------------- | ----------------------- | -------------------------------- |
| Year                    | 1999                    | 2015 (RFC 9106: 2021)            |
| Memory-hard             | No (4KB, fits in cache) | Yes (configurable, 19MB to 1GB+) |
| Cost parameters         | 1 (work factor)         | 3 (time, memory, parallelism)    |
| GPU resistance          | Moderate                | High                             |
| ASIC resistance         | Moderate                | High                             |
| Side-channel resistance | No                      | Yes (via the id variant)         |
| Password length limit   | 72 bytes                | No practical limit               |
| OWASP 2025 status       | Acceptable (legacy)     | Primary recommendation           |

The transition from bcrypt to Argon2id is not a security emergency: bcrypt at cost 12 or higher remains cryptographically sound. It is a matter of direction. For new systems, Argon2id is the correct default. For legacy systems on bcrypt, migration can be done gradually, re-hashing passwords with Argon2id on the user's next successful login.

## References

- Diepenbroek, M. (2020). _Myths and Histories of the Spartan Scytale_. PhD dissertation, University of Bristol.
- Diepenbroek, M. (2021). "Ancient Cybersecurity? Deciphering the Spartan Scytale." _Antigone Journal_.
- Kelly, T. (1998). "The Myth of the Scytale." _Cryptologia_, 22(3).
- Kahn, D. (1967). _The Codebreakers_. Macmillan.
- Plutarch. _Parallel Lives, Lysander_ 19.5–7. Trans. Bernadotte Perrin. Loeb Classical Library.
- Suetonius. _De Vita Caesarum_ (Book I, Chapter 56). ~121 AD. Trans. J.C. Rolfe. Loeb Classical Library.
- Bellaso, G.B. (1553). _La cifra del Sig. Giovan Battista Bellaso_. Venice.
- Kasiski, F.W. (1863). _Die Geheimschriften und die Dechiffrir-Kunst_. Berlin.
- NIST FIPS 46-3 (1999). _Data Encryption Standard_.
- NIST FIPS 197 (2001). _Advanced Encryption Standard (AES)_.
- Daemen, J., Rijmen, V. (2002). _The Design of Rijndael: AES — The Advanced Encryption Standard_. Springer.
- Rivest, R., Shamir, A., Adleman, L. (1978). "A Method for Obtaining Digital Signatures and Public-Key Cryptosystems." _Communications of the ACM_, 21(2).
- Diffie, W., Hellman, M. (1976). "New Directions in Cryptography." _IEEE Transactions on Information Theory_, 22(6).
- Electronic Frontier Foundation. (1998). _Cracking DES_. O'Reilly.
- Goldwasser, S., Micali, S. (1984). "Probabilistic Encryption." _Journal of Computer and System Sciences_, 28(2), 270–299.
- Provos, N., Mazières, D. (1999). "A Future-Adaptable Password Scheme." _USENIX Annual Technical Conference_.
- Biryukov, A., Dinu, D., Khovratovich, D. (2015). "Argon2: the memory-hard function for password hashing and other applications." _Password Hashing Competition_.
- RFC 9106 (2021). _Argon2 Memory-Hard Function for Password Hashing and Proof-of-Work Applications_.
- OWASP. (2025). _Password Storage Cheat Sheet_. https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- NIST SP 800-63B. _Digital Identity Guidelines: Authentication and Lifecycle Management_.
- Wang, X. et al. (2004). "Collisions for Hash Functions MD4, MD5, HAVAL-128 and RIPEMD." _IACR ePrint Archive_.
- Stevens, M. et al. (2017). "The First Collision for Full SHA-1." _CRYPTO 2017_ (SHAttered).
