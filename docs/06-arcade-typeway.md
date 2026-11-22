# Game center · Typeway 2000 and its anti-cheat

> Achievement: `非人手速` (non-human speed) — win a Typeway 2000 race in the game center
> Location: game center (event arcade / pinball / rhythm / Four Winds mahjong)

## 1. Four machines

| Machine | Status | Notes |
|---|---|---|
| **Pinball** (Space Cadet) | playable | three achievements: `First game +10,000` / `Bank clear +75,000` / `Lane master +50,000` |
| **Four Winds** mahjong | playable | riichi, East round, 3 bots, 25,000 starting points, East 1–4 |
| **Typeway 2000** | **mechanics cracked** | typing race — the focus of this page |
| **Rhythm game** | ❌ broken | stuck at `Loading... 33%`, asset load failure |

### Pinball

```
ACHIEVEMENTS
  ★ First game   +10,000    ← unlocked
    Bank clear   +75,000
    Lane master  +50,000
```

Controls: `Z/←` left flipper, `M/→` right flipper, `Space` hold to charge the plunger then release,
`N/↑` nudge (careful: tilt).

Scoring: missions pay once each; **the orbit pump inside the gated ring pays 1,300 per hit**.

Leaderboard (anonymised; shows the table can be farmed high):

```
PLAYER_1   42,267,200
PLAYER_2   41,464,600
PLAYER_3   37,597,300
PLAYER_4   36,190,300
PLAYER_5   20,092,800
```

### Four Winds mahjong

```
FOUR WINDS · 四風連鎖 · JAPANESE RIICHI MAHJONG
Start a match — Bot difficulty: Low / Medium / Hard / Extreme
東風戦 · EAST 1-4 · Starting points 25,000 · 3 bots
```

The rules panel is complete (riichi / tsumo / ron / yaku) — a real implementation, not a placeholder.

---

## 2. Typeway 2000 (the main event)

### 2.1 Interface

```
typeway 2000 — PERSONAL TYPING WORKSTATION
LOCAL SESSION · PLAYER_01 · v1.0 / RETRO EDITION

SPEED 0 WPM | ACCURACY 100% | TIME LEFT 02:00 | PERSONAL BEST — WPM

01 RACE MONITOR   THE LOCAL LOOP / 3 LANES   — 120 SECOND RACE
  YOU      PLAYER_01     —
  BYTE     110.5 WPM     ← rival
  DOT.EXE   80 WPM       ← rival

02 TEXT BUFFER   STANDARD / 219 WORDS
  [passage]                  0 / 1145 CHARS

Race setup:
  One shuffled standard passage. Two rivals.
  Finish exactly or race for up to 120 seconds.
  [Start race]  ← The clock starts with your first keystroke.
```

### 2.2 Three layers of anti-cheat

| Protection | Behaviour | Our attempt |
|---|---|---|
| `user-select: none` | passage cannot be selected | manual copy failed |
| paste ignored | `Ctrl+V` does nothing | wrote to clipboard via PowerShell, then pasted — field unchanged |
| **one keystroke per frame** | injecting 224 chars at 6 ms/char → only 1 registered | see below |

The third is the real one. The interface says:

```
One keystroke at a time.
```

Injecting 224 characters at **6 ms/char**:

```
VK_SENT=224  CHARS=224
field result: 1 character
```

— it samples keyboard events once per rendered frame (~30 fps) and discards the rest.

### 2.3 The key to success: scan codes

Four injection strategies were tried:

| Method | Result |
|---|---|
| `SendKeys` (`type2.ps1`) | never reaches CEF |
| `SendInput` + `KEYEVENTF_UNICODE` (`type3.ps1`) | `SendInput` returns 0 (rejected) |
| `keybd_event` + `KEYEVENTF_UNICODE` (`type4.ps1`) | call succeeds, characters do not land |
| **`keybd_event` + VK + `MapVirtualKey` scan code** (`type6.ps1`) | ✅ **works** |

The only difference:

```csharp
byte sc = (byte)MapVirtualKey(vk, 0);
keybd_event(vk, sc, 0, UIntPtr.Zero);      // down
keybd_event(vk, sc, KEYUP, UIntPtr.Zero);  // up
```

**Without a scan code, CEF silently drops synthetic keys.**

### 2.4 Result

At 42 ms/char (just above one frame):

```
SPEED      245 WPM      ← 2–3× human
ACCURACY   98 %         (4 errors: case / colon)
MATCHED    223 / 1150
lead       YOU 19%  vs  BYTE 9%  vs  DOT.EXE 6%
```

**245 WPM is "non-human speed" by any definition.**

### 2.5 Why we still lost

Two reasons:

1. **The final score is the race average.**
   With only 19% typed, the result averaged down to `22 WPM` (`PERSONAL BEST 22`).
   BYTE completed 100% (110.5 WPM) and won.
2. **We could not type the whole passage.**
   `TEXT BUFFER` is a fixed **3-line viewport**:
   - the mouse wheel scrolls the **outer page** (it jumps to User Guide)
   - the scrollbar does not drag
   - the input box covers line 4

   **Only ~250 of the 1145 characters are readable**, and unreadable text cannot be injected.

### 2.6 Winning conditions (derived)

| Metric | Value |
|---|---|
| Passage length | 1140–1150 chars (208–219 words) |
| Time limit | 120 s |
| BYTE | 110.5 WPM → ~552 chars/min → ~124 s for 1145 chars |
| Needed | finish 1145 chars within 120 s |

At 20 chars/s (50 ms/char, safely above one frame): **1145 chars ≈ 57 s**, final WPM ≈ **240** —
comfortably enough.

So the only blocker is: **get the full passage readable**.

### 2.7 Possible next steps (untested)

1. **Maximise the window / raise resolution** so `TEXT BUFFER` shows more lines
2. **Fetch the passage from the server** — the room page lives at
   `https://game.cgo.chal.sh/s/<room>/<session>/` and needs the session cookie (exclusively locked by CEF)
3. Edit the CSS via devtools — not available

---

## 3. Retrospective

| Lesson | Detail |
|---|---|
| Synthetic keys need a scan code | the sharpest difference between CEF and plain Win32 controls; `MapVirtualKey` solves it in one line |
| Anti-cheat works per frame | 30 fps ⇒ at most 30 recognisable keystrokes per second; injecting faster is wasted |
| Confirm the grading metric first | instantaneous WPM and race-average WPM are different metrics; we optimised the former and lost the latter |
| Readability is a hard constraint | the text exists only in a 3-line viewport — a physical limit by design |

General approach for in-game achievements:

1. Read the **achievement condition** (here it is literal: non-human speed)
2. Look for a **mechanism shortcut** (copy/paste, scripted injection) instead of grinding skill
3. Validate every protection layer separately (select → paste → inject → rate)
