# Webview rooms · CEF forensics and CMS auth

> Location: staff tools → dev log viewer / upcoming events → CMS
> Status: recon done, session never obtained

## 1. Room architecture

Each facility is backed by a webview room on a random host:

```
auth            https://auth.cg.chal.sh/
room websocket  wss://r-<hash>.cg.chal.sh/room
webview entry   https://r-<hash>.cg.chal.sh/_webview/signin
```

All under `cg.chal.sh` / `cgo.chal.sh` (inside the authorized scope).

CEF's `History` reveals concrete rooms:

```
https://game.cgo.chal.sh/s/<room-hash>/<session-hash>/
https://game.cgo.chal.sh/open#<43-char ticket>
https://cms-<hash>.cgo.chal.sh/
```

## 2. Session model

Reversed from `/open`'s frontend JS:

```js
ticket = location.hash.slice(1)            // 43 chars [A-Za-z0-9_-]
POST /session {"ticket": ticket}           // credentials: same-origin
  -> { path: "/",
       status_path: "/_office/visit/status",
       state: "ready" | "preparing" }
  -> Set-Cookie
GET /                                      // requires the cookie, else 401
```

Verified:

| Action | Result |
|---|---|
| `GET /` without cookie | `401: Unauthorized` (aiohttp) |
| `GET /open` | `200`, the bootstrap page (public) |
| replay a historical ticket | `403: Forbidden` (one-shot, consumed) |

`WWW-Authenticate: Bearer` — a token is required, issued via OAuth
(`refresh_token` / `access_token` / `RefreshAccessToken`).

## 3. Dev log viewer

Entry: lobby, press `E` → staff tools → dev log viewer.

```
LOG_ROOT/
  code-review    11/5 20:43:11
  deployment     11/5 20:43:11
  development    11/5 20:36:25   ← different timestamp
  incident       11/5 20:43:11
  retrospective  11/5 20:43:11
  testing        11/5 20:43:11
```

Note: directory rows are opened by **double-click**, not by `QUERY`.

### The leaked log

`development/log.md` (1.75 KB):

> Alex Morgan / **CloudSync Dashboard**
> - dark-mode toggle (follows the system)
> - backend: `PATCH /api/v1/user/preferences` → PostgreSQL, **JWT validation middleware**
> - frontend: Tailwind + React, state in `localStorage`
> - Next.js hydration mismatch → useEffect + defaults

Attack surface: IDOR / broken access control, JWT algorithm confusion or weak secret, SQLi, XSS.

`incident/` is empty (`NO LOGS FOUND`) — suspiciously the one place that *should* have content.

### A live injection point

Entering a non-directory name in the path box pops:

```
https://r-<hash>.cg.chal.sh
[SECURITY ERROR] Unexpected non-whitespace character after JSON at position 4
```

— the `Subdirectory` parameter is fed into a JSON parser. That is a controllable injection point.

### DEPLOY CONSOLE

```
Enterprise Log Deployment Utility
1. Create Log
2. View Log
3. Edit Log Content
4. Delete Log
5. Exit
```

- connected (`[CONNECT]`)
- `View Log` for slots 0–7 is empty (`Invalid index or log does not exist`)
- inference: `Create Log` must run first; `Create`/`Edit` may be a **file-write primitive**

## 4. Upcoming events · Quick.Cms

From CEF's `History` sqlite (unencrypted, readable):

```
https://cms-<hash>.cgo.chal.sh/
  title: "Quick.Cms - fast and simple content management system"
https://cms-<hash>/open#<ticket>
  title: "Opening game"
```

Fingerprint is unambiguous: **Quick.Cms**.

### Verified

| Item | Result |
|---|---|
| `/` | 401 |
| `/open` | 200, bootstrap page |
| replay historical ticket | 403 (consumed) |
| LSB of the two cached PNGs | pure noise, no stego |
| PNG container layers (trailer / text chunks) | clean |
| QR in `f_000002` | ✅ `https://www.youtube.com/channel/UC7FudH8K64SQn--gGBYmG9g` |

Two posters:

- `f_000002` = "SUBSCRIBE FOR INTEL" YouTube poster (with QR)
- `f_000003` = "UPCOMING EVENTS" bulletin (the one visible in-game)

### Blocker: Cookies are exclusively locked

```
%TEMP%\401Unauthorized\webview\<id>\cache\Default\Network\Cookies
```

CEF holds the file exclusively; `FileShare.ReadWrite` cannot open it, and `esentutl /y` needs
`SeBackupPrivilege` (unavailable without admin).

**Known workable unlock** (not executed): leave the room (close the webview / return to lobby / quit
the game), then copy the file immediately and read the `cookies` table with sqlite. If it is v10
encrypted, DPAPI plus the `Local State` key is required.

## 5. Photo kiosk · social achievement

```
Photo kiosk
  → Pick a picture (HKCERT / Black Bauhinia / VXRL)
  → Warm / Cool / Frame
  → QR: https://unauthorized.cg.chal.sh   #401Unauthorized
  → "Share a public X post with the hashtag"
  → [Check my post]
```

The flow is explicit: **publish a public X post with `#401Unauthorized`**, then let the server verify.
This requires a human with an X account; it cannot be automated.

## 6. Reusable recon checklist for webview rooms

Ordered by return on effort:

```
1. History            ← unencrypted; sqlite it, list every URL/title ever visited
2. Preferences        ← hosts, UA, settings
3. Local Storage      ← frontend state (React's localStorage lives here)
4. Network\Cookies    ← exclusively locked; copy after leaving the room
5. Service Worker / Cache Storage ← static assets, possibly older API versions
6. Page source for /open, /_webview/signin, status_path
```

`History` is the highest-value single artifact — it frequently exposes admin panels, upload
endpoints, hidden paths, and **complete URLs carrying tickets**.

## 7. Retrospective

| Attempt | Outcome |
|---|---|
| hit `/` directly | 401; auth is a hard gate |
| replay ticket | one-shot, 403 |
| poster stego | clean (LSB and container layers) |
| QR | a real find (YouTube channel), but the host cannot reach YouTube |
| Cookies | exclusively locked — the biggest technical blocker of the event |

### If we did it again

1. **Leave the room, then copy Cookies** — the known-viable path should have been tried within ten
   minutes of hitting the 401
2. With a session, standard Quick.Cms hits: `/admin.php` default credentials, known CVEs
   (file upload / LFI)
3. The dev log's `PATCH /api/v1/user/preferences` + JWT middleware is a separate privilege-escalation line
4. Revisit the YouTube channel `UC7FudH8K64SQn--gGBYmG9g` from a host with internet access
