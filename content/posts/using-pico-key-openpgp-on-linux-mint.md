---
title: "Using Pico Key OpenPGP (RP2350) on Linux Mint"
date: 2026-03-28
draft: false
tags: ["gpg", "security", "linux", "pico", "openpgp", "hardware-key"]
description: "A step-by-step guide to setting up the Pico Key OpenPGP smart card on Linux Mint, including the critical libccid configuration that is hard to find anywhere."
---

I recently set up a [Pico Key OpenPGP](https://github.com/polhenarejos/pico-openpgp) running on a Raspberry Pi Pico 2 (RP2350) on Linux Mint 22.1, and the process had one particularly tricky step that I couldn't find documented anywhere clearly: editing the CCID driver configuration file. This post documents the full process so you don't have to spend hours figuring it out.

## What is Pico Key?

Pico Key is an open-source OpenPGP smart card implementation that runs on a Raspberry Pi Pico (RP2040 or RP2350). It turns your Pico into a hardware security key compatible with GPG, allowing you to store your private keys on the device itself. The RP2350 is the recommended chip as it has hardware security features like Secure Boot and OTP memory for key encryption.

## Prerequisites

- Raspberry Pi Pico 2 (RP2350) with pico-openpgp firmware flashed
- Linux Mint 22.1 (or similar Ubuntu/Debian-based distro)
- GPG and pcscd installed

Install the required packages:

```bash
sudo apt install gpg pcscd pcsc-tools libccid
sudo systemctl enable --now pcscd
```

## Step 1: Verify the device is recognized

Plug in your Pico Key and run:

```bash
lsusb | grep -i "2e8a"
```

You should see something like:

```
Bus 001 Device 011: ID 2e8a:10ff Pol Henarejos Pico Key
```

If the device shows up here but `gpg --card-status` returns nothing, keep reading — that's exactly the problem this post solves.

## Step 2: Create the udev rule

Without a udev rule, regular users can't access the device. Create the rule file:

```bash
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="10ff", MODE="0660", TAG+="uaccess", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/60-pico-openpgp.rules
```

Reload the rules:

```bash
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Unplug and replug the device.

## Step 3: The critical step — editing the CCID driver (libccid)

This is the part that is almost never documented for Linux Mint. The GPG CCID driver has an internal whitelist of supported devices. The Pico Key VID/PID (`2E8A:10FF`) is not on it by default, so GPG simply ignores the device even though the OS can see it.

The `Info.plist` file in the CCID bundle is actually a symlink:

```bash
ls -la /usr/lib/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist
# lrwxrwxrwx ... Info.plist -> /etc/libccid_Info.plist
```

The real file is `/etc/libccid_Info.plist`. Edit it with sudo:

```bash
sudo nano /etc/libccid_Info.plist
```

You need to add **three entries** — one in each array — at the **same position**. The arrays must always have the same number of elements. The safest approach is to add your entries as the first item in each array.

Find the `ifdVendorID` array and add `0x2e8a` as the first entry:

```xml
<key>ifdVendorID</key>
<array>
    <string>0x2e8a</string>
    <string>0x072F</string>   <!-- existing entries below -->
    ...
</array>
```

Find the `ifdProductID` array and add `0x10ff` as the first entry:

```xml
<key>ifdProductID</key>
<array>
    <string>0x10ff</string>
    <string>0x90CC</string>   <!-- existing entries below -->
    ...
</array>
```

Find the `ifdFriendlyName` array and add the name as the first entry:

```xml
<key>ifdFriendlyName</key>
<array>
    <string>Pico Key OpenPGP</string>
    <string>ACS ACR 38U-CCID</string>   <!-- existing entries below -->
    ...
</array>
```

Save the file, then restart pcscd:

```bash
sudo systemctl daemon-reload
sudo systemctl restart pcscd
gpgconf --kill gpg-agent
```

## Step 4: Verify GPG can see the card

```bash
gpg --card-status
```

You should now see something like:

```
Reader ...........: Pico Key OpenPGP [Pico Key CCID OTP FIDO Interfac] (2CB19BCF...) 00 00
Application ID ...: D276000124010304FFFE2CB19BCF0000
Application type .: OpenPGP
Version ..........: 3.4
...
```

## Step 5: Back up your GPG key

Before moving anything to the card, back up your private key. This is critical because `keytocard` **moves** the key, not copies it.

```bash
gpg --list-secret-keys --keyid-format LONG
gpg --export-secret-keys --armor YOUR_KEY_ID > private-key-backup.asc
gpg --export --armor YOUR_KEY_ID > public-key-backup.asc
gpg --export-ownertrust > trustdb-backup.txt
```

Copy these files to a USB drive (FAT32 works fine) and store it offline in a safe place.

## Step 6: Configure the card PINs

The default user PIN is `123456` and the default Admin PIN is `12345678`. Change both immediately.

```bash
gpg --card-edit
```

Inside the prompt:

```
admin
passwd
```

- Option **1** → change user PIN (must be 6+ digits)
- Option **3** → change Admin PIN (must be 8+ digits)

Store these PINs safely. After **3 wrong attempts** the card locks and requires the Admin PIN to unlock. If the Admin PIN is also entered wrong 3 times, only the Reset Code can recover it — and that wipes the card.

## Step 7: Enable physical button confirmation (UIF)

The RP2350 has a user button (not the BOOTSEL button — use the RST/user button) that can be required for each cryptographic operation. This adds a physical presence requirement so no software can silently use your key.

Still inside `gpg/card>`:

```
uif 1 on
uif 2 on
uif 3 on
quit
```

- `uif 1` → require button press for signing
- `uif 2` → require button press for decryption
- `uif 3` → require button press for authentication

Each command will ask for your Admin PIN.

## Step 8: Move your key to the card

```bash
gpg --edit-key YOUR_KEY_ID
```

Inside the prompt:

```
keytocard
```

Select slot **1** (Signature) for your primary key. Confirm the move and then:

```
save
```

## Step 9: Verify

```bash
gpg --card-status
```

The `Signature key` field should now show your key fingerprint instead of `[none]`.

## Day-to-day usage

When signing a Git commit, GPG will:

1. Ask for the **card PIN** (numeric, cached for a session)
2. Wait for a **button press** on the RST button (if UIF is enabled)
3. Ask for your **key passphrase**

To verify signed commits in your Git log:

```bash
git log --show-signature
# or more compact:
git log --pretty="format:%h %G? %aN %s"
```

The `%G?` field shows `G` for a valid signature, `B` for bad, and `N` for unsigned.

## Summary

The key insight for Linux Mint (and other Debian/Ubuntu-based distros) is that the Pico Key's VID/PID is not in the CCID driver whitelist by default. You must manually add it to `/etc/libccid_Info.plist` — which is not `/usr/lib/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist` directly, but a symlink pointing to that file. This single step is what makes everything work, and it's almost impossible to find documented anywhere.

