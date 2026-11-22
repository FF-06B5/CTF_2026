# FinSim · 一个完整的经济模拟

> 地点: 大厅 · FinSim 终端
> 结论: 机制完整、校验到位，靠单个漏洞打不穿；`Discover` 门槛极高

## 1. 界面结构

```
FinSim — National Agriculture Ventures

1000.00 CR   ⚡ 80/100   8 actions   Day 1 / 30   [Next day 🌙]
```

底部 11 个页签：

| 页签 | 内容 |
|---|---|
| **Build** | 建造面板 |
| **Market** | 水果买卖（动态定价）+ 果汁台 |
| **Bag** | 背包：水果库存、瓶子、拍照、卖出 |
| **Deliver** | 交付合约 + 竞价 |
| **Trade** | 币圈交易所（ORNG / APPL / CHIV / BITE） |
| **Invoices** | 开票 |
| **Orders** | 订单（未深入） |
| **Album** | 相册 |
| **Wallet** | 流水账 |
| **News** | 市场新闻 |
| **Discover** | 三张未解锁卡 |

## 2. 建造

| 设施 | 价格 | 效果 |
|---|---|---|
| Orange orchard | 40.00 CR | +30 存储 · 🍊 收成 |
| Apple orchard | 40.00 CR | +30 存储 · 🍎 收成 |
| Juice factory | 30.00 CR | +30 存储 · 榨汁 |
| Delivery truck | 20.00 CR | 解锁 delivery bids |
| Warehouse | 25.00 CR | +50 水果存储 |

果汁工坊：`2 水果 + 0.80 CR → 1 瓶`。

## 3. 跑通的完整循环

```
建造(115 CR) → 买 20 个橙子(27.60 CR) → 榨 5 瓶(4.00 CR)
→ 批量卖出(33.50 CR) → 接单竞价 → 派车 → 开票收款
```

实测数据：

| 步骤 | 结果 |
|---|---|
| Build 4 项 | `1000.00 → 885.00 CR`，storage `0/120` |
| Market 买 20 橙 | `857.40 CR`，storage `20/120`，橙子参考价 `1.00 → 1.80` |
| 榨 5 瓶 | `853.40 CR`，橙子 `20 → 10` |
| 批量卖 5 瓶 | `+33.50 CR`（9 CR × 80% − 0.50/瓶手续费） |

## 4. 交付与竞价

```
CWE delivery                [open]   Day 2
Place bid for service charge
Bid from Swift Freight: 9.95 CR
```

- 合约名 **`CWE delivery`** —— CWE = Common Weakness Enumeration，明示漏洞类型
- 对手 **Swift Freight** 报价会浮动（见过 8.73 / 9.95）
- 我们报 **1.00 CR** 赢了（最低价中标）
- 派车后生成合约 `CWE-3482`，状态 `Awaiting truck` → 派车 → `paid`

## 5. 开票：三个边界都试过了

开票表单：`Contract reference` / `Amount CR` / `Description`。

| 尝试 | 结果 | 说明 |
|---|---|---|
| 空合约号 | `Please fill out this field.` | 客户端必填校验 |
| `-10` | `Value must be greater than or equal to 0.01.` | 浏览器 `min` 校验 |
| `99999` | `rejected: invalid amount` | **服务端有金额上限** |
| `1.00`（合约额） | ✅ `paid` | 正常路径 |
| 同合约再开 `1.00` | `rejected: no open obligation` | **防重放有效** |
| 同合约开 `9.00` | `rejected: no open obligation` | 合约已关闭 |

结论：

- 金额不能造（服务端校验）
- 次数不能造（obligation 一次性）
- 负数被客户端挡，且由于服务端返回的是 `invalid amount` 而不是"已关闭"，
  说明服务端**先查 obligation 再查金额**，绕过顺序也堵死了

## 6. 卖出：需求区间

Bag 页每瓶果汁都有独立售价框：

```
Orange juice · Use by day 7 · ITEM-0001
[📷 Photo]  [Drink · 20]  Sell: [9] [Sell]   (0.50 CR selling fee)
```

填 `999999` 卖：

```
Consumer demand supports 1–9 CR today
```

每天的需求区间不同（今天是 1–9），这是**设计好的动态系统**，不是漏洞。

批量卖出规则写在按钮下面：

> Bulk sale: 20% below individual maximum, then 0.50 CR fee per bottle.

## 7. 币圈（Trade）

```
ORNG  OrangeCoin   16.40 CR   5 held
APPL  AppleCoin     9.89 CR   0 held
CHIV  ChiveCoin    10.05 CR   0 held
BITE  BiteCoin      9.83 CR
```

带 Buy / Sell 两个方向，价格随天数波动 —— 是投机/套利玩法，不是印钞机。

## 8. Discover：三张锁

```
🔒 Undiscovered — Keep exploring the economy.   ×3
```

跑完整循环（建造 → 买 → 加工 → 拍照 → 卖 → 接单 → 开票）+ 补齐全部 5 种设施，
**一张都没开**。

判断：解锁条件远高于"正常玩一遍"，可能是 30 天全通 / 上万 CR / 特定稀有事件。

## 9. 复盘

这个子系统是**完整实现**的：

- 服务端校验金额上限 ✔
- 一次性 obligation 防重放 ✔
- 动态需求区间 ✔
- 存储上限 + 每日持有成本 ✔

它更像一个"真实的小游戏"，而不是一个待打的漏洞靶。
在 24 小时赛制里，投入产出比很低。

### 唯一的收获

`CWE delivery` 这个命名 + "竞价"机制，提示的是**逻辑漏洞**方向
（price manipulation / 重复结算 / 越权访问他人合约），
而不是注入或溢出。我们验证了其中两条（金额、重放）都被堵住，
剩下 **合约号越权（IDOR）** 没来得及试：

合约号是**顺序编号**（`CWE-3482`），
如果能用别人的合约号开票，就是典型的 `CWE-639`。
