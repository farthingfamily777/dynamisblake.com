# Make your own mods

Mods are welcome. Blake wants people to see the code and make their own packs, in a Sims-style way: most new content should be data, not a rewrite of the engine.

This project is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). You can copy, share, and make mods if you give credit to Blake Farthing, you do not sell the work or use it mainly to make money, and you share your adaptations under the same license. The full legal text is in `LICENSE`.

The in-game workshop is not built yet. The plan for it is in `design/modding-tools-v0.1.md`. What follows is that plan, in plain words, plus a tiny example you can copy later.

## Where the data and scripts live

Base game data is meant to live under `godot/data/`. Each file should have a `version` field and an `id` on every record. Scripts look up things by id, so a name or price can change without rewriting the code.

Already in this source:

| File | What it holds |
|---|---|
| `godot/data/starting_gear.json` | Starter kits for each class |
| `godot/data/latin_names.json` | Latin person, office, guild, and legion word lists, plus ban rules |
| `docs/equipment_slots.json` | Paper-doll slot names (also referenced by the arrival forms) |

Scripts live under `godot/scripts/` (arrival forms, tavern games, the on-screen sticks). The town, hero, and HUD art live under `godot/art/`. Those are GDScript, not bulky image assets.

Planned data files, as each phase lands:

| File | What it will hold | When |
|---|---|---|
| `goods.json` | Trade goods and base prices | Phase 2 |
| `buyers.json` | Buyer types and wants | Phase 2 |
| `factions.json` | Guilds, banks, vampire clans, packs | Phase 4 |
| `gods.json` | Kindled Court, Dusk Court, demigods | Phase 4 |
| `regions.json` / `towns.json` | Places, needs, layout | Phase 4–5 |
| `letters.json` | Canned courier letters | Phase 4 |

The `mods/` folder and load-order hook should be added as those Phase 2 files land, so packs can drop in without rewriting the engine. An in-game Data Desk (simple forms, no raw JSON required) and a public catalog are later work. Build mode, in Phase 3, is the first built-in editor players will touch: saving a lot as a JSON file a friend can copy.

## How a mod folder will work

This is the planned layout. It is not wired into the running game yet.

```
<user or game root>/mods/
  load_order.txt
  my-harbor-goods/
    mod.json
    data/goods.json
  kindled-court-pack/
    mod.json
    data/gods.json
```

`mod.json` holds: `id`, `name`, `version`, `author`, `description`, and optional `depends_on` (other mod ids).

`load_order.txt` is a plain list of mod ids, one per line, top to bottom. The base game loads first. Each mod then merges by id:

- a new id is added
- an existing id is replaced if the mod file says `"replace": true`
- otherwise a duplicate id is skipped and logged

A bad record is skipped, and a plain error is stored so you can read it. The game should still boot.

Every pack, including the base game, should be checked on load:

- ids are unique inside their file
- the house-forbidden number (three sixes in a row) never appears in ids, names, or numbers
- no banned eye words, and no borrowed Elder Scrolls names (same lists as `latin_names.json`)
- no gore-flagged text in kid mode packs

Engine rules (how interest is applied, how autonomy chooses a job, how that number check works) stay in code. Mods should not silently turn those off.

## A tiny example: add a new good

`goods.json` is planned for Phase 2, so this is a sample pack, not something the live game reads today. When the hook is in, a folder like `mods/example-harbor-goods/` could look like this.

`mod.json`:

```
{
  "id": "example-harbor-goods",
  "name": "Example Harbor Goods",
  "version": "0.1",
  "author": "Your name",
  "description": "Adds a sample good called Sea Salt."
}
```

`data/goods.json`:

```
{
  "version": "0.1",
  "goods": [
    {
      "id": "sea_salt",
      "name": "Sea salt",
      "unit": "sack",
      "base_price": 3,
      "tags": ["harbor", "food"]
    }
  ]
}
```

And a line in `mods/load_order.txt`:

```
example-harbor-goods
```

Sea salt is only an example. It is not one of the eight goods in the trade design doc, and it is not in the live game.

## A tiny example: add a name list

`godot/data/latin_names.json` already holds the base word lists. A later name pack could add more civic names the same way, with a new id, and without any banned tokens. For example, a folder `mods/extra-civic-names/` with `mod.json` and a small `data/latin_names.json` that lists extra praenomina or cognomina. The generator must still reject a name that would break the house rules, and it must not invent legion numbers outside the approved list.

Until the load-order hook exists, you can study the lists in `godot/data/latin_names.json` and the rules in `design/government-guilds-legions-v0.1.md`, but do not expect the live web build to load a `mods/` folder yet.

## What you may change, by phase

- **Phase 2:** goods, prices, buyer wants, and starting-gear names (not slot rules).
- **Phase 3:** lot files, wall and furniture catalogs, style palettes.
- **Phase 4:** factions, gods, canned letters, guild word lists.
- **Phase 5:** regions, town templates, legion epithets, charter defaults.

If you share a pack, give credit to Blake Farthing, do not sell it, and keep it under CC BY-NC-SA 4.0. Keep it kid-safe, and always focus on rivalries and drama when you add world content.

For the full design, read `design/modding-tools-v0.1.md`.
