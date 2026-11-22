# 工具链 · Windows GUI 与 CEF 自动化

> 这一节是整场比赛沉淀下来最可复用的部分。

## 0. 为什么需要它

这是一个 **Unity 客户端 + 内嵌 CEF（UnityWebBrowser）** 的混合体：

- 游戏本体是 Unity（像素风 2D）
- 每个"设施"打开一个 CEF webview 房间
- 大量成就要在 webview 里完成（输入框、按钮、拖拽）

官方没有 API，只能从外部做 GUI 自动化。

## 1. 截图

```powershell
capture.ps1 -Out shot.png
# WIN pid=... hwnd=... size=3222x1856 fg=True
# PRINTWINDOW=True SAVED=shot.png
```

用 `PrintWindow`，即使窗口被遮挡也能截到内容。

**关键坑**：窗口物理尺寸 `3222×1856`，但非 DPI 感知进程拿到的是 `2148×1237`（1.5 倍差）。
所有坐标必须以**物理像素**为准，脚本第一行就要 `SetProcessDPIAware()`。

## 2. 鼠标

```powershell
click.ps1 -X 1611 -Y 1056 -Mode click|dbl|click2|move
```

坐标是**相对窗口左上角**的物理像素，脚本内部每次都重新 `GetWindowRect`。

三条经验：

1. **窗口会漂**：本次会话里从 `(787,23)` 漂到 `(531,125)`，硬编码绝对坐标必错
2. **第一次点击经常只用来聚焦**，需要连点两次（`-Mode click2`，间隔 420 ms，
   刚好避开双击判定阈值）
3. **hover 有用**：部分按钮需要 `mouseover` 才"武装"，脚本里先 `SetCursorPos` 再等 220 ms

## 3. 键盘

```powershell
keys.ps1 -Seq "W:500,A:300,E:150"
```

`键:按住毫秒`，支持 ESC/WASD/TAB/ENTER/方向键/字母/数字。

**焦点**：`SetForegroundWindow` 单独调用经常失败，必须用 `AttachThreadInput`
把当前线程挂到前台窗口的输入队列上：

```csharp
AttachThreadInput(curThread, fgThread, true);
BringWindowToTop(hwnd);
SetForegroundWindow(hwnd);
```

## 4. 文本输入（最大的坑）

前后写了 5 个版本，只有最后一个能用：

| 脚本 | 方式 | 结果 |
|---|---|---|
| `type.ps1` / `input.ps1` | 点击 + Ctrl+A + Delete + SendKeys | ❌ Ctrl+A/Delete 在 CEF 无效 |
| `type2.ps1` | `SendKeys` | ❌ 完全进不去 CEF |
| `type3.ps1` | `SendInput` + `KEYEVENTF_UNICODE` | ❌ `SendInput` 返回 0 |
| `type4.ps1` | `keybd_event` + `KEYEVENTF_UNICODE` | ❌ 调用成功，字符不进 |
| **`type6.ps1`** | `keybd_event` + VK + **`MapVirtualKey` scan code** | ✅ 成功 |

### 核心代码

```csharp
[DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
[DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint mapType);

byte sc = (byte)MapVirtualKey(vk, 0);
keybd_event(vk, sc, 0, UIntPtr.Zero);      // down
keybd_event(vk, sc, 0x0002, UIntPtr.Zero); // up
```

**没有 scan code 的合成按键，CEF 会直接丢弃**，但函数返回成功 —— 最坑的一类失败。

### 字符映射

需要自己处理 Shift：

```powershell
# 字母 / 数字 / 空格 / 句点 / 逗号 / 冒号（shift + 0xBA）/ 引号 / 问号 ...
```

### 频率

CEF 里很多输入框**每渲染帧只处理一次击键**（见 Typeway 2000）。
安全节奏是 **40–50 ms/字符**（高于 33 ms 一帧）。

## 5. CEF 取证

| 脚本 | 作用 |
|---|---|
| `cef.py` | 遍历 webview 临时目录，导出 `History` |
| `cookies.py` | 读 `Network\Cookies`（v10 DPAPI 解密） |
| `cefcookie.py` | 简化版 cookie 提取 |

### 定位 webview 目录

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -match 'user-data-dir' } |
  Select-Object ProcessId, Name, CommandLine
```

从 `UnityWebBrowser.Engine.Cef.exe` 的命令行里能直接看到：

```
--user-data-dir="C:\Users\<user>\AppData\Local\Temp\401Unauthorized\webview\<id>\cache"
```

### 读 History

```python
import sqlite3
con = sqlite3.connect(history_copy)
for url, title, visits in con.execute(
        "SELECT url, title, visit_count FROM urls ORDER BY last_visit_time DESC"):
    print(visits, "|", title, "|", url)
```

`History` **未加密**，是最有价值的侦察目标；
`Network\Cookies` 被 CEF 独占锁，需要先退出房间再复制。

## 6. 隐写排查

```powershell
stego.py -f poster.png
```

覆盖：

- PNG 容器层：chunk 遍历、尾部数据、`tEXt` / `zTXt`
- LSB：bit 平面（**渲染成图**，不是拼字节）
- 二维码解码（`zxing-cpp`）

## 7. HTTP

PowerShell 5.1 的 TLS 栈在这台机器上是坏的（`SEC_E_NO_CREDENTIALS`），
所有请求改用 Node：

```powershell
node probe.mjs -url https://target -paths /open,/session,/
node getroom.cjs <url> out.html
```

## 8. PowerShell 的若干坑

| 坑 | 表现 | 解法 |
|---|---|---|
| 执行策略 | 脚本无法运行 | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File` |
| 中文路径被 GBK 化 | `实战` → `瀹炴垬` | 输出路径全用 ASCII |
| `"$i:"` 被当成盘符 | 数组索引报错 | 写 `${i}:` |
| `node -e` 带引号/正则 | 参数被 PowerShell 吃掉 | 写成 `.mjs` / `.cjs` 文件 |
| `mouse_event` 的负 delta | `uint` 强转失败 | 用 `[uint32]4294967176`（2³²−120） |

## 9. 文件清单

| 脚本 | 作用 |
|---|---|
| `capture.ps1` | PrintWindow 截图 + 窗口信息 |
| `click.ps1` | DPI 感知点击（click / dbl / click2 / move） |
| `keys.ps1` | 键盘序列注入（含抢焦点） |
| `type6.ps1` | **VK + scan code 文本注入**（唯一可用版本） |
| `cef.py` / `cookies.py` / `cefcookie.py` | CEF 缓存 / Cookie 取证 |
| `stego.py` | PNG 容器 + LSB 排查 |
| `poster.py` | 海报裁剪 + 增强变体 |
| `probe.mjs` | HTTP 探测 |
| `getroom.cjs` | 拉取房间页面 |
| `inject.mjs` | ticket 注入测试 |
| `yt.mjs` | YouTube 频道抓取 |

## 10. 通用建议

1. **写入前先做回显验证**：输入 → 截图 → 比对，不要盲发
2. **坐标不要硬编码**，每次都从窗口矩形推导
3. **合成输入失败有三种**：API 返回失败、API 返回成功但被丢弃、进去了但被 frame gate 丢弃
   —— 只有第一种会报错，后两种必须靠回显发现
4. **临时目录是宝藏**：`%TEMP%\<AppName>\webview\<id>\cache\Default\`
   里躺着 History / Preferences / Local Storage / Cookies
