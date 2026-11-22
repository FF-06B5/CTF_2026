# 游戏中心 · Typeway 2000 与反作弊

> 成就: `非人手速` — 在游戏中心的 Typeway 2000 赢得一场比赛
> 地点: 游戏中心（活动街机 / 弹珠台 / 节奏游戏 / 四风麻将）

## 1. 四台机器

| 机器 | 状态 | 说明 |
|---|---|---|
| **弹珠台** Space Cadet Pinball | 可玩 | 三个成就：`First game +10,000` / `Bank clear +75,000` / `Lane master +50,000` |
| **四风麻将** Four Winds | 可玩 | 立直麻将东风战，3 bot，25000 起分，东 1-4 |
| **Typeway 2000** | **机制打穿** | 打字竞速，本文重点 |
| **节奏游戏** | ❌ 坏的 | 卡在 `Loading... 33%`，资源加载失败 |

### 弹珠台

```
ACHIEVEMENTS
  ★ First game   +10,000    ← 已点亮
    Bank clear   +75,000
    Lane master  +50,000
```

操作：`Z/←` 左挡板、`M/→` 右挡板、`Space` 蓄力发射、`N/↑` 撞机（会 tilt）。

计分：任务各付一次；**gated ring 内的 orbit pump 每次 1,300 分**。

排行榜（说明这机器能刷很高；**玩家名已匿名化**）：

```
PLAYER_1   42,267,200
PLAYER_2   41,464,600
PLAYER_3   37,597,300
PLAYER_4   36,190,300
PLAYER_5   20,092,800
```

### 四风麻将

```
FOUR WINDS · 四風連鎖 · JAPANESE RIICHI MAHJONG
Start a match — Bot difficulty: Low / Medium / Hard / Extreme
東風戦 · EAST 1-4 · Starting points 25,000 · 3 bots
```

规则面板写得很完整（立直 / ツモ / ロン / 役），是正经实现，不是占位。

---

## 2. Typeway 2000（重点）

### 2.1 界面

```
typeway 2000 — PERSONAL TYPING WORKSTATION
LOCAL SESSION · PLAYER_01 · v1.0 / RETRO EDITION

SPEED 0 WPM | ACCURACY 100% | TIME LEFT 02:00 | PERSONAL BEST — WPM

01 RACE MONITOR   THE LOCAL LOOP / 3 LANES   — 120 SECOND RACE
  YOU      PLAYER_01     —
  BYTE     110.5 WPM     ← 对手
  DOT.EXE   80 WPM       ← 对手

02 TEXT BUFFER   STANDARD / 219 WORDS
  [文章]                    0 / 1145 CHARS

Race setup:
  One shuffled standard passage. Two rivals.
  Finish exactly or race for up to 120 seconds.
  [Start race]  ← The clock starts with your first keystroke.
```

### 2.2 三重反作弊

| 防护 | 表现 | 我们的尝试 |
|---|---|---|
| `user-select: none` | 鼠标选不中文章 | 手动复制失败 |
| 粘贴无效 | `Ctrl+V` 无反应 | 用 PowerShell `Set-Clipboard` 写入后粘贴，输入框纹丝不动 |
| **每帧只收一次击键** | 6 ms/字符注入 224 个字符，只进去 1 个 | 见下 |

第三条最关键。界面原文：

```
One keystroke at a time.
```

我以 **6 ms/字符** 注入 224 个字符：

```
VK_SENT=224  CHARS=224
输入框结果：1 个字符
```

—— 说明它按渲染帧（~30 fps）取一次键盘事件，其余全部丢弃。

### 2.3 成功的关键：scan code

尝试了四种注入方式：

| 方式 | 结果 |
|---|---|
| `SendKeys`（`type2.ps1`） | 完全进不去 |
| `SendInput` + `KEYEVENTF_UNICODE`（`type3.ps1`） | `SendInput` 返回 0（被拒） |
| `keybd_event` + `KEYEVENTF_UNICODE`（`type4.ps1`） | 调用成功但字符没进去 |
| **`keybd_event` + VK + `MapVirtualKey` scan code**（`type6.ps1`） | ✅ **成功** |

核心就一行差别：

```csharp
byte sc = (byte)MapVirtualKey(vk, 0);
keybd_event(vk, sc, 0, UIntPtr.Zero);      // down
keybd_event(vk, sc, KEYUP, UIntPtr.Zero);  // up
```

**没有 scan code 的合成按键，CEF 直接丢弃。**

### 2.4 成绩

42 ms/字符的节奏（略高于一帧）：

```
SPEED      245 WPM      ← 人手 2~3 倍
ACCURACY   98 %         （4 处错误：大小写 / 冒号）
MATCHED    223 / 1150
你领先      YOU 19%  vs  BYTE 9%  vs  DOT.EXE 6%
```

**245 WPM 就是"非人手速"本速。**

### 2.5 为什么还是输了

两个原因：

1. **最终分是全程平均**
   只打了 19%，结算被拉成 `22 WPM`（`PERSONAL BEST 22`）。
   BYTE 打满 100%（110.5 WPM）赢了。
2. **打不完全文**
   `TEXT BUFFER` 是只有 3 行高的固定视窗：
   - 滚轮滚的是**外层页面**（会跑到 User Guide）
   - 滚动条拖不动
   - 输入框覆盖了第 4 行

   **1145 字符只能看到开头 ~250**，读不到的就没法注入。

### 2.6 通关条件（推算）

| 指标 | 数值 |
|---|---|
| 文章长度 | 1140 ~ 1150 字符（208 ~ 219 词） |
| 限时 | 120 s |
| BYTE 速度 | 110.5 WPM → 约 552 字符/分钟 → 1145 字符需 ~124 s |
| 我们需要 | 在 120 s 内打完 1145 字符 |

以 20 字符/秒（50 ms/字符，安全高于一帧）计算：
**1145 字符 ≈ 57 秒**，最终 WPM ≈ **240** —— 完全够用。

所以唯一的门槛就是：**把文章完整读出来**。

### 2.7 可能的解法（未验证）

1. **最大化窗口 / 提高分辨率**，让 `TEXT BUFFER` 一次显示更多行
2. **从服务端拿原文**
   房间页面在 `https://game.cgo.chal.sh/s/<room>/<session>/`，
   需要会话 Cookie（CEF 独占锁）
3. **改 CSS**（如果有 devtools —— 没有）

---

## 3. 复盘

| 学到 | 内容 |
|---|---|
| 合成按键必须带 scan code | 这是 CEF 和普通 Win32 控件的最大区别，`MapVirtualKey` 一行解决 |
| 反作弊看的是"帧" | 每秒 30 帧 = 每秒最多 30 个可识别击键，注入再快也是浪费 |
| 判定口径要先确认 | 瞬时 WPM 和全程平均 WPM 是两个指标，我们按前者优化输了后者 |
| 可读性是硬约束 | 文本只在 3 行视窗里，读不全就打不完 —— 这是设计上的"物理"限制 |

这类"游戏内成就"的通用思路：

1. 先看**成就条件原文**（很直白：`Non-human speed`）
2. 找**机制层面的捷径**（复制粘贴 / 脚本注入），而不是练手速
3. 每一层防护都要单独验证（选中 → 粘贴 → 注入 → 频率）
