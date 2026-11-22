extends RefCounted
## The shared world every hero lives in: villages that grow into towns, one
## family religion, and alliances with procedurally made factions. Plain words,
## kid-safe, and no forbidden triple-six run in any number or name.

const COST := {"village": 20, "hall": 25, "home": 10, "market": 30, "shrine": 20}
const TOWN_POP := 25
const VIRTUES := ["Kindness", "Courage", "Honesty", "Patience", "Sharing", "Joy"]
const BLESSINGS := {
	"light": {"name": "Blessing of Light", "help": "Lux costs half the mana."},
	"luck": {"name": "Blessing of Luck", "help": "+1 on every dice roll."},
	"coin": {"name": "Blessing of Coins", "help": "+2 coins each time a foe runs home."},
	"heal": {"name": "Blessing of Health", "help": "Health comes back twice as fast."}
}
const FAITH_A := ["Way", "Circle", "Order", "Song", "Path", "Lantern", "Hearth", "Harbor"]
const FAITH_B := ["the Dawn", "the Tide", "the Kind Sun", "Still Water", "the Open Hand", "the Golden Bell", "the Morning Star", "the Gentle Wind"]
const VILLAGE_A := ["Oak", "Mill", "Briar", "Stone", "Honey", "Willow", "Lark", "Copper", "Amber", "Fern", "Thistle", "Clover"]
const VILLAGE_B := ["brook", "ford", "field", "hollow", "ridge", "haven", "dale", "wick", "stead", "glen"]
const FACTION_A := ["River", "Hill", "Lantern", "Salt", "Meadow", "Pine", "Copper", "Thunder", "Moon", "Harvest"]
const FACTION_B := ["Otters", "Shepherds", "Tinkers", "Rangers", "Weavers", "Bakers", "Riders", "Fiddlers", "Beekeepers", "Sailors"]
const MOODS := [
	{"mood": "friendly", "need": 8}, {"mood": "careful", "need": 12}, {"mood": "proud", "need": 15}
]
const PERKS := [
	{"id": "coins", "name": "Trade Road", "help": "+2 coins when a foe runs home."},
	{"id": "guard", "name": "Night Watch", "help": "Night creatures stay farther away."},
	{"id": "luck", "name": "Lucky Charm", "help": "+1 on dice rolls."},
	{"id": "grow", "name": "Helping Hands", "help": "Your villages grow faster."},
	{"id": "arrows", "name": "Fletchers", "help": "Arrows cost less."}
]

var seed_value := 1
var villages: Array = []   # {name, x, z, pop, gold, hall, homes, market, shrine, tier}
var religion: Dictionary = {}   # {name, virtue, blessing, followers}
var factions: Array = []   # {name, mood, need, rep, allied, perk, asked_day}
var last_day := 1
var rng := RandomNumberGenerator.new()


static func n(v: int) -> String:
	return TavernSafe.number_text(v)


static func clean(s: String) -> String:
	if TavernSafe.contains_forbidden(s):
		return s.replace("6".repeat(3), "6 6 6")
	return s


func setup(seed_in: int) -> void:
	seed_value = seed_in
	rng.seed = seed_in
	if factions.is_empty():
		_make_factions()


func _make_factions() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value + 17
	var used := {}
	while factions.size() < 5:
		var a: String = FACTION_A[r.randi() % FACTION_A.size()]
		var b: String = FACTION_B[r.randi() % FACTION_B.size()]
		if used.has(a) or used.has(b):
			continue
		used[a] = true
		used[b] = true
		var nm := "%s %s" % [a, b]
		var m: Dictionary = MOODS[r.randi() % MOODS.size()]
		var p: Dictionary = PERKS[factions.size() % PERKS.size()]
		factions.append({"name": "The " + nm, "mood": m["mood"], "need": int(m["need"]), "rep": 0,
			"allied": false, "perk": p["id"], "asked_day": 0})


func village_name(r: RandomNumberGenerator) -> String:
	return VILLAGE_A[r.randi() % VILLAGE_A.size()] + VILLAGE_B[r.randi() % VILLAGE_B.size()]


func faith_name(r: RandomNumberGenerator) -> String:
	return "The %s of %s" % [FAITH_A[r.randi() % FAITH_A.size()], FAITH_B[r.randi() % FAITH_B.size()]]


# ------------------------------------------------------------------ villages

func nearest_village(x: float, z: float, within := 14.0) -> int:
	var best := -1
	var bd := within
	for i in villages.size():
		var v: Dictionary = villages[i]
		var d := Vector2(float(v["x"]) - x, float(v["z"]) - z).length()
		if d < bd:
			bd = d
			best = i
	return best


func can_found_at(x: float, z: float) -> String:
	if absf(x) < 50.0 and z < 42.0:
		return "Walk out past the city into the open land to found a village."
	if nearest_village(x, z, 30.0) >= 0:
		return "Too close to another village. Walk a bit farther."
	return ""


## Bank is passed in so founding pays from the purse (never blocks with shame).
func found_village(bank, name: String, x: float, z: float) -> Dictionary:
	var why := can_found_at(x, z)
	if why != "":
		return {"ok": false, "msg": why}
	if bank.purse < COST["village"]:
		return {"ok": false, "msg": "A village needs %s coins to start. You have %s. Pop bugs or scare off night creatures to earn more." % [n(COST["village"]), n(bank.purse)]}
	bank.spend(COST["village"], "founded %s" % name)
	var v := {"name": clean(name), "x": x, "z": z, "pop": 5, "gold": 0, "hall": false, "homes": 0,
		"market": false, "shrine": false, "tier": "Village"}
	villages.append(v)
	return {"ok": true, "msg": "You founded %s! Five settlers moved in. Build a hall, homes, a market, and a shrine." % v["name"], "index": villages.size() - 1}


func build(bank, i: int, what: String) -> Dictionary:
	if i < 0 or i >= villages.size():
		return {"ok": false, "msg": "Stand in one of your villages to build."}
	var v: Dictionary = villages[i]
	if what in ["hall", "market", "shrine"] and bool(v[what]):
		return {"ok": false, "msg": "%s already has a %s." % [v["name"], what]}
	if what == "home" and int(v["homes"]) >= 8:
		return {"ok": false, "msg": "%s has all the homes it has room for." % v["name"]}
	var cost: int = COST[what]
	var from_gold := mini(cost, int(v["gold"]))
	var need := cost - from_gold
	if bank.purse < need:
		return {"ok": false, "msg": "That costs %s coins. The village has %s and your purse has %s. Earn a few more and come back." % [n(cost), n(int(v["gold"])), n(bank.purse)]}
	v["gold"] = int(v["gold"]) - from_gold
	if need > 0:
		bank.spend(need, "built a %s in %s" % [what, v["name"]])
	if what == "home":
		v["homes"] = int(v["homes"]) + 1
		v["pop"] = int(v["pop"]) + 3
	else:
		v[what] = true
		v["pop"] = int(v["pop"]) + 2
	var grew := _check_town(v)
	var msg := "Built a %s in %s!" % [what, v["name"]]
	if grew:
		msg += " %s is now a TOWN!" % v["name"]
	return {"ok": true, "msg": msg, "town": grew}


func _check_town(v: Dictionary) -> bool:
	if v["tier"] == "Village" and int(v["pop"]) >= TOWN_POP and bool(v["hall"]) and bool(v["market"]):
		v["tier"] = "Town"
		return true
	return false


func collect(bank, i: int) -> String:
	if i < 0 or i >= villages.size():
		return "Stand in one of your villages to collect."
	var v: Dictionary = villages[i]
	var g := int(v["gold"])
	if g <= 0:
		return "%s's chest is empty today. It fills up each morning." % v["name"]
	v["gold"] = 0
	bank.earn(g, "gifts from %s" % v["name"])
	return "%s sent you %s coins. Thank you, founder!" % [v["name"], n(g)]


# ------------------------------------------------------------------ religion

func found_religion(name: String, virtue: String, blessing: String) -> Dictionary:
	if not religion.is_empty():
		return {"ok": false, "msg": "Your family already follows %s." % religion["name"]}
	if not BLESSINGS.has(blessing):
		blessing = "light"
	religion = {"name": clean(name), "virtue": virtue, "blessing": blessing, "followers": 3}
	return {"ok": true, "msg": "%s is founded! Its virtue is %s. %s: %s" % [religion["name"], virtue, BLESSINGS[blessing]["name"], BLESSINGS[blessing]["help"]]}


func has_blessing(id: String) -> bool:
	return not religion.is_empty() and str(religion.get("blessing", "")) == id


func shrines() -> int:
	var c := 0
	for v in villages:
		if bool(v["shrine"]):
			c += 1
	return c


# ------------------------------------------------------------------ alliances

func has_perk(id: String) -> bool:
	for f in factions:
		if bool(f["allied"]) and str(f["perk"]) == id:
			return true
	return false


func perk_info(id: String) -> Dictionary:
	for p in PERKS:
		if p["id"] == id:
			return p
	return PERKS[0]


func luck() -> int:
	return (1 if has_blessing("luck") else 0) + (1 if has_perk("luck") else 0)


## Offer an alliance. Dice: d20 + your Heart bonus + reputation/5 vs their need.
func offer_alliance(dice, i: int, heart_bonus: int, day: int) -> Dictionary:
	var f: Dictionary = factions[i]
	if bool(f["allied"]):
		return {"ok": false, "msg": "%s are already your friends." % f["name"]}
	if int(f["asked_day"]) == day:
		return {"ok": false, "msg": "%s are still thinking. Ask again tomorrow." % f["name"]}
	f["asked_day"] = day
	var bonus := heart_bonus + int(f["rep"]) / 5 + luck()
	var c: Dictionary = dice.check(bonus, int(f["need"]), "Alliance with " + str(f["name"]))
	if c["win"]:
		f["allied"] = true
		var p := perk_info(str(f["perk"]))
		c["msg"] = "%s said YES! Allies now. %s: %s" % [f["name"], p["name"], p["help"]]
	else:
		f["rep"] = int(f["rep"]) + 5
		c["msg"] = "%s said not yet, but they like you more now. Try again tomorrow." % f["name"]
	return c


func raise_rep(amount: int) -> void:
	for f in factions:
		f["rep"] = mini(100, int(f["rep"]) + amount)


# ------------------------------------------------------------------ daily sim

func on_day(day: int) -> String:
	if day <= last_day:
		return ""
	var news: Array = []
	while last_day < day:
		last_day += 1
		for v in villages:
			var room := 5 + int(v["homes"]) * 5 + (10 if bool(v["hall"]) else 0)
			var grow := 1 + int(v["homes"]) + (2 if has_perk("grow") else 0)
			v["pop"] = mini(room, int(v["pop"]) + grow)
			v["gold"] = int(v["gold"]) + int(v["pop"]) / 2 + (10 if bool(v["market"]) else 0)
			if _check_town(v):
				news.append("%s grew into a TOWN!" % v["name"])
		if not religion.is_empty():
			religion["followers"] = int(religion["followers"]) + 1 + shrines() * 3
	if not villages.is_empty():
		news.append("Your villages grew and filled their chests.")
	return " ".join(news)


func to_dict() -> Dictionary:
	return {"seed": seed_value, "villages": villages, "religion": religion, "factions": factions, "last_day": last_day}


func from_dict(d: Dictionary) -> void:
	seed_value = int(d.get("seed", seed_value))
	villages = d.get("villages", [])
	religion = d.get("religion", {})
	factions = d.get("factions", [])
	last_day = int(d.get("last_day", 1))
	for v in villages:
		for k in ["pop", "gold", "homes"]:
			v[k] = int(v.get(k, 0))
	setup(seed_value)
