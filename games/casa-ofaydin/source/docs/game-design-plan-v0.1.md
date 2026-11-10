# Casa O'Faydin Game — Design Plan v0.1 (draft, 2026-11-09)
Lead: Agon. Status: DRAFT. Blake's 15-year world lore comes first and overrides anything here.

## Vision (Blake's words, summarized)
Old-school KOTOR-style RPG on phones first. Low-poly, beautiful, clearly a game world, never uncanny.
Sages, mages, wizards AND starships/capital ships (Event Horizon / Aliens meets Lord of the Rings).
Dragon colonies invaded by xenomorph-like bugs; ork "starship troopers" (modern armor, battle armor, or
armorless axe barbarians) fight the bugs together. Fairies refill mana and health. Day/night cycle.
Sleep is fun: steer your dreams, astral projection. Farming and planting (Minecraft / Crimson Desert).
Daggerfall-style random generation. Baldur's Gate 3-style open choices. Fun for ages 7 to 90.
The world should feel lived-in, with all the best parts and none of the worst.

## Platform & engine
- Engine: Godot 4 (free, exports to Android/iOS; Xbox/VR later).
- Target: mid-range phones, 30+ fps, low-poly models, baked lighting, small textures.
- Controls: one-thumb friendly, big buttons, optional auto-aim. Readable text size for older eyes.

## First playable phone version (Milestone 1)
1. One small dragon colony map with a day/night cycle.
2. Player: health bar plus mana bar. One spell, one weapon.
3. Fairies drift in and refill health and mana.
4. Bug wave attack; 3 ork trooper allies (armored, battle armor, barbarian).
5. One choice with 2 outcomes (help a dragon elder or chase the bug queen).
6. Sleep in a bed and enter one steerable dream area (fly, collect lights). Fiat Lux.
7. One garden plot: plant, wait a day, harvest.
Success = Odin (9), Fae (7) and Nana can each play 10 minutes and want more.

## Later milestones
M2 random generation of villages and caves. M3 starship travel and a capital ship hub. M4 deeper choices,
companions, factions. M5 more platforms (tablet, Xbox, VR).

## Safety & tone
Kid-safe: no gore, bugs pop into light instead of blood. No pushy buying. No the house-forbidden number, no eye imagery.

## Owners
Art style: Theatron. Music/voice: Rhapsodos. Kid fun & safety: Paidagogos. Dev log: Ephemeris.
Lore bible: Chronographos. Budget/money: Logistes. World archive: Mneme. Play breaks: Gymnastes.
Build help: Architekton (when Blake's ready).

## Open questions for Blake
- World name, main races and places from his lore.
- Who is the player character?

## Update 2026-11-09 8:10 PM — Guilds, languages, story engine (from Blake)
### Four classic guilds (copyright-free Latin/Greek names, draft)
- Mages Guild: Magoi (Greek Μάγοι, "the wise ones")
- Fighters Guild: Hoplitai (Greek Ὁπλῖται, "armored soldiers")
- Thieves Guild: Kleptai (Greek κλέπται, "thieves")
- Assassins Guild: Umbrae (Latin, "the shadows"). Kid mode: sneak and tag, no killing.
### Learn real languages by playing
Every guild, spell, and place teaches a real word: Latin, Greek, Aramaic, Sanskrit, Arabic.
Starter words: Lux (Latin, light; casts light), Sophia (Greek, wisdom), Abba (Aramaic, father),
Dharma (Sanskrit, right path), Salaam (Arabic, peace). Paidagogos checks every word with a source.
### Endless story generator
Backbone: the hero's journey (call, helper, trial, darkest moment, return home changed).
Fillers: public-domain fables, parables, Buddhist koans, Aesop, Jataka tales, Arabian Nights.
Family-sitcom story shapes (birthday surprise, a new kid joins the family, a big mix-up) are used as
shapes only. No copyrighted shows, characters, or scenes.

## Update 2026-11-09 — Guild name generator + timeline (from Blake)
- Every new world rolls new guild names, always tagged with the plain label, e.g. "The Blood Cloak (Assassins Guild)".
- "Blood Cloak" is the signature name in the assassin word list. Prototype: /workspace/casa-game/guild_names.py
- One world clock: day/night cycle plus a running calendar (day, season, year). Events, guild history,
  and story beats are stamped on the timeline in order, so every world has its own chronicle.

## Update 2026-11-09 — Three-way world: magic + industrial sci-fi + cyberpunk (from Blake)
Healing has three equal paths, so every player finds their style:
- Magic: sages, shamans, wizards heal with spells (uses mana).
- Science: healing tanks in med bays and on starships (uses credits or time).
- Herbs: grow and brew them on your farm (uses plants you planted).
Cloning labs sit beside warlock towers; tanks and capital ships beside dragons and guild halls.
Cyberpunk neon cities live alongside old villages. Magic and science both work, and neither one wins.
Lore source: Blake's notebooks, pictures, and artwork (photos to Mneme when he has them).

## Update 2026-11-09 — One hero, companions, camera (from Blake)
- The game follows ONE main character. Companions join along the way (KOTOR / Baldur's Gate style),
  each with their own story, opinion of your choices, and loyalty quest.
- Milestone 1 change: the ork troopers become your first companion (one ork who chooses to follow you).
- Camera: one tap on an on-screen camera button switches between first person and third person, anytime.
- Smart camera (Blake, 8:09 PM): each weapon and spell has a best view. With Auto Camera on (the default),
  the view switches when you equip it; the one-tap button always overrides.
  - First person: bows, guns, aimed spells (fireball). Swords work in either view.
  - Third person: self and area spells (invisibility, shields, healing) so you can see yourself.
  - Settings let each player turn Auto Camera off.

## Build log 2026-11-09 8:15 PM
Godot 4.3 gray-box prototype at /workspace/casa-game/godot (runs, no script errors).
Has: day/night clock, health and mana bars, one-tap View button, Lux spell button, fairy refill,
bugs that crawl toward the hero, a colony of low-poly towers. Next: Theatron's art, ork companion,
Android export (needs export templates + Android SDK on my computer).

## Update 2026-11-09 8:12 PM — Pilgrim, Merchant, path to King, starts, full outfits (from Blake)
- New classes: Pilgrim and Merchant. Any class can rise through the whole game to become King or Queen.
- Life-story RPG (BitLife-style, but a full world): play from humble start to the throne.
- Start: player chooses either "Pick my start" (place, family, job) or "Random start", like the
  alternate-start mods for Skyrim and Starfield.
- Character creator at Morrowind depth: face, body, race, voice. You always see your hero (third person
  or a mirror) with every item showing.
- Layered equipment: every slot is visible on the body and has stats. Slot list at
  /workspace/casa-game/equipment_slots.json (left and right gloves and pauldrons, undershirt to robe,
  underpants to greaves).
- Easy mode for outfits (Paidagogos): a "Dress Me" button auto-equips the best gear, and a Simple view shows
  5 big slots (head, body, hands, feet, weapon). The full layered view is one tap away.

## Update 2026-11-09, 8:17 PM CT: Blake's world lore from the voice call (🟢 Blake's words)
- Setting: Earth, far in the future. Old relics survive, in the spirit of *A Canticle for Leibowitz* (inspiration only; we use our own names and relics).
- Places: imperial villages and cottages, giant mushrooms, erupting volcanoes, beautiful seascapes with huge imperial harbors and shipbuilding.
- Peoples living together: Nordics, gray aliens, dragons, Krishna-like and Ganesh-like people, demons, aliens, entities, souls, spirits, liches, vampires, werewolves.
- Werewolves live in the wilderness.
- Vampires and humans are in a constant power struggle. Both want to be in charge, and now they know about each other.
- History: the first patriarch or matriarch died, then kingdoms rose. Kingdoms (like an Indian or Chinese kingdom) warred with vampires for thousands of years. The great wall was built to keep vampires out. Vampires stopped at the mountains because they don't like mountains.
- Today, power works like human corporations, the heirs of the old kingdoms.
- Dragons and fairies help the people and the monks.

---

## Update 2026-11-10, 1:06 AM CT: First town and switching characters (Blake, in Theatron's chat)

**Proof of concept is ONE town:** the first town, a busy, backwater harbor port. Blake's words: "Let's start with just one town as a proof of concept."
- **Name idea:** something like "___ Port Paradise", though "it's a trashy place." He called it "port, something port paradise"; the first word is still to be decided.
- **People and creatures:** tax collectors, bandits, smugglers, pirates, spiders, dogs, cats, elves, orks, fairies, and dragons.
- **Landmarks:**
  - cargo cranes and a few neon towers
  - one huge ancient stone monolith from an old culture, "like Helm's Deep"
  - a high-class tavern and a low-class shack, "where the different classes of people meet and drink and trade"
  - the market (the hero spawns here in the build)
  - the governor's mansion
- **Template for later towns:** they keep this basic layout, but each gets its own architecture: Middle Eastern, pirate, Scandinavian Viking, Mongolian, Aztec, Inca, and heavily Native American influenced.
- **Also present:** plastic-armor, stormtrooper-style starship troopers.
- **Plants and animals** can help you or hurt you.

**BIG CHANGE, which replaces the earlier single-hero rule.** You can switch between all of these characters at any time, and you can interact with any of them at any time. Blake's example: "if you want to have a gambler that becomes famous and becomes the governor and then you want to have an assassin that kills him. You can do that."
- **Design note:** every NPC needs to be playable, so they need a shared character model: stats, faction, reputation, and a role ladder (for example, gambler, famous, then governor). Political roles have to be open to any character, and the world state has to keep going while a character isn't being played.

**Graphics:** Blake approved fixing the graphics with no preview ("No, fix the graphics. Now, you don't have to check with me"). The target look is Morrowind: muted, earthy colors, haze, stone towns, arched bridges, lamp posts, layered armor and robes, and small bars in the corner. Theatron is building it in /workspace/casa-game/godot-art (art/town_harbor.gd).

---

## Update 2026-11-10, 1:10 AM CT: GM mode, world builder, and autonomy (Blake, in Theatron's chat)

Blake's words: "There needs to be a world builder like a sim style, and also the characters need to be able to live their own lives with their own autonomy levels set by the player. He's like the g m or the d. M of the session"

**The player is the Game Master (GM).** Three modes, switched at any time:
1. **Play:** be any character. Switch with the Switch button or by tapping a character, then Take Over.
2. **Build:** Sims-style world and town builder. Place, move, and remove buildings, props, plants, and animals, and paint ground and roads. Snap to a grid, with Undo. New towns start from the Port Paradise layout template: docks, market, high-class tavern, low-class shack, governor's mansion, monolith, cranes and neon towers. The builder can swap in a culture style (Middle Eastern, pirate, Viking, Mongolian, Aztec, Inca, Native American, starship).
3. **Watch:** a free camera with time controls (Pause, Play, Fast, Faster), so the town lives on its own.

**Autonomy, set per character by the GM.** It's a 4-step slider, kept simple for ages 7 to 90:
- **Puppet (0):** does nothing unless you control it.
- **Helper (1):** handles needs (eat, sleep, work), but big choices wait for you.
- **Free (2):** lives its own day and makes its own choices, and you can still step in.
- **Wild (3):** full free will. It can chase ambitions (gambler, then famous, then governor), make rivals, and plot.

The GM panel also has a "Whole town" slider that sets everyone's autonomy at once. Under the hood, each character has needs, a daily schedule (home, work, tavern, sleep), goals, and a relationship web. Autonomy decides who picks the next action: the player, a suggestion, or the character itself.

**Ties to other systems:**
- **Seat switching:** a character you leave keeps living at its autonomy level.
- **Tavern tables:** AI seats are just characters at Free or above sitting down to play.
- **Arrival forms:** they create the shared character record every NPC uses.
- **Proof of concept:** Port Paradise only. Build mode starts with placing props in that town.

---

## Update 2026-11-10, 1:10 to 1:11 AM CT: Port Paradise is a big multicultural port (Blake, via Theatron)

- **A multicultural city like Houston or New York.** The market has dozens of languages spoken at once, like the Saint Denis market in RDR2. Hook: the market chatter can tie into Paidagogos's language lessons and Rhapsodos's voices.
- **Harbor traffic:**
  - sailing ships
  - starships on landing pads
  - giant floating barges
  - steamboats
- **Deadline from Blake (1:11 AM):** "I want to wake up in the morning and be able to walk around in it." He already approved the graphics with no preview, so the Port Paradise art pass goes live by morning at https://dynamisblake.com/games/casa-ofaydin/play/.

---

## Update 2026-11-10, 1:14 AM CT: The core conflict is magic vs. science (Blake, via Theatron)

- **Guild infighting:** the major guilds are always fighting each other for political power.
- **Magic guilds:** they take magic-born children from their families and raise them like monks in a temple order. Blake's word was "cantical," and its meaning isn't settled yet.
- **Non-magic people:** they have to work, but some rise with no magic at all to become engineers, scientists, doctors, starship captains, and astronauts.
- **Travel rivalry:** wizards, warlocks, and witches can travel across the universe instantly, while scientists have built faster-than-light travel.
- **Result:** constant competition between magic and science, which drives politics, careers, and quests.
- **Port Paradise hooks:**
  - guild recruiters in the market
  - a starship captain at the landing pads
  - a mage tower beside the neon towers
  - a recruiter scene where a magic-born child is taken from their family (handled gently for kids)
- **Gameplay tie-in:** any character can pursue the magic path or the science path, which fits the rule that you can switch to any character.

---

## Update 2026-11-10, 1:14 AM CT: Vampires vs. humans, a third rivalry (Blake, via Theatron)

Blake's words: "Let's do the vampire human drama too."
- **Three rivalries now:**
  1. guild infighting
  2. magic vs. science
  3. vampires vs. humans
- **Builds on the canon from the voice call:**
  - vampires are in a constant power struggle with the humans
  - human corporations run by heirs after the original patriarch or matriarch died
  - the old kingdoms warred with the vampires
  - the great wall was built to keep the vampires out, and it stops at the mountains
  - werewolves live out in the wilderness
- **Vampire is a confirmed playable class.** It already has an approved crosshair.
- **Tone is all ages:**
  - secret clans, old grudges, and taking sides
  - deals and betrayals
  - no gore
- **Port Paradise hooks:**
  - a hidden vampire clan with ties to the high-class tavern or the governor's mansion
  - human corporate guards
  - rumors passed around in the low-class shack
- **Character switching:** you can play both sides. One night you're a vampire, the next you're the human hunter.

---

## Update 2026-11-10, 1:15 AM CT: Banking, interest, and dynasties (Blake, via Theatron)

- **Banking system.** Deposits, loans, and compound interest grow on the world clock, so the money keeps changing while you play.
- **Vampire wealth.** Vampires grow rich on centuries of compound interest because they live so long.
- **Dynasties.** Families, corporations, and royal houses do the same thing across generations. The people change, but the house stays the same.
  - Houses and companies are entities in the game that outlive any one character. They own money, property, and titles, and they have heirs.
  - When a character dies or steps away, their house passes everything to an heir.
- **Old money is the main power.** It ties into vampires versus humans, guild politics, and climbing the ladder to governor.
- **Port Paradise hook:** a bank or counting house near the market and the governor's mansion. Players can make deposits, take loans, and buy shares in companies.
- **Gameplay tie-in:** switching characters lets you play the long game. Build up a family fortune, then play the heir.
- **Design notes:**
  - interest uses simple rates per season or year, with small numbers that are easy to read
  - shown balances round so that the house-forbidden number never appears (house rule)
  - kid mode offers a plain savings jar view

---

## Update 2026-11-10, 1:16 AM CT: Open-ended play, achievements, and home building (Blake, via Theatron)

- **Open-ended like the Sims.** There's no required win state. You play for as long as you like, in whatever way you like.
- **Achievements.** There are lots of them, grouped for easy browsing:
  - **Life:** first home, married, heir born
  - **Wealth:** first deposit, interest milestones, own a company
  - **Power:** join a guild, become governor
  - **Rivalry:** side with the vampires or the humans, pick magic or science
  - **Tavern:** win chess, checkers, and a dominoes game to 100
  - **Explorer:** visit every district of Port Paradise
  - **Builder:** build a shack, then a house, then a manor, then a castle
  - **Kids' achievements** are easy and positive. Achievement counts and points never show the house-forbidden number.
- **Home building in Build mode.** Design your own home at any size, from a peasant shack to a huge castle.
  - **Pieces:**
    - walls, floors, roofs, doors, windows, and stairs, built story by story
    - rooms and furniture
    - gardens, plants, and animals, which can help or hurt you
  - **Tools:** Place, Move, Remove, Paint, Style (swap in a culture's style), and Undo, all snapping to a grid
  - **Cost:** building costs money from your house or dynasty bank. Kid mode builds for free.
- **Proof of concept:** one buildable lot in Port Paradise, plus a starter shack you can upgrade.

---

## Update 2026-11-10, 1:16 AM CT: Survival and Creative world modes (Blake, via Theatron)

Blake's words: "think minecraft, survival mode and creative mode."

- **Survival:** you gather and earn materials and money, building costs materials from your house's bank, danger is real, and achievements count.
- **Creative:** you build anything for free with unlimited pieces, from a shack to a castle to whole towns. There's no danger, and achievements don't count.
- **How it fits:** you pick the world mode when you start a new world, and the GM can switch it later. The Play, Build, and Watch tabs work in both modes. Kid mode defaults to Creative.

---

## Update 2026-11-10, 1:17 AM CT: Found towns, grow kingdoms, and write constitutions (Blake, via Theatron)

- **Found a town.** Any player character can claim land and found a town. You build it in Build mode, and it costs materials in Survival but is free in Creative.
- **Growth ladder:** camp, then village, then town, then city, then kingdom. Each step unlocks new buildings, positions, and achievements.
- **Government and constitution.** The founder writes the town's constitution from simple choices:
  - **Who rules:** a council, a governor, a king or queen, the guilds, or the people voting.
  - **Taxes:** low, medium, or high.
  - **Laws:** magic allowed or limited, vampires welcome or banned, and how open trade is.
  - **How leaders change:** elections, heirs, or the guilds pick them.
  The constitution can be changed later through the government it set up.
- **Trade relations.** Towns trade with each other through trade routes, ships and starships, and tariffs. Your town's prices and wealth feed into the banking and dynasty system.
- **Diplomacy with built-in towns** like Port Paradise:
  - allied, friendly, neutral, rival, or at war
  - treaties
  - guild politics and the vampire-versus-human sides shift these relations
- **Ties to other systems:**
  - you can switch characters to play a founder, a rival governor, or a smuggler who breaks the treaty
  - characters on autonomy can run your town while you're away
- **Proof of concept:** one buildable lot outside Port Paradise, which can grow into a camp and then a village, plus one trade route.

---

## Update 2026-11-10, 1:17 AM CT: War has many paths (Blake, via Theatron)

- **Ways to take part in a war:**
  - **Commander:** raise and lead an army into battle.
  - **Merchant:** sell everything the war needs, like food, horses, ships, and supplies.
  - **Blacksmith or crafter:** make the weapons, armor, and materials.
  - Also open: smuggler, spy, healer or doctor, starship captain running supplies, and banker making war loans.
- **The war economy:**
  - War creates real demand, so prices for weapons, armor, and supplies go up.
  - Crafting and trade careers pay off, and banks make loans to the kingdoms at war.
  - Peace brings demand back down.
- **Switching characters:** you can play every side of the same war, such as the general, the merchant selling to both sides, and the blacksmith.
- **Kid mode:** battles are shown as strategy and outcomes, with no gore.
- **Proof of concept:** one trade-war scenario between Port Paradise and a rival town, where you can buy and sell weapons and armor at the market and a blacksmith shop.

---

## SCOPE LOCK and phased roadmap (decided 2026-11-10, 1:18 AM CT)

Blake's rule: "we have to watch out for feature creep, and we have to save memory, and we can't do too much in the game."
Every idea from tonight stays in this plan, but it gets built only in its phase. **Nothing from a later phase starts until the phase before it is playable and live.**

**NPC life, inspired by Radiant AI but tamed:**
- **Needs:** just three, food, shelter, and money.
- **Jobs:** a short list: chop trees, fish, farm, trade, work at the tavern, and work as a guard.
- **Order of choices:** honest work comes first. Theft or robbery happens only at the Wild autonomy level, and only after honest options fail.
- **Level of detail:**
  - Characters near the player get full simulation.
  - Characters far away get one cheap dice roll per game day that decides their results: money, mood, and moving house.
- **Founding towns:** NPC-founded towns are a later-phase event that can happen at most rarely, not a simulation running all the time.
- **Memory and limits:**
  - a cap on fully simulated characters at once (start at 24)
  - object pooling
  - nothing simulated that's off-screen and far away

**Phases:**
- **Phase 0, now (morning of 11/10):** walk around Port Paradise on the web, with Theatron's art.
- **Phase 1, core loop:**
  - the arrival-forms character creation
  - switching characters
  - the Puppet, Helper, Free, and Wild autonomy levels
  - the three needs and the short job list
  - tavern games: chess, checkers, and dominoes
  - Port Paradise only
- **Phase 2, economy:**
  - market buying and selling
  - simple bank deposits and interest
  - houses and dynasties as heirs
  - a few achievements
- **Phase 3, building:**
  - Build mode for one lot, from a shack up to a castle
  - Creative and Survival modes
  - Style swaps
- **Phase 4, politics:**
  - guilds and the three rivalries in quests
  - a governor ladder
  - one trade route to a second town
- **Phase 5, big systems:**
  - founding towns, kingdoms, and constitutions
  - diplomacy, war, and armies, plus the war economy
  - more towns in each culture's style
  - NPC-founded towns

**Rules:**
- New ideas go into the phase list. They don't go into the current build.
- Each phase ships at 100 percent before the next one starts. Ship, reflect, remeasure, and improve.

---

## Phase 1 addition (2026-11-10, 1:19 AM CT): The opening quest line in Port Paradise (Blake, via Theatron)

The opening quest line follows the style of Morrowind's Seyda Neen opening. Every beat is our own version. We copy no names, text, or quests. Chronographos will write the lore and names.

1. **Arrival:** you arrive by boat, step onto the dock, and do your papers at Census & Customs, which are the arrival forms.
2. **First easy quest:** a nervous local has lost a ring. Finding it teaches you to talk, search, and get a reward.
3. **First mystery:** a tax collector has gone missing. This ties into Blake's tax collectors and the guild politics. For kids it stays a "missing" mystery, and for older players it can be a murder, with no gore either way.
4. **Smugglers' cave:** just outside town. It's the first danger and the first loot, and it hooks into the smugglers and the bank's old money.
5. **Leads:** the tavern keeper (high-class or the shack) and a lighthouse keeper point you along.

**Scope for Phase 1:** dialogue is simple and uses canned lines, and quest state is a few flags. The quest never forces you to use a particular character.

---

## CORE PILLAR (standing rule, 2026-11-10, 1:20 AM CT): Rivalries and drama first (Blake)

Blake's words: "Always focus on rivalries and dramas."
- **The rule for every phase:** each feature should create or feed a rivalry, a grudge, a betrayal, or an alliance. If a feature makes no drama, cut it or cut it down.
- **Factions can splinter.** When loyalty drops, a group inside a guild, house, army, or crew can:
  - **split off** and start a new faction
  - **mutiny**, as a ship's crew or an army unit
  - **form a militia**, as townsfolk arming up against a governor, vampires, or a guild
- **Real history is the guide.** Royal drama from history provides the templates: succession fights, rival heirs, regents, usurpers, arranged marriages, exiled princes, palace coups, and civil wars between cousins. Chronographos is pulling the history side.
- **How the phases build up:**
  - Phase 1: tavern rumors, the missing tax collector, and smuggler grudges.
  - Phase 2: inheritance fights in the dynasties, and the bank calling in debts.
  - Phase 4: the full system for splits, mutinies, and militias.
  - Phase 5: civil wars and wars of succession.
- **Kid mode:** the drama comes through choices, sides, and talking, with no gore.

---

## HEADLINE FEATURE (2026-11-10, 1:20 AM CT): Let the sandbox take over (Blake, via Theatron)

Blake's words: "The most fun part for people playing these games is letting the sandbox take over and watch what happens."
- **Watch mode** and the **Whole town** autonomy slider are headline features. Set the town to Free or Wild, hit Fast, and watch the drama happen.
- **Drama log, or "Port Paradise Gazette."** This is a later newsfeed of what happened while you watched: who married, who fought, who got robbed, who rose to power, and which faction split off. It could be written OSN-style by the newspaper desk.
- **Phases:**
  - A basic Watch mode with time controls comes in Phase 1, along with autonomy.
  - The drama log comes in Phase 2.
  - Headlines for mutinies and coups come in Phase 4.

## Tavern games logic done (2026-11-10, 1:41 AM CT)
The rules, AI, and seat manager for chess, checkers, and four-seat dominoes are done in godot/scripts/tavern/, and 42 of 42 headless tests pass. The spec is tavern-games-v0.1.md. Next, Theatron hooks up the UI. These are Phase 1 work.

---

## Update 2026-11-10, evening CT: Minutiae deep dive (Blake, via Agon)

Blake's words: "We've got the skeleton of the game. But now we need to start digging into the minutiae." He asked for trade, buyers, and regions; a way to fund, send someone, and grow more cities; a way to talk to those towns without a politics sim; government, guilds, and legions with Latin name generation; an original lore bible (Elder Scrolls as structure only); and built-in, Sims-style modding, with the source open so people can make mods.

**These are design docs only.** No game code was changed in this pass. The SCOPE LOCK above still rules: every idea gets a tiny phase-first version and a later version, and nothing from a later phase starts until the phase before it is playable and live.

**Docs (all under `/workspace/casa-game/design/`):**

- One-page summary for Blake: `SUMMARY.md`
- Trade, buyers, and regions: `trade-buyers-regions-v0.1.md`
- Founding towns, money, and charters: `founding-towns-v0.1.md`
- Couriers and governor reports: `courier-and-reports-v0.1.md`
- Government, guilds, legions, and the Latin generator spec: `government-guilds-legions-v0.1.md`
- Lore bible (original gods, demigods, clans, and packs): `lore-bible-v0.1.md`
- Modding tools, JSON data, and load order: `modding-tools-v0.1.md`

Latin word lists: `/workspace/casa-game/godot/data/latin_names.json` (data only, no generator script in this pass).

**How each feature maps to a phase:**

| Feature | Phase-first version | Later version |
|---|---|---|
| Trade, buyers, prices | Phase 2: Port Paradise market, eight goods, three buyer types, daily price drift | Phase 4: one ship route to a second town. Phase 5: regions, caravans, ships, and starships |
| Money for a new town | Phase 2: savings, simple bank loan, compound interest once a season | Phase 4: a guild or clan can back you. Phase 5: full shares and called-in debts on a charter |
| Send a founder and grow a town | Phase 3 only has the buildable lot. Phase 5: pick a founder, pack settlers, money, and a one-page charter, then camp to kingdom | More towns, full constitutions, rare NPC-founded towns, cultural style on the Port Paradise layout |
| Talk to towns without politics | Phase 4: courier desk, canned letters, one-page governor report with plain buttons | Phase 5: rival letters, two reports if a town splits, faster starship packets |
| Government offices | Phase 4: Praefectus (Governor), Aedile, Quaestor, and the governor ladder | Phase 5: Consul, Praetor, Tribune, Censor, Proconsul, constitutions |
| Guilds | Phase 4: four classic guilds in quests, rolled names with a plain tag, first splits | Phase 5: more guild types in data, halls in new towns |
| Legions and Latin names | Data and rules can land any time. First use: Phase 4 civic names and offices. A city may host a named cohort only in Phase 5 | Phase 5: `Legio IV Maritima`-style legions, mutiny vexillations, war economy already in the plan |
| Lore (gods, vampires, werewolves, banks) | Phase 1: rumors only. Phase 2: the Harbor Counting House and long-lived depositors. Phase 4: clan hooks in quests | Phase 5: temples, the Wall, packs, and region lore |
| Built-in modding | Phase 2 onward: content in JSON, a `mods/` folder and load order, banned-token checks | Phase 3: lot save files from Build mode. Later: in-game Data Desk and shared packs on the public source page |

New ideas from this deep dive go into the phase list above. They do not go into the current Phase 0 or Phase 1 build.
