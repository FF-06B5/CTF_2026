# Event, rules, and working environment

This page covers two things: **what the competition actually was**, and **under what conditions we
played it**. The latter explains every technical choice that follows.

## 1. Event overview

| Item | Detail |
|---|---|
| Name | HKCERT CTF 2026 · Qualifier |
| Window | 2026-11-06 18:00 → 2026-11-07 18:00 (HKT, 24 h online) |
| Format | Not classic Jeopardy — a Unity game client, `401Unauthorized` |
| Categories | Binary Exploitation / Cryptography / Forensics / Reverse / Web / Misc |
| Scoring | **achievements (dynamic value)**, not flag count |
| Flag format | `hkcert26{[a-z0-9_]+}` |

From the Contest Format / Important Dates pages:

- 24 hours non-stop;
- players explore the game world, find clues, complete tasks;
- advancing required writeups for **3 challenges**.

## 2. Rules (from `platform.ctf.hkcert.org/rules`)

### Authorized scope

- ✅ any-level subdomains of `*.chal.sh`, and the hosts/services they resolve to
- ✅ other resources explicitly provided by the organisers
- ❌ `pwnable.hk`, `hkcert.org` (main site, not `chal.sh`)
- ❌ official Discord / support channels
- ❌ the competition platform itself (`platform.ctf.hkcert.org`)

### Prohibited

- DoS / flooding / any resource-exhaustion attack
- attacking the platform
- social engineering (organisers or other players)
- sharing flags / accounts / solutions outside the team; leaking challenge content before the event

### On AI

AI tools are **explicitly allowed**, with one hard requirement:

> A review writeup must document the **analysis process and human verification** — not just prompts
> or final answers.

That requirement shapes this whole document — see [README §7](../README.md#7-honesty-statement-and-ai-usage).

### Teams

Up to 4 members.

## 3. Extracting the rules page (first small trick)

`https://platform.ctf.hkcert.org/rules` is a **Vite SPA**: the body is not in the HTML, it is baked
into `assets/index-*.js`.

Approach (Node `fetch`):

```js
// 1. fetch the landing HTML, grab <script src=".../assets/index-*.js">
// 2. download the bundle, locate the rules fragment
const m = js.match(/hkcert26\{[\s\S]*?var ug=F\(/);
// 3. pull the three markdown copies out of the fragment
//    en / zh-Hant / zh-Hans
```

With three language copies in hand, the rules become fully searchable.

> For SPA sites that inline their content into the bundle, `Ctrl+U` shows nothing —
> go straight to `assets/*.js`.

## 4. Working environment

| Item | Value |
|---|---|
| OS | Windows 10/11 |
| Shell | PowerShell 5.1 |
| Python | 3.11.9 (with `cryptography` / `numpy` / `Pillow` bundled) |
| Missing tools | 7z, Ghidra, IDA, Wireshark, Docker |

### Pitfall 1: broken TLS stack

Both `curl.exe` and PowerShell's SChannel fail on this machine:

```
SEC_E_NO_CREDENTIALS
```

All HTTPS traffic moved to Node's `fetch` (`probe.mjs` / `getroom.cjs` / `yt.mjs`) or Python `urllib`.

### Pitfall 2: no archivers

Archives were handled with Python's `zipfile` / `gzip`; the disk image needed a hand-written minimal
NTFS parser (its output is `_read/ntfs_*.txt`).

### Pitfall 3: no OCR library

Glyph segmentation and clustering used **only Pillow + numpy** — no Tesseract, no PaddleOCR.

## 5. Redemption mechanics (client-side evidence)

The easiest thing to get wrong in this event: **flags are not submitted on a web page**.

### Localisation strings

```
Mervyn: 兌換代碼讓你輸入代碼，領取對應獎勵。
每個 hkcert26{...} 代碼：到「兌換代碼」視窗兌換
兌換代碼 / 輸入代碼 / 兌換
代碼已兌換：{0}。
此代碼已兌換過。
```

### Code evidence

`CTFGame.UI.dll` string table contains:

```
RedeemWindow    RedeemCode    OpenRedeem    redeemButton
```

The networking layer contains:

```
AchievementClientServiceSubmitFlagRequest
AchievementClientServiceSubmitFlagResponse
```

Response fields:

```
outcome            // redemption result
achievement_id     // returned on success
text               // message shown to the player
```

### Conclusion

```
find flag  →  "redeem code" window  →  POST  →  achievement_id returned  →  achievement granted
```

**The flag → achievement mapping is server-side**; the client cannot validate it offline.

## 6. Observing the achievement system

### Unlocks visible in `Player.log`

```
gits_case_opened
up_up_down_down
vault_first_win
first_dungeon_entry
quest_beginner
```

### The client only receives events

Achievement evaluation is server-side; the client only receives `AchievementEarnedEvent`.

### The total is hidden

The achievement page showed **"unlocked 3/???"** — the denominator is hidden. We reconstructed 42
achievements from screenshots but cannot confirm completeness.

## 7. Timeline (merged across sessions)

| Time | Event |
|---|---|
| 18:03 | rules extraction (SPA bundle) |
| 18:10 | workspace + environment setup |
| 18:20–19:10 | tablet OCR route (failed, but established "this is a substitution") |
| **19:20** | **found plaintext in `StreamingAssets`; both misc challenges fell** |
| 19:30–19:50 | GhostDisk, four flags |
| 20:00+ | in-game achievements: AI Court / FinSim / arcade |
| 20:40 | AI Judge passed (`Achievement unlocked.`) |
| 21:00+ | Typeway 2000 mechanics cracked (245 WPM) |
| 22:00+ | web recon (Quick.Cms / dev-log-viewer); blocked on the cookie lock |

## 8. Three hard constraints (throughout)

1. **Authorized scope is `*.chal.sh` only** — no request left it
2. **AI is allowed, but the process must be reproducible** — every claim here carries a command or script
3. **Flags stay in-team** — redact before publishing (see [Appendix E](../README.md#appendix-e--redaction-before-publishing))
