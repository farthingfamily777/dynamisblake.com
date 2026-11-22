extends RefCounted
## Every hero Blake makes lives in the same world. Make a new one any time,
## switch who you play, party up (the other follows and fights beside you),
## and give coins or gear between them. Bank savings and the realm are shared;
## each hero carries their own purse, gear, level, and stats.

const HeroClass = preload("res://scripts/hero_class.gd")

var heroes: Array = []
var active := 0
var buddy := -1   # index of the hero following you (-1 = none)
var follow := true


func add_hero(name: String, cls: String, stats: Dictionary, purse := 25) -> int:
	var c: Dictionary = HeroClass.CLASSES[cls]
	heroes.append({"name": name, "cls": cls, "stats": stats.duplicate(), "level": 1, "xp": 0,
		"purse": purse, "gear": HeroClass.gear_for(cls), "weapon": c["weapon"], "arrows": 24,
		"x": 0.0, "z": 0.0})
	return heroes.size() - 1


func cur() -> Dictionary:
	return heroes[active] if active < heroes.size() else {}


func pal() -> Dictionary:
	return heroes[buddy] if buddy >= 0 and buddy < heroes.size() else {}


func stat(s: String) -> int:
	return int(cur().get("stats", {}).get(s, 10))


func bonus(s: String) -> int:
	return HeroClass.bonus(stat(s), int(cur().get("level", 1)))


static func xp_needed(level: int) -> int:
	return 20 + level * 10


## Add xp to a hero. Returns how many levels they gained.
func add_xp(i: int, amount: int) -> int:
	if i < 0 or i >= heroes.size():
		return 0
	var h: Dictionary = heroes[i]
	h["xp"] = int(h["xp"]) + amount
	var ups := 0
	while int(h["level"]) < 99 and int(h["xp"]) >= xp_needed(int(h["level"])):
		h["xp"] = int(h["xp"]) - xp_needed(int(h["level"]))
		h["level"] = int(h["level"]) + 1
		ups += 1
		for s in h["stats"].keys():
			if (int(h["level"]) + s.length()) % 3 == 0:
				h["stats"][s] = int(h["stats"][s]) + 1
	return ups


## Give coins from one hero's purse to another. Purse of the active hero lives in the bank.
func give_coins(bank, to_i: int, amount: int) -> String:
	if to_i < 0 or to_i == active:
		return "Party up with another hero first, then you can give."
	var paid := mini(amount, bank.purse)
	if paid <= 0:
		return "Your purse is empty right now."
	bank.purse -= paid
	heroes[to_i]["purse"] = int(heroes[to_i]["purse"]) + paid
	return "%s gave %s coins to %s." % [cur()["name"], TavernSafe.number_text(paid), heroes[to_i]["name"]]


## Hand one worn gear piece to the buddy (one they are not wearing yet).
func give_gear(to_i: int, my_gear: Dictionary) -> String:
	if to_i < 0 or to_i == active:
		return "Party up with another hero first, then you can give."
	var theirs: Dictionary = heroes[to_i]["gear"]
	for slot in my_gear.keys():
		if not theirs.has(slot):
			theirs[slot] = my_gear[slot]
			my_gear.erase(slot)
			return "%s handed over gear for the %s slot. Looking sharp, %s!" % [cur()["name"], str(slot).replace("_", " "), heroes[to_i]["name"]]
	return "%s already wears something in every slot you have." % heroes[to_i]["name"]


func to_dict() -> Dictionary:
	return {"heroes": heroes, "active": active, "buddy": buddy, "follow": follow}


func from_dict(d: Dictionary) -> void:
	heroes = d.get("heroes", [])
	for h in heroes:
		for k in ["level", "xp", "purse", "arrows"]:
			h[k] = int(h.get(k, 0))
		var st: Dictionary = h.get("stats", {})
		for s in st.keys():
			st[s] = int(st[s])
	active = clampi(int(d.get("active", 0)), 0, maxi(0, heroes.size() - 1))
	buddy = int(d.get("buddy", -1))
	if buddy >= heroes.size() or buddy == active:
		buddy = -1
	follow = bool(d.get("follow", true))
