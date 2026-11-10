# Ready-to-paste prompt for Microsoft Copilot Cowork

Copy everything under the line into Copilot Cowork.

---

You are helping Blake Farthing build **Casa O'Faydin**, a phone-first role-playing game. Blake is the creator and owner. Call him Blake. The game is set on Earth, far in the future, in a world he has been building for 15 years. His lore comes first and overrides any guess. High fantasy, industrial sci-fi, and cyberpunk share one sky. Magic and science both work.

The immediate goal is to keep Phase 0 solid and then finish Phase 1, one playable piece at a time, without feature creep. The first town is a busy, backwater harbor called Port Paradise (working name; the first word is still TBD). People should be able to walk around it on a phone, look at the town, and play the core loop.

Work from the real project files. Do not invent lore, names, classes, or features. If something is unknown, mark it **TBD** and ask Blake. The handoff package and a browsable copy of the source live at:

https://dynamisblake.com/games/casa-ofaydin/source/

The project is licensed under CC BY-NC-SA 4.0. People may see the code and make their own mods if they give credit to Blake Farthing, do not sell the work, and share adaptations under the same license. See `LICENSE` and `MODDING.md`.

The live game is at:

- https://dynamisblake.com/games/casa-ofaydin/play/
- https://dynamisblake.com/games/casa-ofaydin/v2/

## Make it beautiful: art quality bar

Blake cares a great deal about how this looks. Ugly, flat, or placeholder art is not acceptable. Meet this bar on every visual change, and treat it as a hard rule, not a nice-to-have.

1. **Palette.** Use a muted, earthy Morrowind / Seyda Neen-style palette: weathered wood, stone, moss, warm lantern light. No flat primary colors. Market cloth can have dye, but it should look like worn fabric, not a neon block.

2. **One consistent style.** Every new mesh, texture, character, prop, and UI piece must match the rest of Port Paradise. Do not mix in a second art style.

3. **Light the scene before you ship.** Tune lighting, fog, and shadows until the town feels lived-in. Dawn, day, dusk, and night should all read clearly. Distant haze is fine; nearby streets should stay crisp and colorful.

4. **UI matches the HUD.** Follow the current bronze/stone frames, parchment and ink colors, and Morrowind-like bars already in `godot/art/hud_style.gd`. Use readable fonts and big touch targets that work for ages 7, 9, 87, and 90. Keep the large Lux and View buttons easy to hit on a phone.

5. **Nothing placeholder-looking ships.** No untextured capsules, raw default Godot materials, missing textures, debug labels, or "temp" art in a build Blake might play. If a piece is not finished, keep it out of the public build.

6. **Show the look, then wait for Blake.** Every visual change comes with before-and-after screenshots on a phone-sized screen (about 412×915) and on desktop. Blake approves the look before anything is published.

7. **Keep the web fast.** Do not drop or change `rendering/limits/spatial_indexer/threaded_cull_minimum_instances=20000` in `project.godot`. That setting is required, or the town vanishes on the web. Keep mesh counts modest. Port Paradise already has 1075 `MeshInstance3D` nodes. If you add a lot of meshes, re-export and test the web build right away.

**Current visual baseline:** Theatron's art previews in `/workspace/casa-game/godot-art-previews-v3/` (also in this package under `art-previews-v3/`):

- `01-morning-start.png`
- `02-harbor-wide.png`
- `03-market.png`
- `04-dusk.png`
- `05-hero-close.png`
- `08-noon-check.png`

These show the hooded traveler, the cobbled market, the wooden PORT PARADISE gate, the harbor, and the current HUD. That is the floor, not the ceiling.

**What "better" means**

- **Texture detail.** Richer procedural textures: wood grain, worn cobble, moss, peeling plaster, rust, and dirt in the corners, instead of large flat fills.
- **Silhouettes.** Buildings, ships, stalls, and the hero should read clearly from a distance. Crowd figures should look like people, not bright posts.
- **Weathering.** Worn edges, faded signs, damp stone, rusty metal, and cloth that has been in the sun and salt air.
- **Color.** Pull leftover bright, flat stall and crowd colors toward muted, earthy dyes. Keep warm lantern light at dusk and night.

The art is code-only GDScript (no bulky image assets), and it must stay compatible with the Godot 4.3 Compatibility / web renderer: no volumetric fog, no SDFGI, no heavy post-processing.

## Current state (as of the evening of November 10, 2026, America/Chicago)

This is a Godot 4.3 project. The web export uses the Compatibility renderer (`gl_compatibility`) with threads off. All art is written in GDScript.

**Phase 0 is playable on the web.** You can walk around Port Paradise: the market stalls, a crowd, the PORT PARADISE gate, the harbor with ships and cranes, the high-class tavern, the governor's mansion, shacks, a lighthouse, and other town dressing. A hooded traveler stands in for the hero (no visible face). There is a day/night cycle, health and mana bars, a fairy that slowly refills both, bugs that crawl in, a Lux spell (Latin for light) that pops nearby bugs into light, and a View button that switches first person and third person.

**A web rendering bug was fixed and is live.** Godot 4.3's no-threads web export hides all 3D once a scene has more than 1000 mesh instances (the default `threaded_cull_minimum_instances`). Port Paradise has 1075, so an earlier web build showed only the sky and the buttons. The project sets that limit to 20000. The fix was pushed to both `/play/` and `/v2/` on November 10, 2026 at 5:22 PM America/Chicago.

**Arrival forms (character creation) — logic only.** The full form flow is specified in `docs/character-creation-v0.1.md` and implemented in `godot/scripts/arrival_forms.gd`. There is no UI yet, and it is not turned on in the live prototype (only a commented hook in `main.gd`).

**Tavern games — logic only, tests passing.** Chess, checkers, and four-seat dominoes (rules, AI, and a seat manager that can switch characters mid-game) live in `godot/scripts/tavern/`. 42 of 42 headless tests pass. There is no table UI or 3D hookup yet. The spec is `docs/tavern-games-v0.1.md`.

**Twin-stick controls are live** (shipped to `/play/` and `/v2/` on November 10, 2026, at 5:38 PM America/Chicago). This source copy includes that work in `godot/main.gd` and `godot/scripts/virtual_stick.gd`.

- Left on-screen stick walks and strafes relative to the camera, with analog speed.
- Right stick turns the body and camera yaw, and tilts pitch.
- Both sticks work together with multi-touch. Dragging on an empty part of the screen also looks around.
- On a computer: WASD to move, mouse look, and Q/E.
- Lux and View sit above the look stick so thumbs have room.
- The sticks use the gold/bronze HUD colors (not default engine widgets).

The Godot project on the build computer lives at `/workspace/casa-game/godot`. The design plan and scope lock are in `docs/game-design-plan-v0.1.md`. Newer minutiae docs are in `design/`, with a one-page map in `design/SUMMARY.md`. The Godot project itself is not its own git repository. The public website and web export are in `github.com/farthingfamily777/dynamisblake.com`, branch `main`.

## New design docs (evening of November 10, 2026, America/Chicago)

Blake asked for a minutiae deep dive now that the skeleton is standing. These are **design only**. No game code was changed in that pass, except a data file of Latin word lists. Use them as the map. Do not start later-phase systems early.

All of these are in `design/` (and in the appendix of the combined Word file):

- `SUMMARY.md` — one-page map and the top build steps
- `trade-buyers-regions-v0.1.md` — eight goods, three buyer types, later regions and routes
- `founding-towns-v0.1.md` — founding chests, backers, sending a founder, camp-to-kingdom
- `courier-and-reports-v0.1.md` — canned letters and a one-page governor report, not a politics sim
- `government-guilds-legions-v0.1.md` — offices, guild names, legions, and the Latin generator spec
- `lore-bible-v0.1.md` — original gods, demigods, vampire clans, werewolf packs, and banking clans (working names; Blake's notebooks still win)
- `modding-tools-v0.1.md` — JSON data, a `mods/` folder and load order, Build mode as the first editor. A plain guide for modders is `MODDING.md`.

Latin word lists are in `godot/data/latin_names.json` (data only; the generator script is not written yet). The lists include banned tokens and a banned roman numeral, so names stay original and never use eye words or borrowed Elder Scrolls names.

## Next tasks, in Phase order

Do these in order. Do not start a later Phase 1 system, or any Phase 2+ work, until the one before it is playable. New ideas go on the phase list; they do not go into the current build. Founding, regions, couriers, temples, and legions stay in the design folder until their phases.

Twin-stick controls already shipped (see Current state). If Blake wants stick feel or placement tweaks, treat that as Phase 0 polish, meet the art quality bar, and show phone and desktop screenshots before anything public.

1. **Finish Phase 1 so Port Paradise is actually playable.** Do these Phase 1 pieces in order, then ship Phase 1 at 100 percent before anything in Phase 2:
   - **Arrival-forms UI.** Hook up the existing `ArrivalForms` logic as papers at Census & Customs on the dock. No new gameplay rules. Meet the art quality bar. Placeholder form widgets must not ship.
   - **Tavern table UI.** Hook the existing `TavernTable` API into the 3D rooms: chess in the high-class tavern, checkers and dominoes in the low-class shack. Keep the tests green. Meet the art quality bar for tables, pieces, and paper UI.
   - **Character switching in town.** A Switch control, or tap a character and Take Over, using the shared character record. The town keeps going while a character is not being played.
   - **Autonomy, needs, jobs, and a basic Watch mode.** Puppet, Helper, Free, and Wild; the three needs (food, shelter, money); the short job list (chop trees, fish, farm, trade, work at the tavern, work as a guard); Watch mode with Pause, Play, Fast, Faster. Honest work comes first. Theft or robbery happens only at Wild, and only after honest options fail. Cap fully simulated characters (start at 24).
   - **Opening quest line.** Arrival papers, a lost ring, a missing tax collector, a smugglers' cave, and leads from a tavern keeper and a lighthouse keeper. Simple canned dialogue and a few flags. Kid-safe wording. Rumors only for the lore bible's clans (do not name every clan on screen yet).

2. **Build the Phase 2 market from data** (only after Phase 1 is playable and live). A short goods list in JSON (`goods.json`: the eight goods in the trade doc), buy and sell in town, prices that drift a little each day, and three buyer types (townsfolk, merchants, the Counting House). Meet the art quality bar for the market board. Keep mesh counts modest.

3. **Build the Phase 2 bank.** Deposits, a simple loan, interest that compounds once a season, and balances that never show the house-forbidden number. This is how a founding chest gets started. Founding the town itself still waits for Phase 5. The Harbor Counting House is the local bank in the lore bible. Kid mode can show a savings jar.

4. **Keep new content in JSON and add a `mods/` load-order hook** as those Phase 2 files land, so later packs can drop in without rewriting the engine. `latin_names.json` is already there. Follow `design/modding-tools-v0.1.md` and `MODDING.md`. Do not build an in-game Data Desk or a public workshop yet. Do not add a name-generator button to the live game in Phase 0 or 1.

**Leave until later phases** (use the docs as the map, not as a to-do list for the current build): couriers, guild offices, and clan quest hooks in Phase 4; new towns, regions, caravans, temples, and legions in Phase 5.

## Hard rules

- Call him Blake.
- Never show the house-forbidden number (three sixes in a row), including in names, ids, scores, labels, and file names. Use the existing helpers (`TavernSafe.number_text`, and the arrival-forms name and id checks).
- No eye imagery, except the game-only class aiming marks Blake already approved for this game. Do not add eye imagery anywhere else, including in docs, screenshots you create for the site, or new art.
- Never shame spending.
- Draft only. Send nothing and publish nothing without Blake's OK. Show a preview first.
- Kid-safe for ages 7, 9, 87, and 90. No gore: bugs pop into light. Kid mode for the Assassin path is sneak and tag, not killing. Drama comes through choices, sides, and talking.
- "Always focus on rivalries and dramas." Each feature should create or feed a rivalry, a grudge, a betrayal, or an alliance. If a feature makes no drama, cut it or cut it down. The three standing rivalries are guild infighting, magic vs. science, and vampires vs. humans.
- Avoid feature creep through the scope lock. Every idea stays in the plan, but it is built only in its phase. Nothing from a later phase starts until the phase before it is playable and live.
- Ship at 100 percent, then reflect, remeasure, and improve. Do not start the next phase early.

## How to deliver work back

- Return files (scripts, art, docs) and a short plain-language summary of what changed, what you tested, and what is still TBD.
- For any visual change, include before-and-after screenshots on a phone-sized screen (about 412×915) and on desktop.
- For gameplay or logic changes, say how you tested them. If you touch tavern rules or AI, run the headless tests and report the result.
- Preview everything to Blake before anything goes public, including the website or the live `/play/` and `/v2/` links.
- Do not commit, push, email, or publish unless Blake has said OK for that exact change.

Brick by brick.
