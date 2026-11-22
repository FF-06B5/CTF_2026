# GhostDisk · 64 MiB NTFS image forensics (4 flags)

> Flags: **4** (bodies redacted; referred to as C1–C4 below)
> Category: Forensics

## 0. Evidence source

```
401Unauthorized_Data\StreamingAssets\content\ghostdisk\case-bb4471-usb.dd.gz
```

Decompresses to a **64 MiB raw disk image**. MBR, partition 1 type `0x07`, start LBA 128, NTFS.
All offsets below are relative to the decompressed `case-bb4471-usb.dd`.

This in-game storyline tracks `eggs /4` — exactly the four flags.

## 1. Image structure

```
offset 0        MBR, first partition entry: type=0x07, LBA=128, sectors=128896
offset 65536    NTFS VBR ("NTFS    "), bytes/sector=512, sectors/cluster=8
                $MFT LCN = 5370
```

MFT record size 1024 B (`clusters_per_mft = -10`).
A minimal NTFS parser walked the MFT: **137 records (133 in use)**.

Key files:

```
BH-README.txt
EXFIL.md
VAULT.GHOST
ZDT-2.2.0-RC1.ZIP
$RECYCLE.BIN/S-1-5-.../$I49OA66.GHOST
$RECYCLE.BIN/S-1-5-.../$R49OA66.GHOST
$RECYCLE.BIN/S-1-5-.../$I9K266D.ZIP
.git/...
```

## 2. Flag 1 (C1) — asset tag

`BH-README.txt`:

```
BAUHINIA UFD 8G - factory defaults
=================================
asset tag : hkcert26{REDACTED}  (Black Bauhinia Studio property - return to IT)
Firmware DFU 1.2.7. Do not reformat (wear-level table on board).
```

Free points. The basic move: walk every filename and text blob (`ntfs_list.txt`).

## 3. Flag 2 (C2) — blueprint LSB (the clever one)

`ZDT-2.2.0-RC1.ZIP` (a copy also sits in the recycle bin as `$R9K266D.ZIP`) contains
`BLUEPRINT-48bpp.tif`: **512×384, 16 bit × 3 channels, uncompressed**.

### Wrong approach

Classic LSB steganography is "take the lowest bit of each pixel → pack 8 bits into a byte → look for
ASCII". Here that yields **pure noise**.

### Right approach

Take **bit 0** of every 16-bit sample and render it as a **512×384 binary image**:

```python
from PIL import Image
import numpy as np

# arr: (384, 512, 3) uint16
bits = ((arr >> 0) & 1).astype("uint8") * 255
Image.fromarray(bits[:, :, 0]).save("lsb_ch0.png")
```

The image literally spells out:

```
BLACK BAUHINIA HEIST
BLUEPRINT ZDT-2.2.0-RC1

REDEEM CODE:
hkcert26{REDACTED}

DELETED IS A LIE.
THE LAST BIT REMEMBERS.
```

> **The point:** the bit-plane *is* an image, not a byte stream.
> 16-bit depth provides plenty of channel — visually indistinguishable.

The three channels are independent images (`if_bit0_ch0/1/2.png`); only ch0 carries content.

## 4. Flag 3 (C3) — git dangling blob

The image root has a full `.git` (including a pack).

### Start with notes

```bash
git --git-dir=.git notes list
git --git-dir=.git show a9095a2
```

The note holds a "burn list":

```
EXFIL.md        - after the window closes
HANDOFF.txt     - travels with me, never on a branch
render-list.txt - keep, looks innocent
```

**"never on a branch"** is the hint: the target is not reachable from any ref.

### Find unreachable objects

```bash
git --git-dir=.git fsck --full --unreachable --no-reflogs
# unreachable blob 00b31d48a32fb8435566fd440f958e8e2a99d800
git --git-dir=.git cat-file -p 00b31d48a32fb8435566fd440f958e8e2a99d800
```

```
HANDOFF - if you can read this, my reset failed.
...
proof for whoever finds this: hkcert26{REDACTED}

- 4471
```

The same blob also appears in unreachable commit `3b3e91d`
(commit message: `witness: the blueprint remembers`).

### Decoy

The `.git` pack is **deliberately corrupted** (idx magic `0xFF` → `0x3F`, zlib checksum error at pack
offset 475). It does not affect loose-object reads — a red herring.

## 5. Flag 4 (C4) — recycle bin with the deletion time as key (the crux)

Recycle bin contents:

- `$I49OA66.GHOST` (58 B) — records the **original path**
- `$R49OA66.GHOST` (117 B) — the **actual payload**

### `$I` layout

```
[0:8]    header
[8:16]   original size
[16:24]  deletion FILETIME
[24:28]  path length
[28:]    UTF-16 original path
```

### Extract the deletion time

```
FILETIME = 0x01DD4F0EFC2E1D80
UTC      = 2026-09-28 06:02:47
HKT      = 2026-09-28 14:02:47
```

```
→ key = "140247"   (HHMMSS, case clock)
```

### `$R` content

```
GHOSTVAULT1
seal: the moment i killed it (HHMMSS, case clock)
cipher: sha256-counter xor
<29 bytes ciphertext>
```

### Decrypt

Counter from 0, 4-byte little endian, `SHA256(key || counter)` as the keystream:

```python
import hashlib, struct

key = b"140247"
stream = b"".join(
    hashlib.sha256(key + struct.pack("<I", i)).digest()
    for i in range(4)
)
plain = bytes(a ^ b for a, b in zip(ct, stream))
# b'hkcert26{REDACTED}'
```

> **The crux:** `deleted is not gone`. `$I` looks like junk but stores the decryption parameter
> (the deletion timestamp). You can delete the data; you cannot delete the metadata.

## 6. Corroborating material (no flag on its own)

| File | Content |
|---|---|
| `ghost_manifest.txt` (deleted, MFT record 51) | serial `BB-4471-9527`, mount `2026-09-28 13:58`, "the key is the moment i killed it." |
| `EXFIL.md` | window `2026-09-28 13:59 - 14:02 case clock` |
| `spec-2.2.0-rc1.md` | canary `ZDT-RC1-b3e5`; an unreachable blob also holds the retired canary `ZDT-RC1-AAAA` |
| `web/servicepipe.fp.js` | frontend fingerprinting script (not pursued) |

## 7. The in-game case board

The GhostDisk workstation has a case board (BB-2026-0928) listing the intended path:

```
C1  VBR serial @0x48 (16 hex)
C2  ghost_manifest.txt
C3  recycled archive name
C4  vault original path
C5  HHMMSS deletion time
C6  erased gap word
Part 2  16-bit TIFF LSB
Part 3  .git reflog
```

Consistent with what we did.

## 8. Image fingerprint

```
MD5     ef643081b827df75ae1cae4fb8e549d1
SHA256  c17ece4fe080e882b665dd83fda20fb3326946b68a7b0e52372ff277b62ecc79
Size    67,108,864 bytes
MFT     256 records
```

## 9. Tooling

| File | Purpose |
|---|---|
| `ntfs_list.txt` / `ntfs_files.json` | MFT walk output |
| `dd_strings.txt` | full-image strings |
| `stego.py` | PNG/TIFF bit-plane triage |
| `decode.py` | Vault XOR decryption |

## 10. Retrospective

| Design choice | Lesson |
|---|---|
| asset tag in a README | `strings` the whole image first, before reaching for tools |
| LSB meant "as an image", not "as bytes" | bit-plane → picture is a core stego reflex |
| notes say "never on a branch" | `git fsck --unreachable` should be muscle memory |
| `$I` deletion time is the key | recycle bins are forensic gold; metadata *is* the key |
| pack deliberately corrupted | decoy — loose objects are unaffected |

The four flags form a complete chain:
**filesystem → image steganography → version control → encrypted container**.
