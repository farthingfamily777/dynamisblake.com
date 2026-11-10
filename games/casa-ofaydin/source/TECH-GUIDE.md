# Casa O'Faydin — Tech Guide

How the project is laid out, how to run tests, how to export for the web, and how the site goes live. Written from the real files on November 10, 2026 (America/Chicago). Unknown items are marked **TBD**.

## Engine and project settings

- Engine: **Godot 4.3** stable.
- Main scene: `res://main.tscn`, which runs `main.gd`.
- Application name in `project.godot`: "Casa O'Faydin Game - Milestone 1".
- Display: 720×1280, portrait (`window/handheld/orientation=1`), stretch mode `canvas_items`, aspect `keep`.
- Touch: `pointing/emulate_touch_from_mouse=true`.
- Renderer: `mobile` by default; **web must use Compatibility** (`renderer/rendering_method.web="gl_compatibility"`).
- **Threads off** on the web export (`variant/thread_support=false`).
- All gameplay and art scripts are plain GDScript. No threads in game code.
- Textures: `textures/vram_compression/import_etc2_astc=true`.

### The cull setting (required)

In `godot/project.godot`:

```
rendering/limits/spatial_indexer/threaded_cull_minimum_instances=20000
```

Do not remove or lower this. Godot 4.3's no-threads web export hides all 3D once a scene has more than 1000 mesh instances (the default). Port Paradise has 1075 `MeshInstance3D` nodes, so a build without this setting shows only the sky and the HUD buttons. This is a known engine issue: https://github.com/godotengine/godot/issues/96968

If you add many new meshes, re-export and test the web build right away. Keep mesh counts modest.

## Folder map

On the build computer, the working tree is `/workspace/casa-game`. The live Godot project is `/workspace/casa-game/godot`. That folder is not its own git repository. The public website lives in `/workspace/dynamisblake/site`, which is the git repo `github.com/farthingfamily777/dynamisblake.com`.

```
casa-game/
  game-design-plan-v0.1.md      Scope lock, phases, lore notes
  character-creation-v0.1.md    Arrival-forms spec
  tavern-games-v0.1.md          Tavern games spec
  equipment_slots.json          Paper-doll slot names and item stats
  design/                       Minutiae deep-dive docs (design only, Nov 10 evening)
    SUMMARY.md
    trade-buyers-regions-v0.1.md
    founding-towns-v0.1.md
    courier-and-reports-v0.1.md
    government-guilds-legions-v0.1.md
    lore-bible-v0.1.md
    modding-tools-v0.1.md
  godot/                        Live Godot 4.3 project (this is what you export)
    project.godot
    export_presets.cfg
    main.tscn
    main.gd
    art/                        Code-only art
    scripts/virtual_stick.gd    On-screen Move and Look sticks
    scripts/arrival_forms.gd
    scripts/tavern/             Chess, checkers, dominoes, AI, tests
    data/starting_gear.json
    data/latin_names.json       Latin person, office, guild, and legion word lists
  godot-art-previews-v3/        Current visual baseline stills
  handoff/                      This package
```

Other folders you may see (`godot-art/`, `backups/`, `web-preview/`, older preview folders) are working copies or backups. **Edit and export from `godot/`.**

In this handoff package and on the public source page, the same project files are grouped like this:

```
godot/           The Godot project, without the .godot cache or exports
docs/            Earlier design specs and equipment_slots.json
design/          Minutiae deep-dive docs, including SUMMARY.md
art-previews-v3/ Baseline stills
```

## What each project file does

### Root of `godot/`

- **`project.godot`** — Engine settings, including the Compatibility web renderer and the cull limit of 20000.
- **`export_presets.cfg`** — The "Web" export preset. Threads are off. The export path points at the site's `games/casa-ofaydin/play/index.html`. The HTML head sets a phone viewport, a dark green page background, and a "back" control style. This file holds no secrets, tokens, or passwords.
- **`main.tscn`** — A single `Node3D` named Main, with `main.gd` attached.
- **`main.gd`** — The running prototype. It builds a collision ground, a hero capsule (later restyled by art), a camera, a fairy, five bugs, and the HUD (health, mana, day clock, View, Lux, and two virtual sticks). It advances the day/night clock, moves the hero with twin-stick or WASD, looks with the right stick, empty-screen drag, or the mouse, refills health and mana, moves bugs, and casts Lux. It calls `Art.apply` and `Art.update_sky`. Arrival forms and tavern tables are mentioned only in comments.
- **`data/starting_gear.json`** — Starter kits for the eight starting classes, using only the approved slot names.
- **`data/latin_names.json`** — Word lists and ban rules for a future Latin name generator (persons, offices, guilds, legions). Data only; no generator script is in the project yet. The rules are in `design/government-guilds-legions-v0.1.md`. Planned later data files (`goods.json`, `buyers.json`, and others) are listed in `design/modding-tools-v0.1.md` and should land with their phase. A `mods/` folder and load-order hook are designed, not built.


### `godot/art/` (all code-only GDScript)

- **`bootstrap.gd`** — One entry point so `main.gd` stays small. `apply()` sets up sky, hero, fairy and bug styling, town, HUD, and a runtime FX node. `update_sky()` is called each frame. `style_new_bug()` styles respawned bugs. If the `ART_SHOT` environment variable is set, it queues preview stills.
- **`sky.gd`** — Compatibility-safe procedural sky, light, and distance fog. No volumetric fog, SDFGI, or glow. Nearby town stays crisp; the far horizon hazes. Colors shift through dawn, day, dusk, and night.
- **`town.gd`** — Port Paradise layout: ground, hills, harbor shoreline, bridge and canal, streets, shacks, houses, domes, high-class tavern, governor's mansion, PORT PARADISE arch, clutter, cave and far-harbor silhouette, animals, dust. Calls `harbor.gd` and `market.gd`.
- **`harbor.gd`** — Ships, cranes, landing pads, and dock palms visible from spawn.
- **`market.gd`** — Market street, stalls, crowd, bank, smithy, and neon towers.
- **`props.gd`** — Shared low-poly pieces (boxes, cylinders, palms, bushes, lighthouse, animals, and other dressing) and helpers to add meshes.
- **`tex.gd`** — Tiny cached procedural textures (dirt, cobble, plaster, wood, rust, stone, sand, moss, fabric, leather, and others) for a weathered look. ImageTexture only; no large assets.
- **`hero_model.gd`** — Replaces the prototype capsule with a hooded traveler: layered robe, trim, pauldrons, boots. No visible face or eyes.
- **`hud_style.gd`** — Restyles the HUD: gold-framed bars, clock, bronze Lux and View buttons, a spell/weapon box, and a compass. Keeps the Move hint where `main.gd` placed it.
- **`fx.gd`** — Runtime ticks: rotating lighthouse, flickering neon, paddle wheel, forge glow, wandering animals and people, compass update.
- **`shot.gd`** — Dev-only stills. When `ART_SHOT` is set, it writes PNGs (morning start, harbor, market, and other views) and can quit. Used to make the baseline previews.

### `godot/scripts/`

- **`virtual_stick.gd`** — On-screen analog stick used for Move and Look. Gold ring and knob, one tracked finger, `mouse_filter` set to ignore so `main.gd` can handle multi-touch.
- **`arrival_forms.gd`** (`class_name ArrivalForms`) — Character creation logic only. Steps, validation, random start, class gear, ids that avoid the house-forbidden number, and `make_npc()` for townspeople who use the same record. Call `self.randomize()` on this class so it is not confused with Godot's global `randomize()`. Gear is loaded from `res://data/starting_gear.json`.

### `godot/scripts/tavern/`

- **`chess_rules.gd`** (`ChessRules`) — Full legal chess.
- **`checkers_rules.gd`** (`CheckersRules`) — Forced captures, multi-jumps, kings, draw rules so games cannot run forever in a browser.
- **`dominoes_rules.gd`** (`DominoesRules`) — Four-player partnership Block Dominoes, double-six set. Gold is seats 0 and 2; Silver is seats 1 and 3. Target 100 or 150. Optional Draw mode. Scores are bumped if they would print the house-forbidden number.
- **`tavern_ai.gd`** (`TavernAI`) — Easy, medium, and hard movers for each game. Chess hard is alpha-beta at depth 2 by default; checkers hard is depth 4. No threads.
- **`tavern_table.gd`** (`TavernTable`) — Seats, human/AI flags, mid-game `switch_human()`, `try_move()`, `legal_moves()`, `play_ai_if_needed()`, and the `move_made`, `turn_changed`, and `game_over` signals.
- **`tavern_safe.gd`** (`TavernSafe`) — `number_text()` so a forbidden digit run never prints as a single token.
- **`tavern_tests.gd`** — Headless rules tests plus 20 AI-vs-AI games of each kind. Extends `SceneTree`.

The `TavernTable` API and move formats are documented in `docs/tavern-games-v0.1.md`.

## How to run the tests

On the build computer, Godot 4.3 stable is at `/tmp/Godot_v4.3-stable_linux.x86_64`. Your machine may have a different path. From a terminal:

```
/tmp/Godot_v4.3-stable_linux.x86_64 --headless --path /workspace/casa-game/godot --script res://scripts/tavern/tavern_tests.gd
```

A passing run prints `RESULTS: 42 passed, 0 failed` and `ALL PASSED`, and exits 0. If you copy the project, point `--path` at your `godot/` folder.

These tests cover tavern rules and AI only. They do not start the 3D town or the web build.

## How to export for the web

Use the built-in preset named **Web** in `export_presets.cfg`. Exact settings that matter:

- Platform: Web
- `variant/thread_support=false` (threads off)
- `variant/extensions_support=false`
- `export_path="../../dynamisblake/site/games/casa-ofaydin/play/index.html"` (relative to `godot/`)
- `html/canvas_resize_policy=2`
- `html/focus_canvas_on_start=true`
- Custom `html/head_include` for the phone viewport and page chrome
- VRAM texture compression on for desktop and mobile
- `script_export_mode=2`

The project must still have `renderer/rendering_method.web="gl_compatibility"` and `limits/spatial_indexer/threaded_cull_minimum_instances=20000`.

On the build computer, web export templates for 4.3 stable are installed (including the no-threads release template). A headless export looks like this:

```
/tmp/Godot_v4.3-stable_linux.x86_64 --headless --path /workspace/casa-game/godot --export-release "Web" /workspace/dynamisblake/site/games/casa-ofaydin/play/index.html
```

After a successful export, the play folder should contain `index.html`, `index.js`, `index.pck`, `index.wasm`, icons, and `.nojekyll`. The live site also keeps a copy under `games/casa-ofaydin/v2/`. The last public fix copied the same build to both `/play/` and `/v2/`.

**Always test the web build in a real browser** after export. Confirm the town draws, not just the sky and buttons. If the town is missing, check the cull setting first.

Do not publish an export until Blake has seen a preview and said OK.

Android and iOS exports are **TBD**. This computer has web templates only. The design plan already noted that Android needs export templates and an Android SDK.

## How the site deploys

- Repo: `https://github.com/farthingfamily777/dynamisblake.com`
- Branch: `main`
- Hosting: GitHub Pages, source branch `main`, site root `/`
- Custom domain: `dynamisblake.com` (CNAME file in the site root; HTTPS is on)
- Game page: `https://dynamisblake.com/games/casa-ofaydin/`
- Live play: `https://dynamisblake.com/games/casa-ofaydin/play/` and `.../v2/`
- This source and handoff: `https://dynamisblake.com/games/casa-ofaydin/source/`

A push to `main` starts a Pages build. The new files are usually live in a few minutes. An old web export can stick in a phone browser for about 10 minutes; a refresh or a private tab helps.

The site repo may contain other unpublished work in unrelated folders. When you are asked to publish game files, stage only the Casa O'Faydin paths Blake has approved. Do not commit or push without that OK.

## House rules in code

- Never print or store the house-forbidden number (three sixes in a row).
- No eye imagery in art, except the game-only class aiming marks Blake already approved.
- Kid-safe wording and no gore.
