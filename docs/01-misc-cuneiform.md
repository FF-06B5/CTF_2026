# Untranslated Tablet · monoalphabetic substitution

> Flag: `hkcert26{REDACTED}`
> Category: Misc / Crypto

## 1. The challenge

The game presents a clay tablet covered in cuneiform (Unicode `U+12000`–`U+123FF`).
The first line looks like a flag; the rest is prose.

## 2. Verdict: a substitution cipher, not pictographic writing

Real pictographic writing is one symbol per word/syllable and never produces a stable 1:1 mapping.
Three observations rule it out:

| Evidence | Data |
|---|---|
| The most frequent trigram `bda` appears **41 times**, always mapping to `the` | frequency analysis holds |
| `chi` always maps to `and`, `be` always maps to `to` | mapping is stable |
| About **26** distinct symbols | exactly one alphabet |

The first sentence decoded on that basis:

```
the traders came down from the high country before dawn
```

Fluent English → confirmed monoalphabetic substitution (26 invented symbols ↔ 26 Latin letters, with
digits and `{}_-` left untouched).

## 3. Why the screenshot route failed

In the screenshots the flag line has **3–5 px** letter spacing, so adjacent glyphs merge:

- `j u g s` is segmented into **5** glyphs
- `m` / `y` merge into one

The connected-component + clustering pipeline (`pipeline.py` / `cluster2.py`) converged on the body
but was guaranteed to fail on the flag line.

**Our best result at that stage** was guessing most of the word shape; the `jugs` section was wrong.

### 3.1 The OCR pipeline (a failure record, but the method is reusable)

No OCR library — pure Pillow + numpy:

1. **Preprocess**: grayscale → threshold to binary
2. **Line split**: horizontal projection, cut at valleys
3. **Glyph split**: vertical projection, merge fragments closer than `< 8 px`
4. **Features**: crop each glyph, normalise to **24×24 grayscale**, subtract mean, unit-normalise
5. **Clustering**: L2 distance + union-find single-link at threshold **0.55** → **39–45 clusters**
6. **Labelling**: manually map about **20 letters** against `key_sheet.png`

The body decoded (context allows error correction). **The flag line did not:**

- 3–5 px spacing means vertical projection merges neighbours into a single connected component
- Single-link clustering propagates: one bad merge swallows an entire run
- Rare letters (j/q/x/z) have the fewest samples and are mislabelled first

### 3.2 The nature of that mistake

`jugs` was segmented into **5 glyphs** in the screenshot (`j`/`u` judged as separated, and the
descender of `g` cut again). In the source file it is **4 characters**.

> This is exactly the lesson: **the bottleneck is signal-to-noise, not the algorithm.**
> 3–5 px spacing in a 3222×1856 screenshot is already at the information-theoretic floor.

## 4. The real solution: plaintext ships with the client

```
401Unauthorized_Data\StreamingAssets\content\dialogs\wedge-tablet.md
```

The first line is the flag line (symbols separated by spaces); the body is the same substitution
applied to English prose. **The authors shipped the Rosetta stone together with the ciphertext.**

With spaces removed it becomes one continuous glyph run, `hkcert26{...}` (body redacted here).
Each glyph maps 1:1 to a Latin character.

## 5. Building the table

Aligning body and English yields the key:

| Symbol | Letter | Symbol | Letter | Symbol | Letter |
|---|---|---|---|---|---|
| 𒆠 | t | 𒆳 | h | 𒆸 | e |
| 𒋗 | r | 𒀸 | a | 𒀭 | d |
| 𒍑 | s | 𒌋 | c | 𒊕 | m |
| 𒄩 | o | 𒀀 | w | 𒈲 | n |
| 𒊩 | f | 𒊺 | i | 𒄑 | g |
| 𒈗 | u | 𒈨 | y | 𒁹 | b |
| 𒇻 | p | 𒄞 | k | 𒌷 | v |
| 𒅆 | x | 𒄷 | j | | |

Full table by code point:

```
12038 a   12079 b   1230B c   1202D d   121B8 e   122A9 f
12111 g   121B3 h   122BA i   12295 m   12232 n   12129 o
122D7 r   12351 s   121A0 t   12217 u   12000 w   12228 y
12337 v   1208D l   121FB p   1211E k   12146 x   1207A q
12328 z   12137 j
```

## 6. Substituting the flag line

```
h k c e r t 26 { …body redacted… }
```

```
hkcert26{REDACTED}
```

### 6.1 The plaintext is a pangram

The flag body is a leet variant of the English pangram:

```
pack my box with five dozen liquor jugs
```

— same family as "the quick brown fox jumps over the lazy dog".

> The pangram is public material, not the secret. The unguessable part of the flag is the **random
> hex suffix** that follows it (redacted). Keeping this explanation does not let anyone reconstruct
> the flag.

This explains two things:

1. Why nearly every letter appears in the flag body (a pangram guarantees alphabet coverage)
2. Why we could "guess" the remainder with only ~20 known letters — the word shape is familiar

> Pangrams are a common carrier for substitution puzzles: one sentence covers 26 letters and is
> naturally a Rosetta stone. When the flag body reads like a leet `pack my box…`, get suspicious.

## 7. Body plaintext (English)

> The traders came down from the high country before dawn, and set their wagons
> beside the river. They had carried grain, oil and copper through the mountain
> passes, and they hoped the city would pay a fair price. A young scribe sat under
> the gate and wrote each name as the carts rolled in. All day he noted the broken
> wheel, the extra spars of willow, the quiet man who kept one sealed box on his cart.
>
> By midday the market was loud. Buyers argued over weights, children chased goats
> between the stalls, and the smell of fresh bread drifted from the ovens. A woman
> from the bronze quarter asked for six measures of salt and a dozen strips of dried
> fish. When the light failed, the scribe closed his list and walked back to the
> archive. The clay was still soft, so he pressed the last lines with care and set
> the tablet where the night air could dry it.
>
> The next morning he read the list aloud to the steward. Most names were familiar,
> yet a few belonged to people who had come from beyond the western hills. They
> brought wool, hides and a small chest of blue stones. The steward told the scribe
> to copy every line twice — once for the tax house, once for the temple. It was slow
> work: his hand cramped, the same smoke hung in the room, and the room stayed cold
> until the sun cleared the walls.
>
> He paused over one entry that did not match the others. The owner had given no
> family name, only a mark, and the goods were listed as mixed tools rather than
> food. The scribe asked the guards, but they remembered only that the stranger paid
> in silver and left before the gates shut. In the margin he drew a small star and
> left the space open, hoping a later reader might know what the mark meant.

## 8. Probes

| File | Purpose |
|---|---|
| `pipeline.py` / `cluster2.py` | line splitting, glyph splitting, clustering |
| `solve_sub.py` | dictionary pattern matching (too ambiguous on short words; unused) |
| `decode_body.py` | rebuild the body from a hand-checked table |
| `final_decode.py` / `split_decode.py` | flag-line glyph matching |
| `decode_md.py` | **the actual solution**: parse `wedge-tablet.md` directly |

## 9. Retrospective

- The hypothesis was right the whole time; what was wrong was **glyph segmentation**
- The hex suffix is an anti-guess random segment, not part of the plaintext
- The first move on this class of challenge should be `grep -r "content/dialogs"`, not OCR
