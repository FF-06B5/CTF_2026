# 未译泥板 · 单表替换密码

> Flag: `hkcert26{REDACTED}`
> 类别: Misc / Crypto

## 1. 题面

游戏里给出一块泥板，上面是楔形文字（Unicode `U+12000`–`U+123FF`）。
第一行格式看起来像 flag，后面是正文。

## 2. 判断：这是替换密码，不是象形文字

真正的象形文字是「一符号一词/一音节」，不会出现稳定的一一映射。三条证据否定前者：

| 证据 | 数据 |
|---|---|
| 最高频三字母词 `bda` 全文出现 **41 次**，恒对应 `the` | 频率分析成立 |
| `chi` 恒对应 `and`，`be` 恒对应 `to` | 映射稳定 |
| 符号总数约 **26** 个 | 正好一个英文字母表 |

按初步替换解出的第一句：

```
the traders came down from the high country before dawn
```

通顺英文 → 确认单表替换（26 自造符号 ↔ 26 英文字母，数字与 `{}_-` 原样保留）。

## 3. 截图路线的失败

flag 行在截图里的字距只有 **3–5 px**，相邻字形粘连：

- `j u g s` 会被切成 5 个字形
- `m` / `y` 会被并成一个

用连通域 + 聚类做的切分（`pipeline.py` / `cluster2.py`）在正文上能收敛，
在 flag 行上必然出错。

**当时的最好成绩**是猜出 `hkcert26{REDACTED}`，
中间那段 `jugs` 错了。

### 3.1 OCR 流水线（失败记录，但方法可复用）

没有用任何 OCR 库，纯 Pillow + numpy 手搓：

1. **预处理**：灰度化 → 阈值二值化
2. **切行**：水平投影，按谷值切
3. **切字**：垂直投影，合并间距 `< 8 px` 的碎片
4. **特征**：每个字形裁剪后归一化到 **24×24 灰度**，去均值、单位化
5. **聚类**：L2 距离 + 并查集单链聚类，阈值 **0.55** → 得到 **39–45 个簇**
6. **标注**：人工对照 `key_sheet.png` 标出约 **20 个字母**

正文能解出来（因为字形有上下文、可以纠错），但 **flag 行解不出来**：

- 字距只有 3–5 px，垂直投影会把相邻字形并进一个连通域
- 单链聚类是"链式传播"，一个错误合并会吞掉一整段
- 越稀有的字母（j/q/x/z）样本越少，越容易标错

### 3.2 那次错误的本质

`jugs` 在截图里被切成了 **5 个字形**（`j` 和 `u` 之间被判定为间距，
`g` 的下伸部又被切了一刀）。而在源文件里它只有 **4 个字符**。

> 这正好印证了：**这类题的瓶颈不在算法，在信噪比**。
> 3–5 px 的字距在 3222×1856 的截图里已经到了信息论的下限。

## 4. 正解：客户端里留着明文

```
401Unauthorized_Data\StreamingAssets\content\dialogs\wedge-tablet.md
```

第一行就是 flag 行（字符之间带空格），正文用同一套替换写成英文。
**出题人把 Rosetta stone 和密文一起打包了。**

去掉空格后：

```
𒆳𒄞𒌋𒆸𒋗𒆠26{𒇻4𒌋𒄞_𒊕𒈨_𒁹0𒅆_𒊩1𒌷𒆸_𒄷𒈗𒄑𒍑_𒌋3𒀸8𒆸1𒀭4}
```

## 5. 建表

把 `wedge-tablet.md` 的正文和已解出的英文逐字对齐，得到 key：

| 符号 | 字母 | 符号 | 字母 | 符号 | 字母 |
|---|---|---|---|---|---|
| 𒆠 | t | 𒆳 | h | 𒆸 | e |
| 𒋗 | r | 𒀸 | a | 𒀭 | d |
| 𒍑 | s | 𒌋 | c | 𒊕 | m |
| 𒄩 | o | 𒀀 | w | 𒈲 | n |
| 𒊩 | f | 𒊺 | i | 𒄑 | g |
| 𒈗 | u | 𒈨 | y | 𒁹 | b |
| 𒇻 | p | 𒄞 | k | 𒌷 | v |
| 𒅆 | x | 𒄷 | j | | |

完整对照（按 Unicode 码位）：

```
12038 a   12079 b   1230B c   1202D d   121B8 e   122A9 f
12111 g   121B3 h   122BA i   12295 m   12232 n   12129 o
122D7 r   12351 s   121A0 t   12217 u   12000 w   12228 y
12337 v   1208D l   121FB p   1211E k   12146 x   1207A q
12328 z   12137 j
```

## 6. 代入 flag 行

```
h k c e r t 26 { …正文已脱敏… }
```

```
hkcert26{REDACTED}
```

### 6.1 明文其实是一个全字母句

flag 正文是英文 pangram 的 leet 变体：

```
pack my box with five dozen liquor jugs
```

—— 和"the quick brown fox jumps over the lazy dog"同类的**全字母句**。

> 这句 pangram 本身是公开语料，不是秘密；flag 里真正不可猜的部分是它后面的
> **随机 hex 段**（已脱敏）。所以保留这层解释不会让人反推出 flag。

这解释了两件事：

1. 为什么 flag 正文里几乎每个字母都出现过（出题人用 pangram 保证覆盖字母表）
2. 为什么我们能在只有 20 个已知字母的情况下"猜到"剩余部分 —— 词形太熟了

> 全字母句是这类替换密码题的常见载体：一句话覆盖 26 字母，
> 天然适合当 Rosetta stone。当 flag 正文读起来像 `pack my box…` 的 leet 变体时，就该警觉。

## 7. 正文原文（英文）

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

## 8. 正文译文（中文）

> 天亮前，商队从高地下来，把大车停在河边。他们翻过山口，运来谷物、油和铜，
> 指望城里能给个好价钱。一个年轻的书记官坐在城门下，车子一辆辆进来，他就一个个记下名字。
> 一整天，他记下了断掉的车轮、多出来的柳木车辕，还有那个把一只封好的箱子放在自己车上的沉默男人。
>
> 到了晌午，集市喧闹起来。买主为分量争个不停，孩子们在摊位之间追着山羊跑，
> 新烤的面包香味从炉子里飘出来。铜匠区的一个女人要了六份盐和一打鱼干。
> 天光暗下来时，书记官收起名册，走回档案库。泥板还软，他小心地把最后几行压上去，
> 把泥板搁在夜里风能吹干的地方。
>
> 第二天早上，他向总管念了名册。大多是熟名字，但有几个是从西山那边来的。
> 他们带来羊毛、皮革，还有一小箱青蓝色的石头。总管让书记官把每一行抄两遍：
> 一遍给税署，一遍给神庙。这活儿很慢，他的手抽筋，屋里还是那股烟，
> 屋子一直冷着，直到太阳照上墙头。
>
> 他在一条记录上停住了，那条跟别的不一样。物主没有留下姓氏，只留了一个记号，
> 货物写的不是粮食，而是杂七杂八的工具。书记官问了守卫，
> 可他们只记得那个外乡人用银币付了钱，在城门关之前就走了。
> 他在页边画了一颗小星星，把那块地方空着，盼着后来的读者能明白那个记号是什么意思。

## 9. 探针脚本

| 文件 | 作用 |
|---|---|
| `pipeline.py` / `cluster2.py` | 行切分、字符切分、字形聚类 |
| `solve_sub.py` | 词库模式匹配（短词歧义大，未采用） |
| `decode_body.py` | 用手工替换表还原正文 |
| `final_decode.py` / `split_decode.py` | flag 行字形匹配 |
| `decode_md.py` | **最终解法**：直接解析 `wedge-tablet.md` |

## 10. 复盘

- 猜想方向一直是对的（词形已经猜出大半），错的是**字形切分**
- flag 后缀是防猜的随机段，不是明文的一部分
- 这类题的第一动作应该是 `grep -r "content/dialogs"`，而不是 OCR
