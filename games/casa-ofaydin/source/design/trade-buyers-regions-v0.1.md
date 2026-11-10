# Trade, Buyers, and Regions v0.1

Status: DESIGN ONLY. Do not change game code from this file.
Date: 2026-11-10, evening CT.
Lead: Agon, from Blake's deep-dive: "I wanna be able to set up trading and buyers and regions."
House rules: rivalries and dramas first; factions can splinter; never show the house-forbidden digit run (three sixes in a row); no eye imagery; kid-friendly for ages 7, 9, 87, and 90; plain words; call him Blake.

This doc sits under the SCOPE LOCK in `game-design-plan-v0.1.md`. A later system is not built until the phase before it is playable and live.

Related: founding towns (`founding-towns-v0.1.md`), courier reports (`courier-and-reports-v0.1.md`), banking already in the design plan (2026-11-10, 1:15 AM CT), and war demand already in the plan (2026-11-10, 1:17 AM CT).

---

## What Blake asked for

Goods, prices, supply and demand, buyer types, regions with their own needs, trade routes, and caravans or ships.

---

## Phase-first version (Phase 2, Port Paradise only)

One market stall sheet in Port Paradise. No second town yet. No caravans yet. No region map yet.

### Goods (keep the list short)

Eight goods, stored as JSON later under `godot/data/goods.json` (not written in this pass). Each good has an id, a plain name, a unit, a base price, and a tag for who wants it.

| Id | Name | Unit | Base price (draft) | Tags |
|---|---|---|---|---|
| `grain` | Grain | sack | 4 | food, farm |
| `fish` | Fish | crate | 5 | food, harbor |
| `timber` | Timber | bundle | 6 | build, wild |
| `iron` | Iron | bar | 8 | forge, war |
| `cloth` | Cloth | bolt | 7 | town, trade |
| `herbs` | Herbs | pouch | 6 | farm, heal |
| `tools` | Tools | set | 10 | build, science |
| `fuel` | Lamp oil and fuel | keg | 9 | harbor, science |

No eye-named goods. No forbidden digit anywhere in ids or prices. If a printed price would contain the forbidden run, bump the shown number by one (same rule as tavern scores).

### Buyer types (three only)

1. **Townsfolk** — buy food, cloth, and herbs a little at a time. Pay the posted price.
2. **Merchants** — buy in bulk when the price is low, sell when it is high. They care about the route, even if the second town is not in yet (they talk about "a ship that might come").
3. **The Counting House** — the local bank. Buys tools and iron for its stores, and will later back loans with goods as collateral.

A buyer record is just: `id`, `name`, `type`, `wants` (list of good ids), `budget` (a small number), `faction` (optional), and `grudge` (optional, a short line of drama).

### Prices and supply

- Each good has a stock in the Port Paradise market and a posted price.
- Once per game day, run one cheap pass (not a live sim of every cart):
  - If stock is high, price falls one step toward a floor (half the base).
  - If stock is low, price rises one step toward a ceiling (double the base).
  - A random buyer buys or sells a small amount, which changes stock.
- War, later, raises iron, tools, and fuel (already promised in the plan). Peace brings them back down.
- A shortage is drama, not just a number. If grain runs low, the Gazette (Phase 2 drama log) gets a line: "Grain is dear in the market. The low-class shack is angry at the cargo docks."

### What the player does

- Buy and sell at the market, as already planned for Phase 2.
- See a simple board: name, stock (Low / Enough / Plenty), price.
- Kid mode: the board uses those three words more than exact numbers. Exact coins are still available one tap away.

### Memory rules

- One price table for the whole town.
- Buyers on screen get a short daily action. Buyers off-screen do not get their own sim.
- Cap stall records. Do not spawn a new merchant NPC for every deal.

---

## Later version (Phase 4, then Phase 5)

### Phase 4 — one trade route

- Add a second town as a name and a price table, even if you only visit it by the route screen at first.
- One route: Port Paradise to that town, by ship (and later a starship berth as flavor).
- A tariff: low, medium, or high, matching the later constitution choices.
- The route can be **open**, **taxed**, **smuggled**, or **cut**. Cutting it is a rivalry event, not a combat sim.
- Player jobs already in the plan still apply: merchant, smuggler, banker.

### Phase 5 — regions, many routes, caravans and ships

A **region** is a handful of towns that share a landscape, a cultural building style, and a need list. Regions are data, not a second world sim running all the time.

Draft regions (working names; Blake can rename):

| Id | Region | Need (buys) | Surplus (sells) | Drama hook |
|---|---|---|---|---|
| `harbor_reach` | Harbor Reach (Port Paradise) | timber, herbs, fuel | fish, cloth, tools | smugglers vs the Counting House |
| `wall_march` | the High Wall March | grain, iron, tools | stone (later good), cloth | Walltrust vs the Highpass-Shy vampires |
| `ridgeward` | the Ridgeward Range | food, cloth | timber, herbs | werewolf packs; vampires will not cross |
| `ashpine` | the Ashpine Wilds | tools, grain | timber, herbs | pack hunting-ground fights |
| `neon_coast` | the Neon Coast | grain, fish, herbs | tools, fuel | House Meridian vs Saltwake Kin |
| `mushroom_low` | the Mushroom Lowlands | tools, cloth | herbs, strange food (later) | old relics, monk farms |
| `ember_belt` | the Ember Belt (volcanoes) | food, cloth | iron, fuel | Ferron temples, risky roads |

Routes then include **cart caravans**, **ships**, and **starships**. Each route is one record: two places, a vehicle type, a travel time in days, a risk word (Safe / Rough / Wild), a tariff, and an owner (a house, a guild, a clan, or the player).

A caravan or ship is not a full crew sim. It is a timer plus a dice roll when it arrives or when it is far away, same as the far-NPC rule in the scope lock. Near the player, you can walk the dock and see the cargo.

### Buyer types added later

- **Guild hall** — buys what its craft needs.
- **Legion quartermaster** — buys food, iron, and fuel when a legion is in the region (Phase 5).
- **Temple** — buys herbs and cloth.
- **Clan agent** — a banking clan or a vampire clan buying to squeeze a rival.

---

## Rivalries and splinters

Every trade feature should feed a grudge or an alliance.

- A merchant house that is undercut may splinter: a junior partner starts a rival stall.
- A smuggler crew may mutiny if the cut of a deal feels unfair (Wild autonomy only for the crime itself).
- If a town bans vampires, vampire buyers vanish from the open market and a rumor starts in the high-class tavern.
- If grain is held back to raise the price, townsfolk may form a militia later (Phase 4 rule).

---

## What this does not do in Phase 2

- No region map, no caravan pathfinding, no multi-town AI economy, no stock market screen, no real-time cargo physics.
- No founding of new market towns (that is Phase 5, see the founding doc).
