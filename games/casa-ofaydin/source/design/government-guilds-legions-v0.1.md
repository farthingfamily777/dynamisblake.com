# Government, Guilds, Legions, and Latin Names v0.1

Status: DESIGN ONLY. Do not change game code from this file.
Date: 2026-11-10, evening CT.
Lead: Agon, from Blake: "And the government and the guilds and the legions remember Latin name generation."
House rules: rivalries first; factions can splinter; never show the house-forbidden digit run (three sixes in a row); no eye imagery; kid-friendly; plain words.

Data file: `/workspace/casa-game/godot/data/latin_names.json`
Older guild roller (prototype, still valid): `/workspace/casa-game/guild_names.py`
Lore for temples and clans: `lore-bible-v0.1.md`
Founding and charters: `founding-towns-v0.1.md`

The data file is lists only. This doc is the rules and the pure function spec. No game scripts are added in this pass.

---

## How the pieces fit the phases

- **Phase 1:** people already live in Port Paradise. No offices to elect yet. A character's `role_ladder` can still say "gambler" or "new arrival."
- **Phase 4 (phase-first for this system):** the four classic guilds appear in quests, with rolled Latin-style names that always include a plain English tag. A governor ladder exists. Offices used in Port Paradise: Praefectus (governor), Aedile (markets and streets), Quaestor (the public purse). The Latin generator may be used for those titles and for NPC names.
- **Phase 5 (later):** full offices (Consul, Praetor, Tribune, Censor, Proconsul), constitutions, and legions. A town that reaches city can raise or host **one cohort**. A kingdom can name **one legion**. Armies and the war economy stay in this phase, as already locked.

---

## Government, phase-first

Port Paradise keeps a **governor**. The player-facing label is "Governor." The Latin office behind it is **Praefectus**.

On the paper, always show both:

> Praefectus Mara Valeria Severa, Governor of Port Paradise

Other Phase 4 offices, only if a building exists:

- **Aedile** — markets, streets, public works.
- **Quaestor** — the town chest.
- **Duumvir** — used in a village that is too small for a governor (two local chairs).

Leaders change the way the charter or constitution says: elections, heirs, or the guilds pick them. Phase-first elections are one ballot with two or three names and a plain result, not a campaign sim.

### Later offices

| Id | Latin | Plain meaning |
|---|---|---|
| consul | Consul | Top elected chair of a city or kingdom |
| praetor | Praetor | Judge and vice-chair |
| aedile | Aedile | Markets, streets, works |
| quaestor | Quaestor | Public purse |
| tribunus | Tribunus | The people's voice |
| praefectus | Praefectus | Appointed governor |
| censor | Censor | Counts people and property |
| proconsul | Proconsul | A consul sent to a region |
| legatus | Legatus | Legion commander, or a founder's deputy |
| centurio | Centurio | Captain of a hundred |
| duumvir | Duumvir | One of two chairs in a small town |
| pontifex | Pontifex | A temple chair (no gore rites) |

Full list and wording also live in `latin_names.json` under `offices`.

---

## Guilds, phase-first

The four classic guilds stay the same types already in the plan:

- Mages Guild
- Fighters Guild
- Thieves Guild
- Assassins Guild (kid mode: sneak and tag, no killing)

Every new world rolls a display name and **always** appends the plain type, for example `The Blood Cloak (Assassins Guild)`. "The Blood Cloak" remains the signature assassins name in the word list.

Phase 4 uses those names in quests and in the three rivalries (guild infighting, magic vs science, vampires vs humans). When loyalty drops, a guild can split, as already locked: a new tagged name is rolled for the splinter ("The Velvet Thorn (Assassins Guild), split from the Blood Cloak").

Later (Phase 5): craft guilds and banking halls can use the same format, with new types added to the JSON, not hard-coded.

---

## Legions, later (Phase 5)

A **legion** is a named army body, not a battlefield engine of its own. War still uses the many-paths plan (commander, merchant, smith, and so on). Kid mode shows strategy and outcomes, no gore.

Name format:

> Legio IV Maritima

That is the word `Legio`, a roman numeral from the approved number list, and an epithet from the list (Maritima, Muraria, Ferraria, Luminosa, Stellaris, and the rest in the JSON).

Smaller bodies:

- `Cohors II Portuensis` — a cohort (phase-first army flavor for a city).
- `Vexillatio Salina` — a detached company on a road or wall.

Never use a legion number that is not on the approved list in `latin_names.json`. Never emit the banned roman token `DCLXVI`. Never print the house-forbidden digit run in arabic or in a label.

A legion can mutiny or split, same standing rule. A mutiny rolls a new vexillation name and a Gazette line.

---

## Latin name generator — rules

### Kinds

The generator returns one of these kinds:

- `person` — `praenomen nomen cognomen` (a full Latin-style name)
- `office` — Latin title plus plain English, optionally with a person name
- `guild` — `The {adjective} {noun} ({plain type})`
- `legion` — `Legio {roman} {epithet}`
- `cohort` — `Cohors {roman} {epithet}`
- `vexillation` — `Vexillatio {epithet}`

### Gender and people

- For `person`, honor the character's gender field: masculine or feminine lists in the JSON. If a later gender option is added by Blake, use the masculine or feminine lists only when they fit, or add a third list then. Do not guess new lists now.
- These lists are for Latin-style civic names. Other peoples (ork, dragon, fairy, and so on) should use their own name lists later. A Nordic fighter in a city office may still take a civic Latin name as a public name; that is a style choice, not a forced rename of their people.

### Banned content

- Build the forbidden digit pattern at runtime from the digit six repeated three times. Do not store that pattern as a literal if it would appear as one number. If a name, numeral, id, or label would contain it, reject and roll again.
- Reject any string that contains a banned token from the JSON (eye words and the listed Elder Scrolls names). The game may be inspired by that structure, but it may not use those names.
- Reject the banned roman token `DCLXVI`.
- Use only approved legion numbers. The list skips a few values on purpose so nearby labels are less likely to form a bad run; still always run the check.

### Always be readable

- Guilds always append the plain type.
- Offices always have a plain English gloss.
- Kid mode can show the plain words first, Latin second.

### Determinism

Same kind, same seed, same options, same result. That way a world can be replayed and mods can test names.

---

## Pure function spec

Language-agnostic. Implement later in GDScript or Python. No I/O, no nodes, no random global state. Pass an RNG or a seed in.

```
load_tables(json) -> tables

# roman numeral for an approved number only.
to_roman(n, tables) -> string | error

# true if the string contains the forbidden digit run,
# a banned token (case-insensitive, whole word or stem as listed),
# or the banned roman token.
is_forbidden(text, tables) -> bool

# options may include:
#   gender: "male" | "female"
#   guild_type: "mages" | "fighters" | "thieves" | "assassins"
#   office_id: "consul" | "praetor" | "aedile" | ...
#   person_name: optional string already generated
#   number: optional approved legion or cohort number
#   epithet: optional forced epithet
#   max_tries: default 16
#
# returns:
#   {
#     "ok": true,
#     "kind": kind,
#     "text": display string,
#     "plain": plain English line,
#     "parts": { ...kind-specific parts... },
#     "seed": seed used
#   }
#   or { "ok": false, "error": "..." }
generate(kind, seed, options, tables) -> result
```

### Algorithms

**to_roman(n):** If `n` is not in `tables.legions.numbers`, error. Build tens and ones from `tables.roman_numerals`. If the result is banned, error.

**generate(person):** Seed the RNG. Pick praenomen, nomen, and cognomen from the gender lists. `text` is the three words in order. `plain` is the same (people already hear it as a name). `parts` stores the three fields. If `is_forbidden(text)`, retry.

**generate(guild):** Pick adjective and noun from that type's lists. If the type is assassins and the world wants the signature name, allow an option `signature: true` to force `The Blood Cloak (Assassins Guild)`. Otherwise roll. `plain` is the plain type. Retry on forbidden text.

**generate(office):** Look up `office_id`. `text` is the Latin title, plus the person name if given. `plain` is the `plain` field from the JSON. Example: `text = "Aedile Gaia Cornelia Prisca"`, `plain = "Aedile, keeper of markets, streets, and public works"`.

**generate(legion / cohort):** Use `options.number` or roll one from the approved list. Convert with `to_roman`. Use `options.epithet` or roll one. Build the format string from the JSON. Retry on forbidden text. Do not invent numbers outside the list.

**generate(vexillation):** Epithet only, no number.

A tiny helper `number_text(n)` should match the tavern rule: print ordinary numbers as digits, but if the forbidden run would appear, insert spaces so those digits never sit together.

---

## Rivalries and splinters

- Two Consuls or a Consul and a Praetor can become rivals. A succession fight uses the history templates already in the plan (heirs, regents, exiles).
- A guild split rolls a new guild name and keeps the same plain type.
- A legion mutiny rolls a Vexillatio and a Gazette headline (Phase 4 headlines, Phase 5 civil wars).
- Kid mode: sides and talking, no gore.

---

## What not to build yet

- Do not add a name-generator button to the live game in Phase 0 or 1.
- Do not raise legions before Phase 5.
- Do not replace arrival-form placeholder names until Theatron and Chronographos hook this in on purpose.
