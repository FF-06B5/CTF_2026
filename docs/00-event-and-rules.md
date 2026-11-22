# 赛事、规则与作战环境

> 本文汇总两件事：**这场比赛到底是什么赛制**，以及**我们是在什么条件下打的**。
> 后者决定了后面所有技术选择的合理性。

## 1. 赛事概况

| 项 | 内容 |
|---|---|
| 名称 | HKCERT CTF 2026 · 预选赛（Qualifier） |
| 时间 | 2026-11-06 18:00 → 2026-11-07 18:00（HKT，24 小时线上） |
| 形式 | 非传统 Jeopardy，而是一款 Unity 游戏客户端 `401Unauthorized` |
| 题目分类 | Binary Exploitation / Cryptography / Forensics / Reverse / Web / Misc |
| 计分 | **成就（动态分值）**，不是 flag 数量 |
| flag 格式 | `hkcert26{[a-z0-9_]+}` |

赛制说明（来自 `ctf.hkcert.org` 的 Contest Format / Important Dates）：

- 24 小时不间断；
- 选手在游戏世界里探索、找线索、完成任务；
- 晋级复审要求提交 **3 道题**的 writeup。

## 2. 规则要点（摘自 `platform.ctf.hkcert.org/rules`）

### 授权范围

- ✅ `*.chal.sh` **任意层级子域**及其解析到的主机/服务
- ✅ 赛方明确提供的其他资源
- ❌ `pwnable.hk`、`hkcert.org`（主站，非 `chal.sh`）
- ❌ 官方 Discord / 支持渠道
- ❌ 比赛平台本身（`platform.ctf.hkcert.org`）

### 禁止事项

- DoS / 泛洪 / 任何形式的资源耗尽攻击
- 攻击比赛平台
- 社工（对赛方人员、其他选手）
- 向队外分享 flag / 账号 / 解法；赛前泄露题目内容

### 关于 AI

规则明确**允许使用 AI 工具**，但有一条硬要求：

> 晋级复审的 writeup 必须写清**分析过程与人工验证**，不能只贴 prompt 或最终答案。

这一条直接决定了本文的组织方式 —— 见 [§7 诚实性声明](#7-诚实性声明与-ai-使用说明)。

### 队伍

每队最多 4 人。

## 3. 规则页的抓取（第一个小技巧）

`https://platform.ctf.hkcert.org/rules` 是个 **Vite SPA**，正文不在 HTML 里，
而是内嵌在 `assets/index-*.js` 的打包产物中。

做法（Node `fetch`）：

```js
// 1. 抓首页 HTML，取出 <script src=".../assets/index-*.js">
// 2. 下载 bundle，正则定位规则片段
const m = js.match(/hkcert26\{[\s\S]*?var ug=F\(/);
// 3. 从片段里提取三份 markdown 原文
//    en / zh-Hant / zh-Hans
```

拿到三语原文后，规则就完全可检索了。

> 这类"SPA 把内容打进 bundle"的站点，`Ctrl+U` 看不到东西是正常的，
> 应该直接去 `assets/*.js` 里找。

## 4. 作战环境

| 项 | 值 |
|---|---|
| OS | Windows 10/11 |
| Shell | PowerShell 5.1 |
| Python | 3.11.9（自带 `cryptography` / `numpy` / `Pillow`） |
| 缺失工具 | 7z、Ghidra、IDA、Wireshark、Docker |

### 踩坑 1：TLS 栈是坏的

本机 `curl.exe` 与 PowerShell 的 SChannel 都报：

```
SEC_E_NO_CREDENTIALS
基础连接已经关闭
```

所有 HTTPS 请求改用：

- Node 的 `fetch`（`probe.mjs` / `getroom.cjs` / `yt.mjs`）
- 或 Python 的 `urllib`

### 踩坑 2：没有压缩工具

压缩包用 Python 的 `zipfile` / `gzip` 处理；
磁盘镜像自己写最小 NTFS 解析器（`_read/ntfs_*.txt` 就是它的产物）。

### 踩坑 3：没有 OCR 库

楔形文字的切分 + 聚类**只用 Pillow + numpy**，没装 Tesseract / PaddleOCR。

## 5. 兑换机制（客户端证据）

这是本场比赛最容易搞错的一点：**flag 不是网页提交**。

### 本地化文案

```
Mervyn: 兌換代碼讓你輸入代碼，領取對應獎勵。
每個 hkcert26{...} 代碼：到「兌換代碼」視窗兌換
兌換代碼 / 輸入代碼 / 兌換
代碼已兌換：{0}。
此代碼已兌換過。
```

### 代码证据

`CTFGame.UI.dll` 的字符串表里有：

```
RedeemWindow    RedeemCode    OpenRedeem    redeemButton
```

网络层有：

```
AchievementClientServiceSubmitFlagRequest
AchievementClientServiceSubmitFlagResponse
```

响应字段：

```
outcome            // 兑换结果
achievement_id     // 兑换成功时返回的成就 id
text               // 展示给玩家的文案
```

### 结论

```
找到 flag  →  「兌換代碼」窗口  →  POST 提交  →  返回 achievement_id  →  成就到账
```

**flag → 成就的映射在服务端**，客户端拿不到，所以本地无法离线验证。

## 6. 成就系统的观测

### `Player.log` 里能看到的解锁

```
gits_case_opened
up_up_down_down
vault_first_win
first_dungeon_entry
quest_beginner
```

（对应：开案 / 老秘技依然有效 / 全身而退? / 首次进地牢 / 新手任务）

### 客户端只收事件

成就判定在服务端，客户端只接收 `AchievementEarnedEvent`。

### 总数被隐藏

成就页显示 **「已解锁 3/???」**，分母是隐藏的 —— 我们靠截图拼出了 42 条，
但无法确认是否完整。

## 7. 时间线（三个会话的合并）

| 时间 | 事件 |
|---|---|
| 18:03 | 读规则（SPA bundle 提取） |
| 18:10 | 建工作区、环境准备 |
| 18:20–19:10 | 泥板截图 OCR 路线（未走通，但确认了"单表替换"） |
| **19:20** | **发现 `StreamingAssets` 明文，两题直接破** |
| 19:30–19:50 | GhostDisk 四条 flag |
| 20:00+ | 游戏内成就线：AI 法庭 / FinSim / 游戏中心 |
| 20:40 | AI Judge 通过（`Achievement unlocked.`） |
| 21:00+ | Typeway 2000 机制打穿（245 WPM） |
| 22:00+ | Web 面侦察（Quick.Cms / dev-log-viewer），会话卡在 Cookies 独占锁 |

## 8. 三条硬约束（贯穿全文）

1. **授权边界只有 `*.chal.sh`** —— 所有请求都没出这个范围
2. **AI 可以用，但过程必须可复现** —— 本文每个结论都带命令或脚本
3. **flag 只在队内** —— 发布前按 [附录 E](#附录-e-发布前脱敏) 做脱敏
