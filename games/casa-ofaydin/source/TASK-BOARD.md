# Casa O'Faydin — Task Board

Plain checklists for the current work. Status is as of the evening of November 10, 2026, America/Chicago, from the real project files. Items marked **TBD** still need a decision from Blake.

## Art quality bar (every visual change)

Use this checklist on every art or UI pass before asking Blake to approve it.

- [ ] Muted, earthy Morrowind / Seyda Neen palette: weathered wood, stone, moss, warm lantern light. No flat primary colors.
- [ ] Style matches the rest of Port Paradise. No second art style mixed in.
- [ ] Lighting, fog, and shadows are tuned. Dawn, day, dusk, and night all read clearly.
- [ ] UI matches the current HUD (bronze/stone frames, parchment and ink, readable type, big touch targets).
- [ ] Nothing placeholder-looking is in the build (no raw capsules, default materials, debug labels, or "temp" art).
- [ ] Before-and-after screenshots on a phone-sized screen (about 412×915) and on desktop are ready for Blake.
- [ ] Blake has approved the look before anything public.
- [ ] `threaded_cull_minimum_instances=20000` is still set. Mesh counts stayed modest. The web build was tested, and the town still draws.
- [ ] The result looks better than the `art-previews-v3/` baseline in texture detail, silhouettes, and weathering.

## Done

- [x] Design plan, scope lock, and phased roadmap (`docs/game-design-plan-v0.1.md`).
- [x] Arrival-forms logic and spec (`godot/scripts/arrival_forms.gd`, `docs/character-creation-v0.1.md`, `godot/data/starting_gear.json`). No UI yet.
- [x] Tavern games logic, AI, seat manager, and 42 of 42 headless tests (`godot/scripts/tavern/`, `docs/tavern-games-v0.1.md`). No table UI yet.
- [x] Port Paradise art pass in GDScript: market, crowd, PORT PARADISE gate, harbor, tavern, mansion, shacks, lighthouse, and related dressing.
- [x] Hooded hero model (no visible face), Morrowind-like HUD, day/night sky and fog.
- [x] Prototype loop still running under that art: day clock, health and mana, fairy refill, bugs, Lux, View camera toggle.
- [x] Web export on Godot 4.3, Compatibility renderer, threads off.
- [x] Cull fix live so the town draws in the browser (`threaded_cull_minimum_instances=20000`). Shipped to `/play/` and `/v2/` on November 10, 2026, at 5:22 PM America/Chicago.
- [x] Game pages live at https://dynamisblake.com/games/casa-ofaydin/play/ and https://dynamisblake.com/games/casa-ofaydin/v2/
- [x] Visual baseline stills saved in `art-previews-v3/`.
- [x] Minutiae design docs in `design/` (summary, trade, founding towns, couriers, government/guilds/legions, lore bible, modding tools). Design only; no gameplay code was changed in that pass.
- [x] Latin word lists added at `godot/data/latin_names.json` (data only; generator not written yet).
- [x] Twin-stick touch controls: left stick walks and strafes, right stick looks. Live on `/play/` and `/v2/` as of November 10, 2026, 5:38 PM America/Chicago. Source: `godot/main.gd`, `godot/scripts/virtual_stick.gd`.


## In progress

- None at the time this package was published. Twin-stick already shipped. Phase 1 is next.

Published: this handoff package and a browsable source copy at https://dynamisblake.com/games/casa-ofaydin/source/

## Next (Phase order)

Do these in order. Do not start Phase 2 until Phase 1 is playable and live. Twin-stick controls already shipped. If Blake wants stick feel or placement tweaks, treat that as Phase 0 polish and show screenshots first.

### Phase 1 — core loop, Port Paradise only

- [ ] Arrival-forms UI at Census & Customs on the dock, hooked to the existing `ArrivalForms` logic. Pass the art quality bar. Do not ship placeholder widgets.
- [ ] Tavern table UI hooked to `TavernTable`: chess in the high-class tavern; checkers and dominoes in the low-class shack. Keep the 42 tests passing. Pass the art quality bar.
- [ ] Character switching in town: Switch control, or tap a character and Take Over. Left characters keep living.
- [ ] Autonomy levels: Puppet, Helper, Free, and Wild, including a Whole-town slider.
- [ ] Three needs (food, shelter, money) and the short job list (chop trees, fish, farm, trade, work at the tavern, work as a guard). Honest work first. Theft or robbery only at Wild, after honest options fail. Cap of 24 fully simulated characters to start.
- [ ] Basic Watch mode with time controls (Pause, Play, Fast, Faster).
- [ ] Opening quest line: arrival papers, a lost ring, a missing tax collector, a smugglers' cave, and leads from a tavern keeper and a lighthouse keeper. Simple canned dialogue and a few quest flags. Kid-safe wording.
- [ ] Opening quest rumors stay light: do not name every lore-bible clan on screen yet.
- [ ] Phase 1 playable and live at 100 percent. Then reflect, remeasure, and improve.

### Phase 2 — economy (not started)

Do not start this until Phase 1 is playable and live. Details are in `design/trade-buyers-regions-v0.1.md`, `design/founding-towns-v0.1.md`, and `design/modding-tools-v0.1.md`.

- [ ] Market from data: eight goods in `goods.json`, buy and sell in town, daily price drift.
- [ ] Three buyer types: townsfolk, merchants, and the Counting House.
- [ ] Harbor Counting House bank: deposits, a simple loan, interest once a season (balances must never display the house-forbidden number). This starts a founding chest. Do not add a Found Town button yet.
- [ ] Houses and dynasties as heirs.
- [ ] A first set of achievements (counts and points must never display the house-forbidden number).
- [ ] Drama log, or "Port Paradise Gazette."
- [ ] Put new content in JSON, and add a `mods/` folder with a load-order hook, as those files land. `latin_names.json` is already there. No in-game Data Desk or public workshop yet.

### Phase 3 — building (not started)

- [ ] Build mode for one lot, shack to castle.
- [ ] Creative and Survival world modes.
- [ ] Style swaps.
- [ ] Starter shack you can upgrade.

### Phase 4 — politics (not started)

Leave these in the design folder until Phase 3 is done. Details: courier, government, lore, and trade docs.

- [ ] Guilds and the three rivalries in quests, with rolled Latin-style names and a plain English tag.
- [ ] Governor ladder and first offices: Praefectus (Governor), Aedile, Quaestor.
- [ ] One trade route to a second town.
- [ ] Courier desk and one-page governor report (canned letters, not a politics sim).
- [ ] Backers for a founding chest.
- [ ] Clan hooks from the lore bible (working names until Blake locks them).
- [ ] Splits, mutinies, and militias.

### Phase 5 — big systems (not started)

- [ ] Found a town: founder, settlers, chest, one-page charter; grow camp to kingdom.
- [ ] Regions, caravans, ships, and starships.
- [ ] Rival letters, and two reports if a town splits.
- [ ] Full offices, constitutions, temples, and named legions or cohorts.
- [ ] Diplomacy, war, armies, and the war economy.
- [ ] More towns in each culture's style, reusing the Port Paradise layout.
- [ ] NPC-founded towns as rare events.

## Waiting on Blake (TBD)

- [ ] The world's name. The lore bible uses the working label Later Earth; do not lock it.
- [ ] The first word of the town name ("___ Port Paradise").
- [ ] Final names for the Krishna-like and Ganesh-like peoples.
- [ ] Lore bible names (gods, clans, packs, regions) are working names until Blake or Chronographos locks them.
- [ ] Whether fairies are a people or creatures.
- [ ] How "Alien" and "Gray Alien" differ.
- [ ] Whether Rogue stays a starting class beside Thief and Assassin.
- [ ] Gender options beyond Male and Female.
- [ ] Finished appearance, voice, family, and starting-job lists.
- [ ] The meaning of the word "cantical."
- [ ] Notebooks, pictures, and artwork for the world archive.
- [ ] Whether to set up Android or iOS export (web is the current target).
