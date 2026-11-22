# FinSim · a complete economic simulation

> Location: lobby · FinSim terminal
> Verdict: fully implemented and properly validated; no single gap punches through it

## 1. Layout

```
FinSim — National Agriculture Ventures

1000.00 CR   ⚡ 80/100   8 actions   Day 1 / 30   [Next day 🌙]
```

Eleven tabs across the bottom:

| Tab | Content |
|---|---|
| **Build** | construction panel |
| **Market** | fruit trading (dynamic pricing) + juice stand |
| **Bag** | inventory: fruit, bottles, photo, sell |
| **Deliver** | delivery contracts + bidding |
| **Trade** | coin exchange (ORNG / APPL / CHIV / BITE) |
| **Invoices** | invoicing |
| **Orders** | orders (not explored) |
| **Album** | photo album |
| **Wallet** | ledger |
| **News** | market news |
| **Discover** | three locked cards |

## 2. Build

| Facility | Price | Effect |
|---|---|---|
| Orange orchard | 40.00 CR | +30 storage · 🍊 harvest |
| Apple orchard | 40.00 CR | +30 storage · 🍎 harvest |
| Juice factory | 30.00 CR | +30 storage · make juice |
| Delivery truck | 20.00 CR | unlocks delivery bids |
| Warehouse | 25.00 CR | +50 fruit storage |

Juice workshop: `2 fruit + 0.80 CR → 1 bottle`.

## 3. The full loop we ran

```
build (115 CR) → buy 20 oranges (27.60 CR) → juice 5 bottles (4.00 CR)
→ bulk sell (33.50 CR) → bid on a contract → send the truck → invoice
```

Measured:

| Step | Result |
|---|---|
| Build 4 facilities | `1000.00 → 885.00 CR`, storage `0/120` |
| Buy 20 oranges | `857.40 CR`, storage `20/120`, orange reference `1.00 → 1.80` |
| Juice 5 bottles | `853.40 CR`, oranges `20 → 10` |
| Bulk sell 5 bottles | `+33.50 CR` (9 CR × 80% − 0.50 per bottle) |

## 4. Delivery and bidding

```
CWE delivery                [open]   Day 2
Place bid for service charge
Bid from Swift Freight: 9.95 CR
```

- The contract is literally named **`CWE delivery`** — CWE = Common Weakness Enumeration, i.e. the
  authors are telling you the weakness class
- Rival **Swift Freight** quotes a floating price (we saw 8.73 / 9.95)
- We bid **1.00 CR** and won (lowest bid wins)
- Sending the truck creates contract `CWE-3482`: `Awaiting truck` → dispatched → `paid`

## 5. Invoicing: all three boundaries tested

Form fields: `Contract reference` / `Amount CR` / `Description`.

| Attempt | Result | Meaning |
|---|---|---|
| empty reference | `Please fill out this field.` | client-side required check |
| `-10` | `Value must be greater than or equal to 0.01.` | browser `min` validation |
| `99999` | `rejected: invalid amount` | **server-side cap exists** |
| `1.00` (contract value) | ✅ `paid` | happy path |
| re-invoice `1.00` | `rejected: no open obligation` | **replay protection works** |
| same contract, `9.00` | `rejected: no open obligation` | obligation already closed |

Conclusions:

- the amount cannot be inflated (server validates)
- the count cannot be inflated (obligation is one-shot)
- negatives are blocked client-side, and because the server answered `invalid amount` rather than
  "already closed", the server **checks the obligation before the amount** — so reordering does not
  help either

## 6. Selling: a demand band

Each bottle in the Bag has its own price field:

```
Orange juice · Use by day 7 · ITEM-0001
[📷 Photo]  [Drink · 20]  Sell: [9] [Sell]   (0.50 CR selling fee)
```

Selling at `999999`:

```
Consumer demand supports 1–9 CR today
```

The band changes per day (1–9 today). This is a **designed dynamic system**, not a bug.

Bulk-sale rule, printed under the button:

> Bulk sale: 20% below individual maximum, then 0.50 CR fee per bottle.

## 7. Coins (Trade)

```
ORNG  OrangeCoin   16.40 CR   5 held
APPL  AppleCoin     9.89 CR   0 held
CHIV  ChiveCoin    10.05 CR   0 held
BITE  BiteCoin      9.83 CR
```

Buy / sell both directions, prices drift with the day — speculation, not a money printer.

## 8. Discover: three locks

```
🔒 Undiscovered — Keep exploring the economy.   ×3
```

After the full loop (build → buy → process → photograph → sell → bid → invoice) **and** building all
five facilities, not one card opened.

Assessment: the unlock conditions are far beyond "play through once" — possibly all 30 days, a
five-figure CR balance, or a specific rare event.

## 9. Retrospective

The subsystem is **fully implemented**:

- server-side amount cap ✔
- one-shot obligation / replay protection ✔
- dynamic demand band ✔
- storage cap + daily holding cost ✔

It behaves like a real small game rather than a vulnerable target, so the return on time was poor
for a 24-hour event.

### The one useful signal

The name `CWE delivery` plus the bidding mechanic points at **business-logic flaws**
(price manipulation / duplicate settlement / cross-tenant contract access), not injection or overflow.
We ruled out two of the three (amount, replay). The remaining one —
**contract IDOR** — was not tested:

contract IDs are **sequential** (`CWE-3482`), so invoicing against someone else's ID would be a
textbook `CWE-639` if the server does not scope the lookup to the authenticated player.
