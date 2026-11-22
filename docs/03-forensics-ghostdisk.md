# GhostDisk · 64 MiB NTFS 镜像取证（4 条 flag）

> Flags: **4 条**（正文已脱敏，格式均为 `hkcert26{...}`；本文按 C1–C4 指代）
> 类别: Forensics

## 0. 证据来源

```
401Unauthorized_Data\StreamingAssets\content\ghostdisk\case-bb4471-usb.dd.gz
```

解压后是 **64 MiB raw 磁盘镜像**。MBR，分区 1 类型 `0x07`，起始 LBA 128，NTFS。
本文所有偏移都相对于解压后的 `case-bb4471-usb.dd`。

游戏内这条支线计 `eggs /4`，正好对应四条 flag。

## 1. 镜像结构

```
offset 0        MBR，分区表第一项：type=0x07, LBA=128, sectors=128896
offset 65536    NTFS VBR（"NTFS    "），bytes/sector=512, sectors/cluster=8
                $MFT LCN = 5370
```

MFT 记录大小 1024 B（`clusters_per_mft = -10`）。
写了个最小 NTFS 解析器遍历 MFT，得到 **137 条记录（133 in-use）**。

关键文件：

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

## 2. Flag 1 — asset tag

`BH-README.txt`：

```
BAUHINIA UFD 8G - factory defaults
=================================
asset tag : hkcert26{REDACTED}  (Black Bauhinia Studio property - return to IT)
Firmware DFU 1.2.7. Do not reformat (wear-level table on board).
```

白给。基本功：`ntfs_list.txt` 里翻一遍所有文件名和文本内容。

## 3. Flag 2 — 蓝图 LSB（本题最巧）

`ZDT-2.2.0-RC1.ZIP`（回收站里还有一份 `$R9K266D.ZIP`）内含
`BLUEPRINT-48bpp.tif`：**512×384，16 bit × 3 通道，未压缩**。

### 错误思路

常规 LSB 隐写是「取每像素最低 bit → 每 8 bit 拼成一个字节 → 找 ASCII」。
这题这样拼出来是**纯噪点**。

### 正确思路

把每个 16-bit 样本的 **bit 0** 取出来，按 512×384 **直接渲染成二值图**：

```python
from PIL import Image
import numpy as np

# arr: (384, 512, 3) uint16
bits = ((arr >> 0) & 1).astype("uint8") * 255
Image.fromarray(bits[:, :, 0]).save("lsb_ch0.png")
```

图上直接写着字：

```
BLACK BAUHINIA HEIST
BLUEPRINT ZDT-2.2.0-RC1

REDEEM CODE:
hkcert26{REDACTED}

DELETED IS A LIE.
THE LAST BIT REMEMBERS.
```

> **关键点**：bit 平面本身就是一张图，不是字节流。
> 16-bit 深度给了充足的信道 —— 视觉上看不出任何差异。

三个通道分别是独立的图（`if_bit0_ch0/1/2.png`），只有 ch0 有内容。

## 4. Flag 3 — Git dangling blob

镜像根目录有完整 `.git`（含 `pack`）。

### 先看 notes

```bash
git --git-dir=.git notes list
git --git-dir=.git show a9095a2
```

notes 里写着 "burn list"：

```
EXFIL.md        - after the window closes
HANDOFF.txt     - travels with me, never on a branch
render-list.txt - keep, looks innocent
```

**"never on a branch"** 是提示：目标文件不在任何分支上。

### 找 unreachable 对象

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

同一个 blob 也出现在 unreachable commit `3b3e91d`
（commit message: `witness: the blueprint remembers`）的 tree 里。

### 干扰项

`.git` 的 pack 被**故意损坏**（idx magic `0xFF` → `0x3F`，pack offset 475 zlib 校验错）。
但不影响 loose object 的读取，属障眼法。

## 5. Flag 4 — 回收站 + 删除时刻做 key（题眼）

回收站里：

- `$I49OA66.GHOST`（58 B）— 记录**原始路径**
- `$R49OA66.GHOST`（117 B）— **实际内容**

### `$I` 的结构

```
[0:8]    头
[8:16]   原始大小
[16:24]  删除 FILETIME
[24:28]  路径长度
[28:]    UTF-16 原始路径
```

### 取删除时间

```
FILETIME = 0x01DD4F0EFC2E1D80
UTC      = 2026-09-28 06:02:47
HKT      = 2026-09-28 14:02:47
```

```
→ key = "140247"   (HHMMSS, case clock)
```

### `$R` 的内容

```
GHOSTVAULT1
seal: the moment i killed it (HHMMSS, case clock)
cipher: sha256-counter xor
<29 bytes ciphertext>
```

### 解密

counter 从 0 开始，4 字节小端，`SHA256(key || counter)` 生成 keystream：

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

> **题眼**：`deleted is not gone`。
> `$I` 文件看起来是垃圾，实际保存了 `$R` 的解密参数（删除时刻）。
> 删得掉的是数据，删不掉的是元数据。

## 6. 佐证材料（不直接出 flag）

| 文件 | 内容 |
|---|---|
| `ghost_manifest.txt`（已删除，MFT 记录 51） | serial `BB-4471-9527`，mount `2026-09-28 13:58`，"the key is the moment i killed it." |
| `EXFIL.md` | window `2026-09-28 13:59 - 14:02 case clock` |
| `spec-2.2.0-rc1.md` | canary `ZDT-RC1-b3e5`；unreachable blob 里还有 retired canary `ZDT-RC1-AAAA` |
| `web/servicepipe.fp.js` | 前端指纹脚本（未深入） |

## 7. 案件板（游戏内）

GhostDisk 工作台有一块案件板（BB-2026-0928），列出官方解法路径：

```
C1  VBR serial @0x48（16 hex）
C2  ghost_manifest.txt
C3  recycled archive name
C4  vault original path
C5  HHMMSS deletion time
C6  erased gap word
Part 2  16-bit TIFF LSB
Part 3  .git reflog
```

和实际解法完全一致。

## 8. 镜像指纹

```
MD5     ef643081b827df75ae1cae4fb8e549d1
SHA256  c17ece4fe080e882b665dd83fda20fb3326946b68a7b0e52372ff277b62ecc79
大小    67,108,864 bytes
MFT     256 条记录
```

## 9. 工具

| 文件 | 作用 |
|---|---|
| `ntfs_list.txt` / `ntfs_files.json` | MFT 遍历结果 |
| `dd_strings.txt` | 镜像全量 strings |
| `stego.py` | PNG/TIFF 位平面排查 |
| `decode.py` | Vault XOR 解密 |

## 10. 复盘

| 题目设计 | 学到的 |
|---|---|
| asset tag 放在 README | 先 `strings` 全盘，别急着上工具 |
| LSB 要"看图"不要"提字节" | 位平面 → 图像，是隐写的基本功之一 |
| notes 里写 "never on a branch" | `git fsck --unreachable` 应该是肌肉记忆 |
| `$I` 的删除时间当密钥 | 回收站是取证富矿，元数据即密钥 |
| pack 故意损坏 | 干扰项，loose object 不受影响 |

四条 flag 的获取路径完全独立，是一条完整的取证链：
**文件系统 → 图像隐写 → 版本控制 → 加密容器**。
