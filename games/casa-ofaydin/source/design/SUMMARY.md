# Casa O'Faydin — Minutiae Deep Dive, in plain words

Date: 2026-11-10, evening CT. Written for Blake. Design only; no game code was changed in this pass.

Blake, you asked us to start digging into the minutiae now that the skeleton is standing. Here is the map. Every idea has a small first version and a later version, so we do not let the game get too heavy. Your rule still stands: watch out for feature creep, save memory, and do not do too much at once.

## Where to read the full notes

All of these are in `/workspace/casa-game/design/`:

- Trade, buyers, and regions: `trade-buyers-regions-v0.1.md`
- How you fund, send someone, and grow a new town: `founding-towns-v0.1.md`
- How you talk to a town without a politics sim: `courier-and-reports-v0.1.md`
- Government, guilds, legions, and the Latin name rules: `government-guilds-legions-v0.1.md`
- The lore bible (original gods, demigods, vampire clans, werewolf packs, banking clans): `lore-bible-v0.1.md`
- Built-in modding, JSON data, and load order: `modding-tools-v0.1.md`

The Latin word lists are at `/workspace/casa-game/godot/data/latin_names.json`. A short link section was also added to `game-design-plan-v0.1.md`.

## The six ideas, short

1. **Trade.** First you only get the Port Paradise market: eight goods, three kinds of buyers, and prices that drift a little each day. Later come one shipping route, then regions, caravans, ships, and starships.
2. **More cities.** First you just raise money (savings, a simple bank loan with interest that grows each season). Then you can take on a backer. Only later do you pick a founder, pack settlers, money, and a one-page charter, and send them to start a camp that can grow into a village, town, city, or kingdom. New towns reuse Port Paradise's layout, with different building styles.
3. **Talking to towns.** A courier desk and a one-page governor report, with ready-made letters and a few buttons (send grain, send money, ask for a report, leave it). The full hall and elections stay behind a door for when you want them.
4. **Government, guilds, and legions.** Offices use Latin titles with a plain English label, like "Praefectus, Governor." Guilds still roll names such as "The Blood Cloak (Assassins Guild)." Legions come later, named like "Legio IV Maritima." A generator with word lists and clear rules is specified; it never uses the forbidden number or borrowed Elder Scrolls names.
5. **Lore.** The shape is like a classic god court plus wilder bargains, but every name is ours. Eight Kindled gods, four Dusk powers, five demigods, four banking clans, four vampire clans, and three werewolf packs, all on a far-future Earth. Vampires and banks fight over old money and a goddess of fair counting named Numera. Vampires use a "night tithe" (a tired morning, never gore). Werewolves are a moonlit run in the woods. Your notebooks still win if they disagree.
6. **Mods.** Things like goods, towns, factions, gods, and names should live in JSON. A `mods/` folder and a load-order file come first. Build mode is the first in-game editor. A later Data Desk lets people add items without writing code. Open sharing on dynamisblake.com is a publish step, not part of this writing pass.

Rivalries and splinters are baked into each system. Kid-friendly, no gore, no eye signs, and the forbidden number never appears.

## Top 5 next build steps

These follow the scope lock. We finish a phase before we start the next one. We do not found empires in code tomorrow.

1. **Finish Phase 1** so Port Paradise is actually playable: arrival forms, switching characters, autonomy, the tavern games on screen, and the opening quests.
2. **Build the Phase 2 market** from data: a short goods list in JSON, buy and sell in town, prices that move a little each day, and three buyer types (townsfolk, merchants, the Counting House).
3. **Build the Phase 2 bank:** deposits, a simple loan, interest that compounds once a season, and balances that never show the forbidden number. That is how you start a founding chest, even though founding itself waits.
4. **Keep new content in JSON and add a `mods/` load-order hook** as those files land, so Cowork and later modders can drop in packs without rewriting the engine. The Latin names file is already there.
5. **Leave founding, regions, couriers, temples, and legions in the design folder until their phases** (couriers and guild offices in Phase 4; new towns, regions, and legions in Phase 5). Use these docs as the map, not as a to-do list for the current build.

Brick by brick.
