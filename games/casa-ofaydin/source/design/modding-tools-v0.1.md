# Built-in Modding Tools v0.1

Status: DESIGN ONLY. Do not change game code from this file.
Date: 2026-11-10, evening CT.
Lead: Agon, from Blake: the code should be open so everyone can see it and make their own mods. Modding tools need to be built in. It should feel Sims-style. We have the skeleton; now the minutiae should be data.

House rules: rivalries first; factions can splinter; never show the house-forbidden digit run; no eye imagery; kid-friendly; plain words.

Open source style on dynamisblake.com is a separate publish step. This doc is how the game itself should load and edit data so Cowork, Blake, and later players can add things without rewriting the engine.

---

## The idea

Most "content" should live in **JSON files**, not in hard-coded scripts: items, towns, factions, gods, and names. The in-game **Build mode** already planned for Phase 3 is the first built-in editor. A later in-game workshop edits those JSON lists with simple forms. Mods are folders with a load order, so one person's town or god pack can sit on top of the base game.

---

## Phase-first version

Do this early, in a small way, so we do not have to rip things out later. It can start as soon as Phase 2 (items and goods) and must not wait for Phase 5.

### 1. Data-driven lists

Base game data lives under `godot/data/` (and later under a public source folder on the site). Each file has a `version` field and an `id` on every record.

Planned files (some exist, some are still only planned):

| File | What it holds | Status now |
|---|---|---|
| `starting_gear.json` | Class kits | Already exists |
| `equipment_slots.json` | Paper-doll slots | Already exists (repo root; should also be referenced clearly for mods) |
| `latin_names.json` | Latin person, office, guild, and legion lists | Added 2026-11-10 |
| `goods.json` | Trade goods and base prices | Planned, Phase 2 |
| `buyers.json` | Buyer types and wants | Planned, Phase 2 |
| `factions.json` | Guilds, banks, vampire clans, packs | Planned, Phase 4 |
| `gods.json` | Kindled Court, Dusk Court, demigods | Planned, Phase 4 |
| `regions.json` / `towns.json` | Places, needs, layout template | Planned, Phase 4–5 |
| `letters.json` | Canned courier letters | Planned, Phase 4 |

Scripts should look up by id. If a name, price, or god title changes, the script does not.

Every record is checked on load:

- ids are unique inside their file
- no house-forbidden digit run in ids, names, or numbers
- no banned eye tokens, and no banned Elder Scrolls names (same lists as `latin_names.json`)
- no gore-flagged text in kid mode packs

A bad record is skipped, and a plain error is stored for a log Blake or a modder can read. The game should still boot.

### 2. Mod folders and load order

Folder layout (draft):

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

`mod.json` has: `id`, `name`, `version`, `author`, `description`, and optional `depends_on` (other mod ids).

`load_order.txt` is a plain list of mod ids, one per line, top to bottom. The base game loads first. Each mod then **merges by id**:

- a new id is added
- an existing id is replaced if the mod file says `"replace": true`
- otherwise a duplicate id is skipped and logged

Phase-first: the game can already read a `mods/` folder and a load-order file even if only one test pack exists. There is no store, no workshop upload, and no in-game browser yet. People can share a folder or a zip.

### 3. Builder tie-in (Phase 3)

Build mode is the first modding tool players touch:

- Place, Move, Remove, Paint, Style, Undo, snap to a grid (already in the plan)
- In Survival, pieces cost money or materials; in Creative they are free
- A saved lot is a data file (rooms, pieces, style) that a mod folder can include

Phase-first export: "Save lot" writes a JSON the game can reload. That is enough for Cowork or a friend to copy a house.

---

## Later version

- An in-game **Data Desk** (a simple form, like a Sims catalog): add or edit a good, a faction, a god, or a canned letter, then save it into a new mod folder. No typing raw JSON required.
- A style painter that can stamp a whole town skeleton (the Port Paradise layout) with a cultural pack.
- A name-list editor that uses the Latin generator rules.
- A public catalog or source page on dynamisblake.com where people can download packs (separate publish step, with Blake's OK).
- Sandbox tools for Watch mode: drop a rivalry flag, split a faction, and see what happens.
- Hard limits stay in place: cap on fully simulated characters, no off-screen heavy sim, kid-safe and banned-token checks on every loaded pack.

---

## Sims-style minutiae, without feature creep

"Sims-style" here means:

- you can tinker with people, lots, and lists
- the world keeps going while you watch
- most new stuff is data, not a new engine

It does not mean every Sims system at once (needs stay at three: food, shelter, money). New catalogs wait for their phase.

---

## What modders may change, by phase

- **Phase 2:** goods, prices, buyer wants, starting gear names (not slot rules).
- **Phase 3:** lot files, wall and furniture catalogs, style palettes.
- **Phase 4:** factions, gods, canned letters, guild word lists.
- **Phase 5:** regions, town templates, legion epithets, charter defaults.

Engine rules (how interest is applied, how autonomy chooses a job, how the forbidden-number check works) stay in code. Mods should not silently turn those off.

---

## House-rule checks for every pack

A shared validator (spec only in this pass) runs on base data and on mods:

1. Reject the forbidden digit run in any field.
2. Reject banned eye tokens and banned outside-world names.
3. Kid pack flag: no gore words.
4. If a pack fails, skip it and say why in plain words.

---

## What not to do in this pass

- Do not move or rewrite existing game scripts to be "mod ready."
- Do not stand up a public workshop.
- Do not add an in-game JSON editor yet.
- Do put new design lists in JSON as each phase lands, starting with the Latin names file already added.
