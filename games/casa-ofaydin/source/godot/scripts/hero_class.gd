extends RefCounted
## Mage, Thief, Warrior: starting kits, signature moves, and dice-rolled stats.
## Stats are plain words: Might, Sneak, Magic, Heart. Start = d20 + class base.

const STATS := ["might", "sneak", "magic", "heart"]
const STAT_NAMES := {"might": "Might", "sneak": "Sneak", "magic": "Magic", "heart": "Heart"}

const CLASSES := {
	"mage": {
		"name": "Mage", "blurb": "Bolts of fire, frost, and lightning from your fingertips.",
		"move": "Storm", "move_help": "Lightning jumps to every foe near you.",
		"weapon": "staff", "base": {"might": 0, "sneak": 1, "magic": 5, "heart": 2},
		"color": Color(0.36, 0.42, 0.85),
		"gear": {"head": "pilgrim_hood", "shirt": "linen_tunic", "robe": "counting_robe", "pants": "padded_hose",
			"boots": "low_shoes", "belt": "dyed_sash", "amulet": "amber_drop", "ring_l": "sea_glass_ring"},
		"tints": {"robe": "#33407a", "head": "#2b3566", "belt": "#c9a24a"},
		"look": {"hair": "long", "beard": false, "build": "slim"}
	},
	"thief": {
		"name": "Thief", "blurb": "Quiet feet, quick hands, and a crossbow with bone arrows.",
		"move": "Sneak", "move_help": "Fade out so foes lose you. Then Tag someone for coins.",
		"weapon": "crossbow", "base": {"might": 1, "sneak": 5, "magic": 1, "heart": 1},
		"color": Color(0.3, 0.55, 0.35),
		"gear": {"head": "", "shirt": "patchwork_vest", "cuirass": "boiled_leather_jerkin", "pants": "knee_breeches",
			"boots": "fur_lined_boots", "belt": "coin_pouch_belt", "glove_l": "hide_bracer", "glove_r": "hide_bracer",
			"robe": "traveler_cloak"},
		"tints": {"robe": "#2f4a33", "cuirass": "#4a3a2a"},
		"look": {"hair": "crop", "beard": false, "build": "average"}
	},
	"warrior": {
		"name": "Warrior", "blurb": "Sword, shield block, and a mighty charge.",
		"move": "Charge", "move_help": "Rush ahead and bump every foe back.",
		"weapon": "sword", "base": {"might": 5, "sneak": 0, "magic": 0, "heart": 3},
		"color": Color(0.8, 0.35, 0.25),
		"gear": {"head": "bronze_crest_helm", "shirt": "quilted_gambeson", "cuirass": "harbor_plate",
			"pauldron_l": "harbor_plate_pauldron", "pauldron_r": "harbor_plate_pauldron",
			"glove_l": "saltiron_gauntlet", "glove_r": "saltiron_gauntlet", "belt": "plate_war_belt",
			"pants": "dock_trousers", "greaves": "harbor_plate_greaves", "boots": "saltiron_sabatons"},
		"tints": {},
		"look": {"hair": "shag", "beard": true, "build": "broad"}
	}
}

const FIRST := ["Bram", "Tilda", "Oren", "Wren", "Corin", "Mira", "Dax", "Lena", "Finn", "Rosa",
	"Hugo", "Ivy", "Jory", "Nell", "Pip", "Sage", "Toby", "Una", "Vale", "Zeke", "Odessa", "Kip"]
const EPITHET := ["the Brave", "the Kind", "of the Harbor", "Quickstep", "the Bright", "Stormhand",
	"the Bold", "Lightfoot", "the Steady", "of the Hills", "Goldheart", "the Clever"]


static func roll_stats(dice, cls: String) -> Dictionary:
	var base: Dictionary = CLASSES[cls]["base"]
	var rolls := {}
	var stats := {}
	for s in STATS:
		var r: int = dice.d20()
		rolls[s] = r
		stats[s] = r + int(base[s])
	return {"rolls": rolls, "stats": stats}


static func random_name(dice) -> String:
	return "%s %s" % [dice.pick(FIRST), dice.pick(EPITHET)]


## Check bonus from a stat (0..25) plus level: small, readable numbers.
static func bonus(stat_value: int, level := 1) -> int:
	return int(stat_value / 4) + int(level / 10)


static func gear_for(cls: String) -> Dictionary:
	var g: Dictionary = (CLASSES[cls]["gear"] as Dictionary).duplicate()
	for k in g.keys():
		if str(g[k]) == "":
			g.erase(k)
	return g
