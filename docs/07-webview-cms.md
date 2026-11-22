# Webview 房间 · CEF 取证与 CMS 认证

> 地点: 员工工具 → 开发日志检视器 / 活动预告 → CMS
> 状态: 侦察完成，会话未拿到

## 1. 房间架构

每个设施背后是一个 webview 房间，域名是随机的：

```
auth            https://auth.cg.chal.sh/
room websocket  wss://r-<hash>.cg.chal.sh/room
webview 入口    https://r-<hash>.cg.chal.sh/_webview/signin
```

全部在 `cg.chal.sh` / `cgo.chal.sh` 下（赛事授权范围内）。

从 CEF 的 `History` 里能读到具体房间：

```
https://game.cgo.chal.sh/s/<room-hash>/<session-hash>/
https://game.cgo.chal.sh/open#<43 字符 ticket>
https://cms-<hash>.cgo.chal.sh/
```

## 2. 会话模型

从 `/open` 的前端 JS 逆出来：

```js
ticket = location.hash.slice(1)            // 43 字符 [A-Za-z0-9_-]
POST /session {"ticket": ticket}           // credentials: same-origin
  -> { path: "/",
       status_path: "/_office/visit/status",
       state: "ready" | "preparing" }
  -> Set-Cookie 会话
GET /                                      // 需要该 Cookie，否则 401
```

验证结果：

| 操作 | 结果 |
|---|---|
| `GET /` 无 Cookie | `401: Unauthorized`（aiohttp） |
| `GET /open` | `200`，引导页（公开） |
| 重放历史 ticket | `403: Forbidden`（一次性、已消费） |

`WWW-Authenticate: Bearer` —— 需要 token，token 走 OAuth
（`refresh_token` / `access_token` / `RefreshAccessToken`）。

## 3. 开发日志检视器

入口：大厅按 `E` → 員工工具 → 開發日誌檢視器。

```
LOG_ROOT/
  code-review    11/5 20:43:11
  deployment     11/5 20:43:11
  development    11/5 20:36:25   ← 时间戳不同
  incident       11/5 20:43:11
  retrospective  11/5 20:43:11
  testing        11/5 20:43:11
```

操作要点：目录行是**双击**进入，不是 `QUERY`。

### 泄露的日志

`development/log.md`（1.75 KB）：

> Alex Morgan / **CloudSync Dashboard**
> - 深色模式切换（跟随系统）
> - 后端：`PATCH /api/v1/user/preferences` → PostgreSQL，**JWT 校验中间件**
> - 前端：Tailwind + React，状态存 `localStorage`
> - Next.js hydration mismatch → useEffect + 默认值

攻击面：越权/IDOR、JWT 算法混淆或弱密钥、SQLi、XSS。

`incident/` 为空（`NO LOGS FOUND`）—— 但恰好是"该有东西却没有"的位置。

### 活的注入点

目录框输入非目录名后弹窗：

```
https://r-<hash>.cg.chal.sh
[SECURITY ERROR] Unexpected non-whitespace character after JSON at position 4
```

—— `Subdirectory` 参数**被送进 JSON 解析**，是可控的注入点。

### DEPLOY CONSOLE

```
Enterprise Log Deployment Utility
1. Create Log
2. View Log
3. Edit Log Content
4. Delete Log
5. Exit
```

- 已连上（`[CONNECT]`）
- `View Log` 槽位 0–7 全空（`Invalid index or log does not exist`）
- 推断：先 `Create Log` 才有内容；`Create` / `Edit` 可能是**文件写原语**

## 4. 活动预告 · Quick.Cms

从 CEF 的 `History` sqlite（未加密，直接可读）挖到：

```
https://cms-<hash>.cgo.chal.sh/
  标题: "Quick.Cms - fast and simple content management system"
https://cms-<hash>/open#<ticket>
  标题: "Opening game"
```

指纹明确：**Quick.Cms**。

### 已验证

| 项 | 结果 |
|---|---|
| `/` | 401 |
| `/open` | 200，引导页 |
| 重放历史 ticket | 403（已消费） |
| 缓存里两张 PNG 的 LSB | 纯噪点，无隐写 |
| PNG 容器层（尾部 / 文本块） | 干净 |
| `f_000002` 的二维码 | ✅ `https://www.youtube.com/channel/UC7FudH8K64SQn--gGBYmG9g` |

两张海报：

- `f_000002` = "SUBSCRIBE FOR INTEL" YouTube 订阅海报（含二维码）
- `f_000003` = "UPCOMING EVENTS" 行动公报（游戏里能看到的那张）

### 卡点：Cookies 被独占锁

```
%TEMP%\401Unauthorized\webview\<id>\cache\Default\Network\Cookies
```

CEF 以独占方式持有该文件，`FileShare.ReadWrite` 也打不开；
`esentutl /y` 需要 `SeBackupPrivilege`（非管理员不可用）。

**已知可行的解锁方式**（未执行）：让游戏离开该房间（关 webview / 退出大厅 / 关游戏）
后立刻复制该文件，再用 sqlite 读 `cookies` 表。
若是 v10 加密，需要 DPAPI + `Local State` 里的 key。

## 5. 照相亭 · 社交成就

```
Photo kiosk
  → Pick a picture（HKCERT / Black Bauhinia / VXRL）
  → Warm / Cool / Frame
  → QR: https://unauthorized.cg.chal.sh   #401Unauthorized
  → "Share a public X post with the hashtag"
  → [Check my post]
```

流程很清楚：**在 X 上公开发一条带 `#401Unauthorized` 的帖子**，
点 `Check my post` 让服务器验证。这条必须真人操作（需要 X 账号），自动化做不了。

## 6. 可复用的侦察清单

webview 房间的固定动作（按性价比）：

```
1. History            ← 未加密，直接 sqlite 读，能列出所有访问过的 URL / 标题
2. Preferences        ← 域名、UA、设置
3. Local Storage      ← 前端状态（React 的 localStorage 就在这里）
4. Network\Cookies    ← 被独占锁，需要"先退出房间再复制"
5. Service Worker / Cache Storage ← 静态资源、可能的旧版本 API
6. 页面源码里的 /open、/_webview/signin、status_path
```

`History` 是最高性价比的一个 —— 它经常直接暴露：
后端管理面板、上传接口、被隐藏的路径、以及**带 ticket 的完整 URL**。

## 7. 复盘

| 尝试 | 结论 |
|---|---|
| 直接打 `/` | 401，认证是硬门 |
| 重放 ticket | 一次性，403 |
| 海报隐写 | 干净（LSB / 容器层都试了） |
| 二维码 | 有收获（YouTube 频道），但本机网络到 YouTube 超时 |
| Cookies | 被独占锁，是本次最大的技术卡点 |

### 如果重来

1. **先退出房间再复制 Cookies**，这是已知可行的路径，应该在发现 401 的 10 分钟内就做
2. 拿到会话后，Quick.Cms 的标准打点：`/admin.php` 默认口令、已知 CVE（文件上传 / LFI）
3. 开发日志的 `PATCH /api/v1/user/preferences` + JWT 中间件是一条独立的越权线
4. YouTube 频道 `UC7FudH8K64SQn--gGBYmG9g` 值得用能通外网的环境再看一次
