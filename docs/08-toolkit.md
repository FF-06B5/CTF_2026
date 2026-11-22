# Toolchain · Windows GUI and CEF automation

This page is the most reusable thing to come out of the event.

## 0. Why it was needed

The target is a hybrid: a **Unity client** with an **embedded CEF** (UnityWebBrowser).

- the game itself is Unity (pixel-art 2D)
- each "facility" opens a CEF webview room
- many achievements live inside the webview (text fields, buttons, drag targets)

There is no API, so everything had to be driven from outside.

## 1. Screenshots

```powershell
capture.ps1 -Out shot.png
# WIN pid=... hwnd=... size=3222x1856 fg=True
# PRINTWINDOW=True SAVED=shot.png
```

`PrintWindow` works even when the window is occluded.

**Key trap:** the window is physically `3222×1856`, but a non-DPI-aware process sees `2148×1237`
(a 1.5× difference). All coordinates must be physical pixels — call `SetProcessDPIAware()` first.

## 2. Mouse

```powershell
click.ps1 -X 1611 -Y 1056 -Mode click|dbl|click2|move
```

Coordinates are **window-relative physical pixels**; the script re-reads `GetWindowRect` every time.

Three lessons:

1. **The window moves** — this session went from `(787,23)` to `(531,125)`; hard-coded absolute
   coordinates always break
2. **The first click often only focuses**, so double up (`-Mode click2`, 420 ms apart — just above
   the double-click threshold)
3. **Hover matters** — some buttons need `mouseover` before they arm; the script moves the cursor and
   waits 220 ms before clicking

## 3. Keyboard

```powershell
keys.ps1 -Seq "W:500,A:300,E:150"
```

`key:hold-ms`, supporting ESC/WASD/TAB/ENTER/arrows/letters/digits.

**Focus**: a bare `SetForegroundWindow` frequently fails. You must attach the current thread to the
foreground window's input queue:

```csharp
AttachThreadInput(curThread, fgThread, true);
BringWindowToTop(hwnd);
SetForegroundWindow(hwnd);
```

## 4. Text input (the biggest trap)

Five versions were written; only the last worked:

| Script | Method | Result |
|---|---|---|
| `type.ps1` / `input.ps1` | click + Ctrl+A + Delete + SendKeys | ❌ Ctrl+A/Delete dead in CEF |
| `type2.ps1` | `SendKeys` | ❌ never reaches CEF |
| `type3.ps1` | `SendInput` + `KEYEVENTF_UNICODE` | ❌ `SendInput` returns 0 |
| `type4.ps1` | `keybd_event` + `KEYEVENTF_UNICODE` | ❌ call succeeds, characters do not land |
| **`type6.ps1`** | `keybd_event` + VK + **`MapVirtualKey` scan code** | ✅ works |

### Core code

```csharp
[DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
[DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);

byte sc = (byte)MapVirtualKey(vk, 0);
keybd_event(vk, sc, 0, UIntPtr.Zero);      // down
keybd_event(vk, sc, 0x0002, UIntPtr.Zero); // up
```

**Without a scan code CEF drops the key silently, while the API still reports success** — the worst
kind of failure.

### Character mapping

Shift has to be handled by hand (letters / digits / space / period / comma / colon = shift + `0xBA` /
quotes / question mark, …).

### Rate

Many CEF inputs process **one keystroke per rendered frame** (see Typeway 2000).
A safe cadence is **40–50 ms/char** (above the 33 ms frame).

## 5. CEF forensics

| Script | Purpose |
|---|---|
| `cef.py` | walk the webview temp dirs, export `History` |
| `cookies.py` | read `Network\Cookies` (v10 DPAPI) |
| `cefcookie.py` | simplified cookie extractor |

### Locating the webview directory

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'user-data-dir' } |
  Select-Object ProcessId, Name, CommandLine
```

The `UnityWebBrowser.Engine.Cef.exe` command line exposes it directly:

```
--user-data-dir="C:\Users\<user>\AppData\Local\Temp\401Unauthorized\webview\<id>\cache"
```

### Reading History

```python
import sqlite3
con = sqlite3.connect(history_copy)
for url, title, visits in con.execute(
        "SELECT url, title, visit_count FROM urls ORDER BY last_visit_time DESC"):
    print(visits, "|", title, "|", url)
```

`History` is **unencrypted** and the most valuable recon target; `Network\Cookies` is exclusively
locked and needs "leave the room, then copy".

## 6. Stego triage

```powershell
stego.py -f poster.png
```

Covers:

- PNG container: chunk walk, trailing data, `tEXt` / `zTXt`
- LSB: bit-planes (**rendered as images**, not packed into bytes)
- QR decoding (`zxing-cpp`)

## 7. HTTP

PowerShell 5.1's TLS stack is broken on this machine (`SEC_E_NO_CREDENTIALS`), so every request went
through Node:

```powershell
node probe.mjs -url https://target -paths /open,/session,/
node getroom.cjs <url> out.html
```

## 8. PowerShell traps

| Trap | Symptom | Fix |
|---|---|---|
| Execution policy | scripts refuse to run | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File` |
| Non-ASCII paths mangled | `实战` → `瀹炴垬` | keep output paths ASCII |
| `"$i:"` parsed as a drive | array index errors | write `${i}:` |
| `node -e` with quotes/regex | arguments eaten by PowerShell | put it in a `.mjs` / `.cjs` file |
| negative `mouse_event` delta | `uint` cast throws | use `[uint32]4294967176` (2³²−120) |
| BOM on write | stray character in markdown | `[IO.File]::WriteAllText` + `UTF8Encoding($false)` |

## 9. File inventory

| Script | Purpose |
|---|---|
| `capture.ps1` | PrintWindow screenshot + window info |
| `click.ps1` | DPI-aware click (click / dbl / click2 / move) |
| `keys.ps1` | key sequences with focus stealing |
| `type6.ps1` | **VK + scan code text injection** (the only working version) |
| `cef.py` / `cookies.py` / `cefcookie.py` | CEF cache / cookie forensics |
| `stego.py` | PNG container + LSB triage |
| `poster.py` | poster cropping + enhancement variants |
| `probe.mjs` | HTTP probing |
| `getroom.cjs` | fetch a room page |
| `inject.mjs` | ticket injection tests |
| `yt.mjs` | YouTube channel fetch |

## 10. General advice

1. **Build echo verification into automation** — type → screenshot → compare; never fire blind
2. **Never hard-code coordinates** — derive them from the window rect every time
3. **Synthetic input fails in three ways**: API returns failure, API returns success but the event is
   dropped, and the event lands but a frame gate discards it. Only the first surfaces as an error —
   the other two require echo verification
4. **Temp directories are gold**: `%TEMP%\<AppName>\webview\<id>\cache\Default\` holds
   History / Preferences / Local Storage / Cookies
