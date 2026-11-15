extends RefCounted
## Morrowind-style worn gear. Slots + items come from res://data/clothing.json.
## The player owns every item (pack); paired types (pauldron, glove, ring) can be
## worn on both sides at once. Underclothes always stay on.

const LowPoly = preload("res://art/lowpoly_character.gd")

var slots: Array = []         # [{slot, label, type}]
var equipped: Dictionary = {} # slot -> item id
var start: Dictionary = {}


func load_config(path := "res://data/clothing.json") -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	slots = d.get("slots", [])
	start = d.get("hero_start", {})
	equipped = start.duplicate()
	LowPoly.load_items(path)


func slot_info(slot: String) -> Dictionary:
	for s in slots:
		if s["slot"] == slot:
			return s
	return {}


func items_for(slot: String) -> Array:
	var t := str(slot_info(slot).get("type", ""))
	var out: Array = []
	for id in LowPoly.load_items().keys():
		var it: Dictionary = LowPoly.load_items()[id]
		if str(it.get("type", "")) == t:
			out.append(it)
	return out


func item_name(id: String) -> String:
	return str(LowPoly.item(id).get("name", ""))


func equip(slot: String, id: String) -> void:
	if id == "":
		equipped.erase(slot)
	else:
		equipped[slot] = id


func take_off(slot: String) -> void:
	equipped.erase(slot)


func strip_all() -> void:
	equipped.clear()


## Paidagogos' one-tap "Dress Me": best armor + warmth + charm per slot.
func dress_me() -> void:
	for s in slots:
		var best := ""
		var score := -1
		for it in items_for(s["slot"]):
			var st: Dictionary = it.get("stats", {})
			var v := int(st.get("armor", 0)) * 3 + int(st.get("warmth", 0)) + int(st.get("charm", 0))
			if v > score:
				score = v
				best = str(it["id"])
		if best != "":
			equipped[s["slot"]] = best


func totals() -> Dictionary:
	var t := {"armor": 0, "warmth": 0, "weight": 0, "charm": 0, "stealth": 0, "magic": 0}
	for slot in equipped.keys():
		var st: Dictionary = LowPoly.item(str(equipped[slot])).get("stats", {})
		for k in t.keys():
			t[k] += int(st.get(k, 0))
	return t


func worn_count() -> int:
	return equipped.size()


func to_dict() -> Dictionary:
	return equipped.duplicate()


func from_dict(d: Dictionary) -> void:
	equipped = {}
	for k in d.keys():
		if not LowPoly.item(str(d[k])).is_empty():
			equipped[str(k)] = str(d[k])
