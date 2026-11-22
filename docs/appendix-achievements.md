# Appendix · The 42 achievements

> Source: the in-game achievement page, 42 entries.
> Unlock rates are from the screenshot taken around 18:58 (one hour into the event) and are only
> useful as a relative difficulty signal.

## 1. Full list

| # | Achievement | Condition | Unlocked |
|---|-------------|-----------|----------|
| 1 | Diagnostic insight | 12 consecutive valid buffer calibrations | 0.0% |
| 2 | Ten steps ahead | Predict 10 signal channels correctly in a row | 1.0% |
| 3 | Beneath the wall's shadow | ??? (hidden) | 0.0% |
| 4 | Jailbreak | Defeat the 1/F boss, the warden | 0.2% |
| 5 | Golem collapse | Defeat the 2/F boss, the relic golem | 0.0% |
| 6 | Heartbreaker | Defeat the 3/F boss, the dungeon heart | 0.0% |
| 7 | Maze walker | Open the chest at the end of the maze | 0.0% |
| 8 | Peak | Reach level 50 | 0.0% |
| 9 | Out of reach | ??? (hidden) | 0.0% |
| 10 | Merry Christmas to me | Help me, ERINNNNNN!! I can't translate it! But I know they are two sentences!… | 0.0% |
| 11 | Merge the shards | Try merging shards from the Discord emoji shop! | 0.0% |
| 12 | Buy the most expensive item | Try buying the priciest item in the Discord emoji shop! | 0.0% |
| 13 | Hidden secret | The Discord bot '401 Emoji Shop' is hiding something… | 0.0% |
| 14 | Enterprise log deployment tool | Explore the secrets of the enterprise log deployment tool! | 0.5% |
| 15 | First day on the job | Complete the workstation tour with R. This flash drive is studio property. | 33.8% |
| 16 | Log leak | Find what the dev log leaked by accident | 0.6% |
| 17 | Log in as admin | The 'upcoming events' site seems hosted by some tool… try to get access! | 0.0% |
| 18 | Ouija six | Parapsychologist | 0.0% |
| 19 | Non-human speed | Win a Typeway 2000 race in the game center | 0.2% |
| 20 | Strange event poster | Something is hidden inside the 'upcoming events' poster… | 0.0% |
| 21 | Instruction drift | Deviate from the beginner porridge instructions before the "three bowls of barley porridge / first dungeon entry" record appears | 0.8% |
| 22 | First glimpse | Unlock your first skill | 0.0% |
| 23 | Tempered | Upgrade a weapon for the first time | 1.8% |
| 24 | Mastery | Unlock every skill and max every upgradeable one | 0.0% |
| 25 | Open the case | Open the phantom workstation and mount the evidence disk | 17.4% |
| 26 | Pocket money | ??? (hidden) | 1.3% |
| 27 | Pentathlete | Raise all five attributes to level 10 | 0.0% |
| 28 | Sold out | The sponsor's memory, entirely sold out | 0.0% |
| 29 | The old cheat still works | Enter the ancient cheat code — gamepad or keyboard | 12.2% |
| 30 | Hundredfold | Upgrade a weapon to +100 | 0.0% |
| 31 | First wind | Win a full East-round match on low difficulty, first place | 0.2% |
| 32 | Maze conqueror | ??? (hidden) | 0.0% |
| 33 | Clean exit | Complete the "first infiltration" quest | 1.5% |
| 34 | Fully equipped | Complete the "upgrade equipment" quest | 0.6% |
| 35 | Eternal orbit | Keep playing… MMXXVI・XI・VI | 0.0% |
| 36 | Time keeper 1 | Clear an Easy performance with ALL JUST | 0.0% |
| 37 | Time keeper 2 | Clear an Expert performance with ALL JUST | 0.0% |
| 38 | Time keeper 3 | Clear a Troll performance with FULL COMBO | 0.0% |
| 39 | Time traveller 1 | Clear an Easy performance before the game launched | 0.0% |
| 40 | Time traveller 2 | Clear an Expert performance within 24 hours before launch | 0.0% |
| 41 | Time traveller 3 | Clear a Troll performance within 5 minutes before launch | 0.0% |
| 42 | Seal | Win against the guard at full strength and seal a vault | 0.2% |

## 2. Tiers

### A. Freebies (≥ 1% unlocked — pure mechanics/onboarding)

| Achievement | Unlocked | How |
|---|---|---|
| First day on the job | 33.8% | follow R. through the workstation tour |
| Open the case | 17.4% | phantom workstation + mount the evidence disk |
| The old cheat still works | 12.2% | the classic Konami code (↑↑↓↓←→←→BA) |
| Tempered | 1.8% | first weapon upgrade |
| Clean exit | 1.5% | the "first infiltration" quest |
| Pocket money | 1.3% | hidden, but 1.3% solved it — so the trigger is not exotic |
| Ten steps ahead | 1.0% | predict 10 signal channels in a row (implies a deterministic solution exists) |
| Instruction drift | 0.8% | deliberately ignore the beginner porridge steps before the trigger records fire |
| Log leak | 0.6% | find the leaked content in the dev log |
| Fully equipped | 0.6% | the "upgrade equipment" quest |

### B. Security challenges (the ones that produce flags)

| Achievement | Target | Likely focus |
|---|---|---|
| Hidden secret / Merge the shards / Buy the most expensive item | Discord bot '401 Emoji Shop' | **401 = Unauthorized**: auth bypass, economy privilege escalation, shard-merge logic flaw |
| Log in as admin | 'Upcoming events' site, hosted by "some tool" | admin panel default credentials / known CVE / path disclosure |
| Strange event poster | something hidden in the poster | stego, metadata, QR/layers |
| Enterprise log deployment tool | an "enterprise" log deployment product | product-level flaw (default config, unauthenticated API) |
| Log leak | dev log leak | git history, debug output, `.env` |
| Merry Christmas to me | "I can't translate it! But I know they are two sentences!" | almost certainly a second substitution-puzzle tablet |
| Ouija six / Parapsychologist | Ouija board, mind reading | RNG prediction / weak PRNG seed |

### C. Time manipulation

- **Time traveller 1/2/3** — require clearing a performance "**before the game launched**" ⇒ manipulate
  the client/system clock
- **Eternal orbit** — `MMXXVI・XI・VI` = **2026-11-06**, the launch date ⇒ likely also clock/date based
- **Merry Christmas to me** — Christmas ⇒ 25 December, plausibly date triggered

Highest-value line: once "the game trusts the local clock" is confirmed, four achievements may fall
together.

### D. Grind tier (0.0% — pure time sink)

Peak (level 50), Hundredfold (+100), Mastery (all skills maxed), Pentathlete (five attributes at 10),
Sold out (empty the sponsor's stock).

Classic time traps; very poor value in a 24-hour event unless a fast-farm bug turns up.

### E. Dungeon combat tier

Jailbreak 1/F, Golem collapse 2/F, Heartbreaker 3/F (three bosses), Maze walker / Maze conqueror
(maze chest), Seal (win against the guard at full strength).

Gated by gear and level, hence coupled to tier D.

## 3. Reading the clues

### 1. '401 Emoji Shop'

"401" is HTTP **Unauthorized**. A Discord shop plus three achievements (merge shards / buy the most
expensive item / hidden secret) points squarely at **authentication and authorization**:

- query someone else's order by ID → IDOR
- shard merging without quantity/rarity checks → negative amounts or overflow
- the priciest item is unaffordable → price or balance trusted client-side

### 2. 'Upcoming events' + enterprise log deployment tool

Both descriptions mention "hosted by some tool", likely the **same product**: identify it, then look
for default credentials or a known CVE.

(We later identified **Quick.Cms** — see [07-webview-cms.md](07-webview-cms.md).)

### 3. Time traveller / Eternal orbit

`MMXXVI・XI・VI` is Roman numerals for 2026-11-06.
Combined with "before the game launched", the client clearly judges by **local time**.

That is both an achievement trick and a possible vulnerability (client time bypassing other time locks).

### 4. Merry Christmas to me

> "Help me, ERINNNNNN!! I can't translate it! But I know they are two sentences!…"

Almost certainly related to the **untranslated tablet**: an NPC holding a tablet they cannot read, but
recognising "two sentences". Ours had a flag line plus four body paragraphs, so this is probably another one.

### 5. Ten steps ahead / Diagnostic insight / Ouija six

All three involve prediction or mind reading. If they are random judgements, consecutive success is
practically impossible by hand — so either the seed is fixed or you read memory / patch traffic.
**Ten steps ahead has 1.0% unlocked**, so a stable solution exists.

## 4. Scoring observation

The platform does not score by flag count; it scores by **achievement rarity**. Empirically:

- achievements fall into two weight bands (roughly 50 and 500 base points)
- final value ≈ `0.1 × base + 0.9 × base × rarity factor`
- rarer achievements carry a larger rarity factor

So the optimal strategy is to chase **rare but tractable** achievements rather than volume.

## 5. Priority order (post-event)

1. **0–30 min**: sweep tier A (tutorial, cheat code, upgrade, quests, pocket money) while learning the map
2. **30 min–3 h**: attack the three web/service clusters in tier B — they produce flags directly
3. **Interleaved**: verify the clock hypothesis (system time → Time traveller 1); if it holds, four
   achievements fall at once
4. **Last**: tier D/E only if a fast-farm bug appears
