# Untranslated Signal · Egyptian hieroglyphs

> Flag: `hkcert26{REDACTED}`
> Category: Misc / Crypto

## 1. The challenge

The second "undecipherable tablet" — this time Egyptian hieroglyphs
(Unicode `U+13000`–`U+1342F`). Same pattern: first line is the flag, body is English.

## 2. The difference: the key is handed over

Unlike the cuneiform challenge, the body's five lines are the **pangram**:

```
the quick brown fox jumps over the lazy dog
```

Word by word, that gives a **complete 26-letter mapping**, no gaps. The authors effectively wrote the
key onto the challenge itself.

## 3. The table

```
𓉔 h  𓈎 k  𓎡 c  𓇋 e  𓂋 r  𓏏 t
𓐍 q  𓅱 u  𓇌 i  𓎼 g  𓅓 m  𓊪 p
𓋴 s  𓃭 l  𓄿 a  𓃀 b  𓂧 d  𓁹 o
𓇳 w  𓆑 f  𓂀 x  𓊽 z  𓆓 y  𓈖 n
𓆣 j  𓋹 v
```

Correspondence, word by word:

| Word | Glyphs |
|---|---|
| the | 𓏏 𓉔 𓇋 |
| quick | 𓐍 𓅱 𓇌 𓎡 𓈎 |
| brown | 𓃀 𓂋 𓁹 𓇳 𓈖 |
| fox | 𓆑 𓁹 𓂀 |
| jumps | 𓆣 𓅱 𓅓 𓊪 𓋴 |
| over | 𓁹 𓋹 𓇋 𓂋 |
| lazy | 𓃭 𓄿 𓊽 𓆓 |
| dog | 𓂧 𓁹 𓎼 |

## 4. Decoding the flag line

The flag line is a single glyph run; substituting each symbol via the table above yields:

```
h k c e r t 26 { …body redacted… }
```

→

```
hkcert26{REDACTED}
```

## 5. Why this one was "easy"

The flag plaintext is a plain-English phrase — the authors themselves treated this as a giveaway.
(Flag body redacted; the hex suffix is an anti-guess random segment.)

Both flags in this family use a random hex suffix, but the prefix is semantic, so
**guess the word shape first, then confirm against the source file** is a viable strategy.

## 6. Probes

| File | Purpose |
|---|---|
| `ocr.py` / `ocr2.py` / `ocr3.py` | glyph segmentation + clustering |
| `ref.npz` / `ref2.npz` | reference glyph features |
| `half.py` / `lines.py` / `chunks.py` | layout segmentation |
| `decoded.txt` | final decoded plaintext |

## 7. Retrospective

- Both challenges share one method: **classify as substitution → find a Rosetta stone → build the
  table → substitute**
- The cuneiform one is hard because of segmentation; this one is nearly free because the key is complete
- The real efficiency difference was **thinking to look in `StreamingAssets/content/dialogs`**
