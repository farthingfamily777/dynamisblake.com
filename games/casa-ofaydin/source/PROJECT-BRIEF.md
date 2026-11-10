# Casa O'Faydin — Project Brief

A handoff brief for collaborators. Written from the real design docs and the Godot project on November 10, 2026 (America/Chicago). Unknown items are marked **TBD**. Nothing here is invented.

## Vision

Casa O'Faydin is a phone-first role-playing game Blake is building in the free Godot engine. It is set on Earth, far in the future, in a world he has been making for 15 years. Blake's lore comes first.

The feel is old-school, in the spirit of Knights of the Old Republic, Morrowind, Daggerfall-style random generation, and Baldur's Gate 3 open choices, with farming and building in the spirit of Minecraft. The art should be low-poly, beautiful, clearly a game world, and never uncanny. It has to run well on a mid-range phone.

High fantasy, industrial sci-fi, and cyberpunk share one sky. Sages, mages, wizards, warlocks, and shamans live beside starships, capital ships, cloning labs, and neon cities. Magic and science both work, and neither one wins.

Healing has three equal paths: magic spells (mana), science healing tanks in med bays and on starships (credits or time), and herbs you grow and brew on a farm.

The game should be fun for ages 7 and 9 and for ages 87 and 90. Kid-safe: no gore (bugs pop into light), no pushy buying, and easy-to-read text.

The world's name is **TBD**. The first town's working name is Port Paradise; Blake said the first word is still **TBD**.

Play is open-ended, like the Sims. There is no required win state. A headline idea is to let the sandbox take over: set the town's autonomy, hit Fast, and watch the drama happen.

## Pillars

- **Rivalries and drama first.** Blake's standing rule: "Always focus on rivalries and dramas." Each feature should create or feed a rivalry, a grudge, a betrayal, or an alliance. If it makes no drama, cut it or cut it down. The three standing rivalries are guild infighting, magic vs. science, and vampires vs. humans. Factions can later splinter, mutiny, or form a militia (Phase 4).
- **One living town first.** The proof of concept is Port Paradise, a busy, backwater, multicultural harbor port, not a whole continent.
- **Anyone can be played.** You can switch to any character at any time. A gambler can rise to governor; you can then play someone who opposes him. Every person uses the same character record.
- **The player is the Game Master.** Three modes, switched at any time: Play (be a character), Build (Sims-style town and home building), and Watch (a free camera with time controls). Autonomy is a four-step slider per character: Puppet, Helper, Free, and Wild.
- **Pick your start or roll one.** Arrival papers at the dock are how both starts work in this town.
- **Learn by playing.** Guilds, spells, and places teach real words from Latin, Greek, Aramaic, Sanskrit, and Arabic (for example, Lux, Latin for light). Stories come from the hero's journey and public-domain tales, not from copyrighted shows.
- **Kid-safe and all-ages.** Easy enough for 7, 9, 87, and 90. Drama through choices and talk, not gore.
- **Phones first.** Big buttons, readable type, modest performance. Other platforms (tablet, Xbox, VR) come later.

## Scope lock and phased roadmap

Decided November 10, 2026, 1:18 AM America/Chicago. Blake's rule: watch out for feature creep, save memory, and do not do too much at once.

Every idea stays in the plan, but it is built only in its phase. **Nothing from a later phase starts until the phase before it is playable and live.** New ideas go on the phase list, not into the current build. Each phase ships at 100 percent, then the team reflects, remeasures, and improves.

NPC life is inspired by Radiant AI, but tamed: only three needs (food, shelter, money); a short job list (chop trees, fish, farm, trade, work at the tavern, work as a guard); honest work first; theft or robbery only at Wild, and only after honest options fail. Nearby characters get a full simulation; far-away characters get one cheap dice roll per game day. Cap fully simulated characters at 24 to start. Use object pooling. Do not fully simulate what is off-screen and far away.

### Phase 0 — now

Walk around Port Paradise on the web, with Theatron's art. This is playable and live, with a web drawing fix shipped on November 10, 2026, and twin-stick move and look controls shipped the same day at 5:38 PM America/Chicago.

### Phase 1 — core loop

Port Paradise only.

- Arrival-forms character creation
- Switching characters
- Puppet, Helper, Free, and Wild autonomy
- The three needs and the short job list
- Tavern games: chess, checkers, and dominoes
- Opening quest line, in the style of a Morrowind arrival (our own story, no copied names or quests): papers at the dock, a lost ring, a missing tax collector, a smugglers' cave, and leads from a tavern keeper and a lighthouse keeper
- A basic Watch mode with time controls

### Phase 2 — economy

- Market buying and selling from data: eight goods, three buyer types (townsfolk, merchants, the Counting House), and prices that drift a little each day
- Simple bank deposits, a simple loan, and interest that compounds once a season (this starts a founding chest; founding itself waits)
- Houses and dynasties as heirs
- A few achievements
- A drama log, or "Port Paradise Gazette"
- Content in JSON, plus a `mods/` folder and load-order hook as those files land

### Phase 3 — building

- Build mode for one lot, from a shack up to a castle
- Creative and Survival world modes
- Style swaps
- One buildable lot in Port Paradise, plus a starter shack you can upgrade

### Phase 4 — politics

- Guilds and the three rivalries in quests, with rolled names and a plain English tag
- A governor ladder and first offices: Praefectus (Governor), Aedile, Quaestor
- One trade route to a second town
- A courier desk and a one-page governor report (canned letters, not a politics sim)
- Backers who can put coin in a founding chest
- Clan hooks from the lore bible (for example, a hidden Vesperine tie, Counting House vs the Pale Ledger)
- Splits, mutinies, and militias
- Headlines for mutinies and coups

### Phase 5 — big systems

- Founding towns: pick a founder, pack settlers, money, and a one-page charter; grow camp to village, town, city, then kingdom
- Regions, caravans, ships, and starships
- Couriers with rival letters, and two reports if a town splits
- Full offices, constitutions, temples, and named legions or cohorts
- Diplomacy, war, and armies, plus the war economy
- More towns in each culture's style, reusing the Port Paradise layout
- NPC-founded towns (rare events, not a simulation running all the time)

Earlier milestone notes (a dragon colony gray box, random villages, starship hubs, and so on) still live in the design plan as longer-term picture. They do not override this phase order.

## Systems that are done (and what is only half done)

### Arrival forms

**Logic is done. UI is not.** Spec: `docs/character-creation-v0.1.md`. Code: `godot/scripts/arrival_forms.gd`. Starting kits: `godot/data/starting_gear.json`. Slot names also live in `docs/equipment_slots.json`.

You arrive by boat and fill out papers at Census & Customs. Steps: how to begin (Pick my start or Random start), name, people, gender, look and voice, class, place/family/job, then review and Sign and Stamp. Starting classes already named by Blake: Pilgrim, Merchant, Mage, Fighter, Thief, Assassin, Rogue, and Vampire. Starting gear is applied from the class and is not a separate choice. The signed record is the shared character model every person in town will use.

Several lists still have **TBD** / placeholder marks in the spec: the Krishna-like and Ganesh-like people names, some family and job labels, appearance sliders, voices, and a few open lore questions. Do not ship placeholder labels as final names.

### Tavern games

**Rules, AI, and seat management are done. 42 of 42 headless tests pass. UI is not hooked up.** Spec: `docs/tavern-games-v0.1.md`. Code: `godot/scripts/tavern/`.

- Chess: full legal rules (castling, en passant, promotion, check, checkmate, stalemate, fifty-move, threefold, insufficient material).
- Checkers: forced captures, multi-jumps, and kings.
- Dominoes: four-player partnership Block Dominoes, games to 100 or 150, optional Draw mode.
- Easy, medium, and hard AI for each game, with no threads.
- `TavernTable` seats characters, supports mid-game switching, and emits signals for a future UI.
- Planned table placement (not built yet): chess in the high-class tavern; checkers and dominoes in the low-class shack.

### Port Paradise art

**A code-only art pass is in the live web build.** All meshes, textures, sky, and HUD styling are GDScript, not imported models. Entry point: `godot/art/bootstrap.gd`, called from `main.gd`.

The town includes dirt and cobble streets, hills, a harbor with sailing ships, a paddle steamboat, a barge, cranes, starship landing pads, palms, a market with stalls, a crowd, a bank, a smithy, neon towers, the wooden PORT PARADISE gate, a high-class tavern, a governor's mansion, shacks, a lighthouse, animals, a smugglers' cave mouth, and far-harbor dressing. The hero is a hooded traveler in a blue robe, with no visible face. The HUD uses Morrowind-like bars, a small compass, and large bronze Lux and View buttons.

The current visual baseline is Theatron's stills in `art-previews-v3/` (from `/workspace/casa-game/godot-art-previews-v3/`). That look is the floor. New art must meet the quality bar in the Cowork prompt: a muted earthy palette, consistent style, tuned lighting and fog, HUD-matched UI, no placeholder art, and before-and-after screenshots for Blake.

### Controls

**Twin-stick move and look, View, and Lux are in the live build and in this source copy.** Shipped November 10, 2026, at 5:38 PM America/Chicago.

- Left on-screen stick walks and strafes relative to the camera, with analog speed.
- Right stick turns the body and camera yaw, and tilts pitch.
- Multi-touch is supported. Dragging on an empty part of the screen also looks around.
- On a computer: WASD, mouse look, and Q/E.
- Lux and View sit above the look stick. Lux costs 20 mana and pops nearby bugs into light. View switches first person and third person.
- Auto Camera (best view per weapon or spell) is in the design plan, not built yet.

Code: `godot/main.gd` and `godot/scripts/virtual_stick.gd`. The sticks use gold/bronze HUD colors.

### Other prototype systems already in the running build

Day and night on a two-minute cycle, a day clock, health and mana, a circling fairy that refills both, five bugs that crawl toward the hero, and a gentle respawn if health runs out. These date from the first gray-box prototype and still run under the Port Paradise art.

## Owners (for context)

These are Blake's other bots and their design roles. Cowork is being handed the game build work. Do not assume they will do the next coding pass.

- Agon: lead, design plan, build (this brief).
- Theatron: art style, Port Paradise art, HUD, future table and paper UI.
- Rhapsodos: music, voices, story loom.
- Paidagogos: language lessons, kid ease and safety.
- Chronographos: lore bible and final names.
- Ephemeris: pitch and dev log.
- Logistes: money plan.
- Mneme: Blake's world archive (notebooks and artwork still to come).
- Gymnastes: play breaks.


## Minutiae deep dive (design only, November 10, 2026, evening America/Chicago)

Blake asked to start digging into the minutiae now that the skeleton is standing. These docs are design only. They do not change the scope lock. Each idea has a small first version and a later version. The one-page map is `design/SUMMARY.md`.

1. **Trade.** First, only the Port Paradise market: eight goods, three kinds of buyers, and prices that drift a little each day. Later come one shipping route, then regions, caravans, ships, and starships. Details: `design/trade-buyers-regions-v0.1.md`.
2. **Founding more towns.** First you only raise money (savings, a simple bank loan with interest once a season). Then you can take on a backer. Only later do you pick a founder, pack settlers, money, and a one-page charter, and send them to start a camp that can grow into a village, town, city, or kingdom. New towns reuse Port Paradise's layout, with different building styles. Details: `design/founding-towns-v0.1.md`.
3. **Talking to towns.** A courier desk and a one-page governor report, with ready-made letters and a few buttons (send grain, send money, ask for a report, leave it). The full hall and elections stay behind a Hall door. This starts in Phase 4, when a second town exists. Details: `design/courier-and-reports-v0.1.md`.
4. **Government, guilds, and legions.** Offices use Latin titles with a plain English label, like "Praefectus, Governor." Guilds still roll names such as "The Blood Cloak (Assassins Guild)." Legions come in Phase 5, named like "Legio IV Maritima." A generator is specified but not coded yet. Word lists are in `godot/data/latin_names.json`. Details: `design/government-guilds-legions-v0.1.md`.
5. **Lore bible.** The shape is a classic god court plus wilder bargains, but every name is original. Eight Kindled gods, four Dusk powers, five demigods, four banking clans, four vampire clans, and three werewolf packs, all on a far-future Earth (working label: Later Earth). Vampires and banks fight over old money and Numera, a goddess of fair counting. Vampires use a "night tithe" (a tired morning, never gore). Werewolves are a moonlit run in the woods. Blake's notebooks still win if they disagree. Details: `design/lore-bible-v0.1.md`.
6. **Mods.** Goods, towns, factions, gods, and names should live in JSON. A `mods/` folder and a load-order file come first, starting as Phase 2 data lands. Build mode is the first in-game editor. A later Data Desk lets people add items without writing code. Details: `design/modding-tools-v0.1.md`.

Rivalries and splinters are written into each of these systems. Do not found empires in the current build.

## Open items (TBD)

- The world's name, and the first word of "___ Port Paradise." The lore bible uses the working label Later Earth; do not lock that name.
- Final in-game names for the Krishna-like and Ganesh-like peoples.
- Lore bible names (gods, clans, packs, regions) are working names until Blake or Chronographos locks them.
- Whether fairies are a people or creatures, and how "Alien" and "Gray Alien" differ.
- Whether Rogue stays a starting class beside Thief and Assassin.
- Gender options beyond Male and Female.
- Finished appearance sliders, voice set, family names, and starting job list.
- The meaning of Blake's word "cantical."
- Blake's 15-year notebooks, pictures, and artwork (not in the archive yet).
- Android or iOS export. The design plan notes that export templates and an Android SDK were not set up on the build computer. This computer currently has Godot 4.3 web export templates only.
- Store and pricing questions (those are not Phase 0 or Phase 1 work).
