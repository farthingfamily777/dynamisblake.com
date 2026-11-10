# Casa O'Faydin — Character Creation / Arrival Forms v0.1

Status: DRAFT logic and data only. No UI, no export changes, no site push.
Date: 2026-11-10, late night CT.
Lead source: Blake, in Theatron's chat, 2026-11-10, 1:07 AM CT, modeled on Morrowind's opening.
You arrive as a newcomer in the harbor town Port Paradise and fill out arrival forms at the dockside census and customs office.

This file is the spec. The code is `/workspace/casa-game/godot/scripts/arrival_forms.gd`. The class-to-gear table is `/workspace/casa-game/godot/data/starting_gear.json`.

House rules used here: the house-forbidden number (three sixes in a row) is never used, including in names, ids, and numbers. No eye imagery and no eye-named items (the class-crosshair exception is art-only, not gear). Wording is meant to be easy for ages 7, 9, 87, and 90.

Blake's 15-year world comes first. This spec uses only classes and peoples already named in the design plan, the world archive, and the lore bible. It does not invent new canon. Where a list is missing, the option is marked **[PLACEHOLDER]**.

Theatron's paper mockup at `/workspace/casa-game/art/arrival-papers-character-creation-v0.1.jpg` is a review sheet (name, people, gender, appearance, class, starting gear, Random Start, Sign and Stamp). The logic below supports that sheet. A few example values on the mockup are not canon and must not be shipped: "Spellsword" is a Morrowind class name, not one of Blake's classes; "Dark Elf" is not on Blake's people list (he said "elves"); "Varden Coris" is only a sample name.

---

## 1. How this fits "Pick my start" and "Random start"

The current Godot prototype (`main.gd`) has no character creation yet. The hero is a plain capsule. "Pick my start" and "Random start" exist only in the design plan (Update 2026-11-09, 8:12 PM CT): the player chooses **Pick my start** (place, family, job) or **Random start**, like the alternate-start mods for Skyrim and Starfield. The creator should have Morrowind depth: face, body, race, and voice.

The arrival-forms flow is how both starts work now:

- **Pick my start:** the player walks the form steps and chooses each field, including place, family, and job.
- **Random start:** every field is filled at once, starting gear is applied from the rolled class, and the player lands on the review sheet to read it, roll again, change a line, or sign.

The first town is the proof of concept, so both starts take place in **Port Paradise** (working name; Blake said the first word is still to be decided). The story beat is the same: the boat lands at the arrival dock, and you fill out papers at the office next door. Place is "where you are headed in town," not a different city.

---

## 2. Form steps, in order

Player-facing titles are in plain words. A linear walk is easy on a phone. The review sheet can also jump to any step (the arrows on Theatron's mockup). Starting gear is not a choice; it is applied when class is set and shown on the review.

### Step 1 — How to begin

- Fields: `start_mode`
- Options:
  - `pick` — "Pick my start"
  - `random` — "Random start"
- Next: a choice is required.
  - If **Random start**, fill every field (see §4), apply class gear, and jump to Step 8 (Review and sign).
  - If **Pick my start**, go to Step 2. Place, family, and job start with the kind new-arrival defaults listed below, and the player can change them in Step 7.
- Back: leaves the forms (no record is saved). This is a UI action, not a signed character.

### Step 2 — Your name

- Fields: `name`
- One text box: "What should we call you?"
- Rules: required. Trim spaces. 1 to 32 characters. Letters, spaces, hyphens, and apostrophes are allowed. The name must not contain the house-forbidden number (three sixes in a row).
- Next: valid name required.
- Back: to Step 1. If the player then switches to Random start, the random fill replaces the name.

### Step 3 — Your people

- Fields: `race` (stored as a people id)
- Player-facing label: "Your people"
- Options are the peoples Blake has already named. See §6. A choice is required.
- Next: a people id from that list is required.
- Back: to Step 2.

### Step 4 — Your gender

- Fields: `gender`
- Options on file (Blake said "gender" but did not list choices):
  - `male` — "Male"
  - `female` — "Female"
  - **[PLACEHOLDER]** More options can be added when Blake names them.
- Next: a listed choice is required.
- Back: to Step 3.

### Step 5 — How you look and sound

Blake asked for appearance, and the design plan also names face, body, and voice. No finished look list is in the docs, so the choices below are simple **[PLACEHOLDER]** options until art and voice are set.

- Fields, under `appearance`:
  - `face` — Face 1, Face 2, Face 3, Face 4, Face 5
  - `hair` — Short, Medium, Long, Braided, Bald
  - `hair_color` — Black, Brown, Gold, Red, White, Gray
  - `tone` — Tone 1 through Tone 8 (art will map these per people; a dragon, an ork, and a human will not share the same colors)
  - `build` — Small, Medium, Tall, Sturdy
- Fields, beside appearance:
  - `voice` — Warm, Calm, Bright, Deep (**[PLACEHOLDER]** until Rhapsodos records real voices)
- Next: every subfield and voice must be filled from those lists.
- Back: to Step 4.
- Later face sliders (Morrowind-depth nose, jaw, and so on) are **[PLACEHOLDER]** and are not in this version. The five faces and the body fields are the first, easy set.

### Step 6 — Your class

- Fields: `class_id` (the record key is `class_id` because `class` is reserved in GDScript; the form label is "Class")
- Options: the starting classes in §5. A choice is required.
- On set or change: call `apply_class_gear()`. This replaces starter gear with the kit for the new class. It does not keep the old class's items.
- The review shows the kit name (for example, "Traveler's Outfit") and the items by slot.
- Next: a listed class is required, and gear must have been applied.
- Back: to Step 5.

### Step 7 — Your start

This is the "Pick my start" trio: place, family, and job, on one page so it stays easy on a phone.

- Fields: `place`, `family`, `job`
- Town is Port Paradise for this proof of concept (`arrived_town`).
- **Place** (landmarks Blake named in the first town, plus the arrival dock):
  - `arrival_dock` — "Arrival dock" (default; the boat lands here)
  - `market` — "The market"
  - `high_tavern` — "High-class tavern"
  - `low_shack` — "Low-class shack"
  - `cargo_docks` — "Cargo docks"
  - `monolith` — "The ancient stone monolith"
  - `governors_mansion` — "Governor's mansion"
- **Family** (no family list is in the docs; these are **[PLACEHOLDER]** except the default):
  - `traveling_alone` — "Traveling alone" (default)
  - `dock_family` — "A dock family" **[PLACEHOLDER]**
  - `trade_family` — "A trading family" **[PLACEHOLDER]**
  - `town_family` — "A town family" **[PLACEHOLDER]**
  - `monk_family` — "A monk family" **[PLACEHOLDER]** (monks are mentioned in the voice-call lore)
- **Job** (no starting-job list is in the docs; these are **[PLACEHOLDER]** except the default):
  - `new_arrival` — "New arrival (no job yet)" (default)
  - `dock_worker` — "Dock worker" **[PLACEHOLDER]**
  - `trader` — "Trader" **[PLACEHOLDER]**
  - `farm_helper` — "Farm helper" **[PLACEHOLDER]**
  - `temple_helper` — "Temple helper" **[PLACEHOLDER]**
- Town roles Blake named (tax collector, bandit, smuggler, pirate, gambler, governor, and later King or Queen) are **not** starting jobs. They belong on the role ladder, which a character can climb after arrival.
- Next: all three fields must be on their lists.
- Back: to Step 6.

### Step 8 — Review and sign

This is the arrival-papers sheet.

- Shows every field, the starting-gear kit, and a short slot list.
- Actions:
  - **Back** — to Step 7 (or to any line's step, if the arrow buttons are used). Allowed until the form is signed.
  - **Change a line** — jump to that step, then return here. If class changes, gear is applied again.
  - **Random start / Roll again** — fills every field again, including name, and reapplies gear. `start_mode` becomes `random`.
  - **Sign and Stamp** — runs full validation. If it passes, the record is marked `signed: true` and is ready to enter town. If it fails, show the simple error lines and stay here.
- After signing, the record is locked for this arrival. Later games can still switch to this character, because every character uses the same model (§8).

---

## 3. Validation and back / next rules (summary)

- Next is blocked until the current step is valid.
- Back is allowed from Step 2 through Step 8. From Step 1, Back leaves without saving.
- Jump-from-review is allowed to any earlier step while the form is unsigned.
- Signing requires the whole record to be valid, not just the last step.
- A name is invalid if it is empty, too long, has disallowed characters, or contains the house-forbidden number.
- People, gender, class, voice, appearance subfields, place, family, and job must be ids from the lists above.
- Class gear must use only slot names from `/workspace/casa-game/equipment_slots.json`. Unknown slots are an error.
- No generated id may contain the house-forbidden number. If a roll would create one, roll again.
- Simple player messages:
  - "Please type a name."
  - "Please use letters, spaces, hyphens, or apostrophes only."
  - "That name can't be used. Please pick another."
  - "Please pick your people."
  - "Please pick a gender."
  - "Please finish how you look and sound."
  - "Please pick a class."
  - "Please pick your place, family, and job."
  - "Please look over your papers, then sign."

---

## 4. How Random start fills every field

`ArrivalForms.randomize()` builds a fresh unsigned record and fills:

| Field | How it is filled |
|---|---|
| `start_mode` | `random` |
| `name` | One name from the **[PLACEHOLDER]** name list in the script (short, original names; no family names, and no Elder Scrolls-style names) |
| `race` | Any people id from the list in §6, including placeholder-named peoples |
| `gender` | `male` or `female` |
| `appearance` | Each subfield rolled from its list |
| `voice` | Rolled from the placeholder voices |
| `class_id` | Rolled from the starting classes in §5 |
| `place`, `family`, `job` | Rolled from their lists (defaults are included in the roll) |
| `arrived_town` | `Port Paradise` |
| `equipment`, `kit_name`, `robe_over_armor` | From `apply_class_gear()` |
| `stats` | Health 100, mana 100 (same as the current prototype) |
| `faction` | Empty string **[PLACEHOLDER]** |
| `reputation` | Empty map **[PLACEHOLDER]** |
| `role_ladder` | `current_role` starts as the class label (or the job, if the job is not "New arrival"); `history` starts empty |
| `is_playable` | Always true |
| `id` | A fresh id that does not contain the house-forbidden number |
| `signed` | false, until Sign and Stamp |

The player can roll again from the review sheet. Each roll replaces the whole record (a new id too).

---

## 5. Starting classes

Used as starting classes (already in the design docs):

| Id | Label | Why it's on the list |
|---|---|---|
| `pilgrim` | Pilgrim | Blake added Pilgrim and Merchant as classes (8:12 PM CT, Nov 9). |
| `merchant` | Merchant | Same update. |
| `mage` | Mage | Classic Mages Guild path. The world also names sages, wizards, warlocks, and shamans; those are related roles, not extra starting classes yet. |
| `fighter` | Fighter | Classic Fighters Guild path. |
| `thief` | Thief | Classic Thieves Guild path. |
| `assassin` | Assassin | Classic Assassins Guild path (Blood Cloak is the guild's signature name, not the class name). Kid mode: sneak and tag, no killing. Starter gear follows that. |
| `rogue` | Rogue | Named as a class in the class-crosshair talk, with Blake's game-only crosshair exception. |
| `vampire` | Vampire | Blake confirmed Vampire as a playable class (2026-11-10). Vampire is also still a people. The starter kit is all-ages: a coat, a cane, and a family ring. No blood or gore items. |

Any class can later rise to King or Queen. That is a role-ladder destination, not a starting class.

**Not starting classes in this version:** Sage, Wizard, Warlock, Shaman, Ranger (Ranger appears only in an agent-made crosshair draft), Spellsword (mockup only, not ours), Gambler, Governor, King, Queen (roles you can become). Ork trooper kits (modern armor, battle armor, or armorless barbarian with an axe) are people kits, not class kits; a later pass may layer them on an Ork character. **[PLACEHOLDER]**

Guild membership is not chosen on the arrival forms. A new arrival can join a guild later.

---

## 6. Peoples (races)

From Blake's voice-call lore (Nov 9, 8:17 PM CT), the first-town list (Nov 10, 1:06 AM CT), and "vampires and humans" in the same call. Elder Scrolls race names (Breton, Redguard, Dark Elf, and so on) are influence only and are not options.

| Id | Label | Notes |
|---|---|---|
| `human` | Human | Named with vampires in the power struggle. |
| `nordic` | Nordic | Voice-call peoples list. |
| `gray_alien` | Gray Alien | Voice-call list. |
| `alien` | Alien | Listed separately from gray aliens; the difference is still open. |
| `elf` | Elf | First-town peoples list. |
| `ork` | Ork | Blake's spelling. Also the starship troopers. |
| `dragon` | Dragon | Colonies; helpers with fairies. |
| `fairy` | Fairy | In the town list. The lore bible still asks whether fairies are a people or creatures. Included here, with that question still open. |
| `vampire` | Vampire | A people, and also a confirmed starting class (2026-11-10). |
| `werewolf` | Werewolf | Live in the wilderness. |
| `demon` | Demon | Voice-call list. |
| `lich` | Lich | Voice-call list. |
| `entity` | Entity | Voice-call list. |
| `soul` | Soul | Voice-call list. |
| `spirit` | Spirit | Voice-call list. |
| `krishna_like` | Krishna-like people | **[PLACEHOLDER name]** Blake's description. The original in-game name is not yet chosen. Do not ship this label as the final name. |
| `ganesh_like` | Ganesh-like people | **[PLACEHOLDER name]** Same as above. |

Bugs are invaders, not a starting people.

---

## 7. Class-to-gear table (short form)

Full items and stats: `/workspace/casa-game/godot/data/starting_gear.json`. Every class also gets the common under-layers: Plain Undershirt, Plain Underclothes, Wool Socks. Only slot names from `equipment_slots.json` are used. No eye-named items. The house-forbidden number is not used.

| Class | Kit name | What they get (besides the under-layers) |
|---|---|---|
| Pilgrim | Traveler's Outfit | Traveler's Hood, Travel Shirt, Simple Robe (worn over clothes), Dust Cloak, Travel Pants, Walking Shoes, Worn Belt, Travel Pouch, Path Charm, Walking Staff |
| Merchant | Trader's Outfit | Merchant Tunic, Market Cloak, Town Pants, Town Shoes, Merchant Belt, Coin Pouch, Fair Deal Ring, Measuring Stick |
| Mage | Apprentice Outfit | Student's Hood, Apprentice Robe, Study Cloak, Soft Tights, Soft Shoes, Cloth Belt, Herb Pouch, Light Charm, Practice Staff |
| Fighter | Training Outfit | Iron Cap, Training Shirt, Practice Mail, left and right Training Bracers, Training Pants, Sturdy Boots, Wide Belt, Practice Sword, Wooden Shield |
| Thief | Soft-Shoe Outfit | Soft Hood, Dark Tunic, Quiet Cloak, left and right Soft Gloves, Soft Tights, Soft Shoes, Thin Belt, Hide Pouch, Short Blade |
| Assassin | Quiet Outfit | Shadow Hood, Dark Shirt, Night Cloak, left and right Quiet Gloves, Soft Tights, Soft Shoes, Thin Belt, Hide Pouch, Tag Stick (sneak and tag, kid-safe) |
| Rogue | Rover's Outfit | Rover's Hood, Rover's Tunic, Rover's Cloak, left and right Worn Gloves, Travel Pants, Soft Boots, Worn Belt, Hide Pouch, Short Blade |
| Vampire | Evening Outfit | High-Collar Coat (robe slot, worn over clothes), Dark Shirt, Night Cloak, left and right Fine Gloves, Town Pants, Polished Shoes, Fine Belt, Coin Pouch, Family Crest Ring, Walking Cane (a cane, not a weapon) |

Empty slots stay empty. If a kit includes a robe, `robe_over_armor` is set from the kit (true for Pilgrim, Mage, and Vampire; the Vampire coat uses the robe slot, because there is no separate coat slot). Fighters start with mail, not a robe.

---

## 8. The shared character model (every person is playable)

Blake's rule as of Nov 10, 1:06 AM CT replaces the older single-hero rule: you can switch to any character at any time, and you can interact with any of them. Example: play a gambler who becomes famous and then governor, then switch to an assassin who takes him out.

So the arrival-form record **is** the character model. NPCs are created with the same dictionary, even if they never walk through the forms. Fields:

- Identity: `id`, `name`, `race`, `gender`, `appearance`, `voice`, `class_id`
- Start: `start_mode`, `place`, `family`, `job`, `arrived_town`
- Body and kit: `equipment` (every paper-doll slot, or null), `kit_name`, `robe_over_armor`
- Play: `is_playable` (always true), `stats` (health and mana for now; a fuller stat list is **[PLACEHOLDER]**)
- World standing: `faction` **[PLACEHOLDER]**, `reputation` **[PLACEHOLDER]**, `role_ladder` (`current_role` plus `history`, so a person can go from gambler to famous to governor, or from any class to King or Queen)
- Forms: `signed` (true after arrival papers are stamped, or true for NPCs who already live in town)

When the player switches characters, the game loads this record and shows that person's body, gear, and role. The town keeps going while a character is not being played.

---

## 9. Code hooks and limits

- Logic only: `res://scripts/arrival_forms.gd` (`class_name ArrivalForms`). No UI nodes, no art, no export edits.
- `main.gd` may have a commented hook only. Do not turn creation on in the live prototype from this pass.
- Visuals (the office, the paper, the doll on the stand) stay with Theatron.
- Compatibility / web-safe: plain GDScript, no threads, gear loaded from `res://data/starting_gear.json`.
- The fill method is named `randomize()`. Inside this class it must be called as `self.randomize()`, so it is not confused with Godot's global seed function.

---

## 10. Open items for Blake (not guessed here)

- Final names for the Krishna-like and Ganesh-like peoples.
- Whether fairies are a people or creatures.
- How "Alien" and "Gray Alien" differ.
- Whether Rogue stays a starting class beside Thief and Assassin.
- Gender options beyond Male and Female.
- Finished appearance sliders, voice set, family names, and job list.
- The first word in the town name ("___ Port Paradise").
- The world's name, and the 15-year notebooks still to come.
