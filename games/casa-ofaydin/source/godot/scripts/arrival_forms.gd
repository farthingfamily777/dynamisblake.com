extends RefCounted
class_name ArrivalForms
## Pure arrival-form logic for Port Paradise. No UI.
## Spec: /workspace/casa-game/character-creation-v0.1.md
## Gear: res://data/starting_gear.json
## Godot 4.3, Compatibility / web-safe: no threads, no editor-only APIs.

const GEAR_PATH := "res://data/starting_gear.json"
const NAME_MAX_LEN := 32

const SLOT_NAMES: Array = [
	"cap/hood", "helmet", "crown",
	"undershirt", "shirt", "tunic", "chain mail", "breastplate",
	"robe (over or under armor)", "cloak",
	"left pauldron", "right pauldron",
	"left bracer", "right bracer", "left glove", "right glove",
	"left gauntlet", "right gauntlet",
	"underpants", "tights", "pants or skirt", "chain leggings", "greaves",
	"socks", "shoes or boots",
	"belt", "pouch",
	"amulet", "left ring", "right ring",
	"main hand", "off hand or shield",
]

const STEPS: Array = [
	{"id": "begin", "title": "How to begin", "fields": ["start_mode"]},
	{"id": "name", "title": "Your name", "fields": ["name"]},
	{"id": "people", "title": "Your people", "fields": ["race"]},
	{"id": "gender", "title": "Your gender", "fields": ["gender"]},
	{"id": "look", "title": "How you look and sound", "fields": ["appearance", "voice"]},
	{"id": "class", "title": "Your class", "fields": ["class_id"]},
	{"id": "start", "title": "Your start", "fields": ["place", "family", "job"]},
	{"id": "review", "title": "Review and sign", "fields": []},
]

# Starting classes already named in the design docs.
const CLASSES: Array = [
	{"id": "pilgrim", "label": "Pilgrim", "placeholder": false},
	{"id": "merchant", "label": "Merchant", "placeholder": false},
	{"id": "mage", "label": "Mage", "placeholder": false},
	{"id": "fighter", "label": "Fighter", "placeholder": false},
	{"id": "thief", "label": "Thief", "placeholder": false},
	{"id": "assassin", "label": "Assassin", "placeholder": false},
	{"id": "rogue", "label": "Rogue", "placeholder": false},
	{"id": "vampire", "label": "Vampire", "placeholder": false},
]

# Peoples Blake has already named. Placeholder names are flagged.
const RACES: Array = [
	{"id": "human", "label": "Human", "placeholder": false},
	{"id": "nordic", "label": "Nordic", "placeholder": false},
	{"id": "gray_alien", "label": "Gray Alien", "placeholder": false},
	{"id": "alien", "label": "Alien", "placeholder": false},
	{"id": "elf", "label": "Elf", "placeholder": false},
	{"id": "ork", "label": "Ork", "placeholder": false},
	{"id": "dragon", "label": "Dragon", "placeholder": false},
	{"id": "fairy", "label": "Fairy", "placeholder": false},
	{"id": "vampire", "label": "Vampire", "placeholder": false},
	{"id": "werewolf", "label": "Werewolf", "placeholder": false},
	{"id": "demon", "label": "Demon", "placeholder": false},
	{"id": "lich", "label": "Lich", "placeholder": false},
	{"id": "entity", "label": "Entity", "placeholder": false},
	{"id": "soul", "label": "Soul", "placeholder": false},
	{"id": "spirit", "label": "Spirit", "placeholder": false},
	{"id": "krishna_like", "label": "Krishna-like people", "placeholder": true},
	{"id": "ganesh_like", "label": "Ganesh-like people", "placeholder": true},
]

const GENDERS: Array = [
	{"id": "male", "label": "Male", "placeholder": false},
	{"id": "female", "label": "Female", "placeholder": false},
]

const HAIR: Array = [
	{"id": "short", "label": "Short", "placeholder": true},
	{"id": "medium", "label": "Medium", "placeholder": true},
	{"id": "long", "label": "Long", "placeholder": true},
	{"id": "braided", "label": "Braided", "placeholder": true},
	{"id": "bald", "label": "Bald", "placeholder": true},
]

const HAIR_COLORS: Array = [
	{"id": "black", "label": "Black", "placeholder": true},
	{"id": "brown", "label": "Brown", "placeholder": true},
	{"id": "gold", "label": "Gold", "placeholder": true},
	{"id": "red", "label": "Red", "placeholder": true},
	{"id": "white", "label": "White", "placeholder": true},
	{"id": "gray", "label": "Gray", "placeholder": true},
]

const TONES: Array = [
	{"id": "tone_1", "label": "Tone 1", "placeholder": true},
	{"id": "tone_2", "label": "Tone 2", "placeholder": true},
	{"id": "tone_3", "label": "Tone 3", "placeholder": true},
	{"id": "tone_4", "label": "Tone 4", "placeholder": true},
	{"id": "tone_5", "label": "Tone 5", "placeholder": true},
	{"id": "tone_6", "label": "Tone 6", "placeholder": true},
	{"id": "tone_7", "label": "Tone 7", "placeholder": true},
	{"id": "tone_8", "label": "Tone 8", "placeholder": true},
]

const BUILDS: Array = [
	{"id": "small", "label": "Small", "placeholder": true},
	{"id": "medium", "label": "Medium", "placeholder": true},
	{"id": "tall", "label": "Tall", "placeholder": true},
	{"id": "sturdy", "label": "Sturdy", "placeholder": true},
]

const FACES: Array = [
	{"id": "face_1", "label": "Face 1", "placeholder": true},
	{"id": "face_2", "label": "Face 2", "placeholder": true},
	{"id": "face_3", "label": "Face 3", "placeholder": true},
	{"id": "face_4", "label": "Face 4", "placeholder": true},
	{"id": "face_5", "label": "Face 5", "placeholder": true},
]

const VOICES: Array = [
	{"id": "warm", "label": "Warm", "placeholder": true},
	{"id": "calm", "label": "Calm", "placeholder": true},
	{"id": "bright", "label": "Bright", "placeholder": true},
	{"id": "deep", "label": "Deep", "placeholder": true},
]

const PLACES: Array = [
	{"id": "arrival_dock", "label": "Arrival dock", "placeholder": false},
	{"id": "market", "label": "The market", "placeholder": false},
	{"id": "high_tavern", "label": "High-class tavern", "placeholder": false},
	{"id": "low_shack", "label": "Low-class shack", "placeholder": false},
	{"id": "cargo_docks", "label": "Cargo docks", "placeholder": false},
	{"id": "monolith", "label": "The ancient stone monolith", "placeholder": false},
	{"id": "governors_mansion", "label": "Governor's mansion", "placeholder": false},
]

const FAMILIES: Array = [
	{"id": "traveling_alone", "label": "Traveling alone", "placeholder": false},
	{"id": "dock_family", "label": "A dock family", "placeholder": true},
	{"id": "trade_family", "label": "A trading family", "placeholder": true},
	{"id": "town_family", "label": "A town family", "placeholder": true},
	{"id": "monk_family", "label": "A monk family", "placeholder": true},
]

const JOBS: Array = [
	{"id": "new_arrival", "label": "New arrival (no job yet)", "placeholder": false},
	{"id": "dock_worker", "label": "Dock worker", "placeholder": true},
	{"id": "trader", "label": "Trader", "placeholder": true},
	{"id": "farm_helper", "label": "Farm helper", "placeholder": true},
	{"id": "temple_helper", "label": "Temple helper", "placeholder": true},
]

# Placeholder first names only. Not canon. No family or copyrighted names.
const PLACEHOLDER_NAMES: Array = [
	"Ari", "Noor", "Sam", "Jin", "Mara", "Tess", "Bo", "Luis",
	"Anya", "Ken", "Priya", "Omar", "Nico", "Ruth", "Sol", "Eden",
	"Kira", "Mateo", "Hana", "Reed", "Lila", "Yusuf", "Willa", "Theo",
]

var rng: RandomNumberGenerator
var record: Dictionary
var step_index: int
var _gear_table: Dictionary
var _blocked_token: String


func _init() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	_blocked_token = "6".repeat(3)
	step_index = 0
	_gear_table = {}
	record = new_record()


func new_record() -> Dictionary:
	return {
		"id": make_id(),
		"is_playable": true,
		"signed": false,
		"start_mode": "",
		"name": "",
		"race": "",
		"gender": "",
		"appearance": {
			"face": "",
			"hair": "",
			"hair_color": "",
			"tone": "",
			"build": "",
		},
		"voice": "",
		"class_id": "",
		"family": "traveling_alone",
		"place": "arrival_dock",
		"job": "new_arrival",
		"arrived_town": "Port Paradise",
		"robe_over_armor": true,
		"equipment": empty_equipment(),
		"kit_name": "",
		"stats": {"health": 100.0, "mana": 100.0},
		"faction": "",
		"reputation": {},
		"role_ladder": {"current_role": "", "history": []},
	}


func empty_equipment() -> Dictionary:
	var gear := {}
	for slot in SLOT_NAMES:
		gear[slot] = null
	return gear


func make_id() -> String:
	for _i in 32:
		var s := "c_%x" % rng.randi()
		if s.find(_blocked_token) == -1:
			return s
	return "c_1000"


func current_step() -> Dictionary:
	if step_index < 0 or step_index >= STEPS.size():
		return {}
	return STEPS[step_index]


func step_id() -> String:
	var step: Dictionary = current_step()
	return str(step.get("id", ""))


func can_go_back() -> bool:
	return (not bool(record.get("signed", false))) and step_index > 0


func can_go_next() -> bool:
	if bool(record.get("signed", false)):
		return false
	if step_index >= STEPS.size() - 1:
		return false
	var check: Dictionary = validate_step(step_id())
	return bool(check.get("ok", false))


func next() -> bool:
	if bool(record.get("signed", false)):
		return false
	var check: Dictionary = validate_step(step_id())
	if not bool(check.get("ok", false)):
		return false
	if step_id() == "begin" and str(record.get("start_mode", "")) == "random":
		self.randomize()
		step_index = STEPS.size() - 1
		return true
	if step_index < STEPS.size() - 1:
		step_index += 1
		return true
	return false


func back() -> bool:
	if not can_go_back():
		return false
	step_index -= 1
	return true


func goto_step(id: String) -> bool:
	if bool(record.get("signed", false)):
		return false
	for i in STEPS.size():
		if str(STEPS[i].get("id", "")) == id:
			step_index = i
			return true
	return false


func options_for(field: String) -> Array:
	match field:
		"start_mode":
			return [
				{"id": "pick", "label": "Pick my start", "placeholder": false},
				{"id": "random", "label": "Random start", "placeholder": false},
			]
		"race":
			return RACES.duplicate()
		"gender":
			return GENDERS.duplicate()
		"class_id":
			return CLASSES.duplicate()
		"place":
			return PLACES.duplicate()
		"family":
			return FAMILIES.duplicate()
		"job":
			return JOBS.duplicate()
		"voice":
			return VOICES.duplicate()
		"hair":
			return HAIR.duplicate()
		"hair_color":
			return HAIR_COLORS.duplicate()
		"tone":
			return TONES.duplicate()
		"build":
			return BUILDS.duplicate()
		"face":
			return FACES.duplicate()
		_:
			return []


func label_for(field: String, id: String) -> String:
	for item in options_for(field):
		if str(item.get("id", "")) == id:
			return str(item.get("label", id))
	return id


func set_value(field: String, value: Variant) -> Dictionary:
	if bool(record.get("signed", false)):
		return _result(false, ["These papers are already signed."])
	match field:
		"name":
			record["name"] = str(value).strip_edges()
		"start_mode", "race", "gender", "class_id", "place", "family", "job", "voice":
			record[field] = str(value)
			if field == "class_id":
				apply_class_gear()
				record["role_ladder"] = _starting_role(record)
		"face", "hair", "hair_color", "tone", "build":
			var looks: Dictionary = record.get("appearance", {})
			looks[field] = str(value)
			record["appearance"] = looks
		_:
			return _result(false, ["That field is not on the form."])
	return validate_field(field, record)


func randomize() -> Dictionary:
	# Fills every field for Random start. Does not sign the papers.
	var fresh: Dictionary = new_record()
	fresh["start_mode"] = "random"
	fresh["name"] = str(_pick(PLACEHOLDER_NAMES))
	fresh["race"] = str(_pick(_ids(RACES)))
	fresh["gender"] = str(_pick(_ids(GENDERS)))
	fresh["appearance"] = {
		"face": str(_pick(_ids(FACES))),
		"hair": str(_pick(_ids(HAIR))),
		"hair_color": str(_pick(_ids(HAIR_COLORS))),
		"tone": str(_pick(_ids(TONES))),
		"build": str(_pick(_ids(BUILDS))),
	}
	fresh["voice"] = str(_pick(_ids(VOICES)))
	fresh["class_id"] = str(_pick(_ids(CLASSES)))
	fresh["place"] = str(_pick(_ids(PLACES)))
	fresh["family"] = str(_pick(_ids(FAMILIES)))
	fresh["job"] = str(_pick(_ids(JOBS)))
	fresh["arrived_town"] = "Port Paradise"
	record = fresh
	apply_class_gear()
	record["role_ladder"] = _starting_role(record)
	record["signed"] = false
	return record


func roll_again() -> Dictionary:
	self.randomize()
	step_index = STEPS.size() - 1
	return record


func apply_class_gear(rec: Dictionary = {}) -> Dictionary:
	var target: Dictionary = record if rec.is_empty() else rec
	var class_id := str(target.get("class_id", ""))
	var table: Dictionary = load_gear_table()
	var equipment: Dictionary = empty_equipment()
	var kit_name := ""
	var robe := true
	if table.has("common_base") and table["common_base"] is Dictionary:
		_merge_gear(equipment, table["common_base"])
	var kits: Dictionary = table.get("kits", {})
	if kits.has(class_id) and kits[class_id] is Dictionary:
		var kit: Dictionary = kits[class_id]
		kit_name = str(kit.get("kit_name", ""))
		robe = bool(kit.get("robe_over_armor", true))
		if kit.has("gear") and kit["gear"] is Dictionary:
			_merge_gear(equipment, kit["gear"])
	target["equipment"] = equipment
	target["kit_name"] = kit_name
	target["robe_over_armor"] = robe
	return target


func load_gear_table() -> Dictionary:
	if not _gear_table.is_empty():
		return _gear_table
	if not FileAccess.file_exists(GEAR_PATH):
		return {}
	var file := FileAccess.open(GEAR_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_gear_table = parsed
	return _gear_table


func validate_step(id: String, rec: Dictionary = {}) -> Dictionary:
	var target: Dictionary = record if rec.is_empty() else rec
	var errors: Array = []
	match id:
		"begin":
			_add_field_errors(errors, validate_field("start_mode", target))
		"name":
			_add_field_errors(errors, validate_field("name", target))
		"people":
			_add_field_errors(errors, validate_field("race", target))
		"gender":
			_add_field_errors(errors, validate_field("gender", target))
		"look":
			_add_field_errors(errors, validate_field("appearance", target))
			_add_field_errors(errors, validate_field("voice", target))
		"class":
			_add_field_errors(errors, validate_field("class_id", target))
			_add_field_errors(errors, _validate_gear(target))
		"start":
			_add_field_errors(errors, validate_field("place", target))
			_add_field_errors(errors, validate_field("family", target))
			_add_field_errors(errors, validate_field("job", target))
		"review":
			return validate_record(target)
		_:
			errors.append("That page is not on the form.")
	return _result(errors.is_empty(), errors)


func validate_record(rec: Dictionary = {}) -> Dictionary:
	var target: Dictionary = record if rec.is_empty() else rec
	var errors: Array = []
	for id in ["begin", "name", "people", "gender", "look", "class", "start"]:
		_add_field_errors(errors, validate_step(id, target))
	if str(target.get("id", "")).find(_blocked_token) != -1:
		errors.append("That name can't be used. Please pick another.")
	if str(target.get("arrived_town", "")) == "":
		errors.append("Please pick your place, family, and job.")
	return _result(errors.is_empty(), errors)


func validate_field(field: String, rec: Dictionary = {}) -> Dictionary:
	var target: Dictionary = record if rec.is_empty() else rec
	match field:
		"start_mode":
			var mode := str(target.get("start_mode", ""))
			if mode != "pick" and mode != "random":
				return _result(false, ["Please pick how to begin."])
		"name":
			return _validate_name(str(target.get("name", "")))
		"race":
			if not _is_option("race", str(target.get("race", ""))):
				return _result(false, ["Please pick your people."])
		"gender":
			if not _is_option("gender", str(target.get("gender", ""))):
				return _result(false, ["Please pick a gender."])
		"class_id":
			if not _is_option("class_id", str(target.get("class_id", ""))):
				return _result(false, ["Please pick a class."])
		"voice":
			if not _is_option("voice", str(target.get("voice", ""))):
				return _result(false, ["Please finish how you look and sound."])
		"place":
			if not _is_option("place", str(target.get("place", ""))):
				return _result(false, ["Please pick your place, family, and job."])
		"family":
			if not _is_option("family", str(target.get("family", ""))):
				return _result(false, ["Please pick your place, family, and job."])
		"job":
			if not _is_option("job", str(target.get("job", ""))):
				return _result(false, ["Please pick your place, family, and job."])
		"appearance":
			var looks: Dictionary = target.get("appearance", {})
			for sub in ["face", "hair", "hair_color", "tone", "build"]:
				if not _is_option(sub, str(looks.get(sub, ""))):
					return _result(false, ["Please finish how you look and sound."])
		_:
			return _result(false, ["That field is not on the form."])
	return _result(true, [])


func sign_forms() -> Dictionary:
	var check: Dictionary = validate_record()
	if not bool(check.get("ok", false)):
		return check
	record["signed"] = true
	record["is_playable"] = true
	if str(record.get("role_ladder", {}).get("current_role", "")) == "":
		record["role_ladder"] = _starting_role(record)
	return check


func make_npc(overrides: Dictionary = {}) -> Dictionary:
	# Same character model as a signed arrival, for town people you can switch to later.
	self.randomize()
	for key in overrides.keys():
		record[key] = overrides[key]
	if not overrides.has("equipment"):
		apply_class_gear()
	record["start_mode"] = str(overrides.get("start_mode", "npc"))
	record["signed"] = true
	record["is_playable"] = true
	if str(record.get("role_ladder", {}).get("current_role", "")) == "":
		record["role_ladder"] = _starting_role(record)
	return record.duplicate(true)


func _validate_name(n: String) -> Dictionary:
	var cleaned := n.strip_edges()
	if cleaned.is_empty():
		return _result(false, ["Please type a name."])
	if cleaned.length() > NAME_MAX_LEN:
		return _result(false, ["Please type a shorter name."])
	if cleaned.find(_blocked_token) != -1:
		return _result(false, ["That name can't be used. Please pick another."])
	if not _name_chars_ok(cleaned):
		return _result(false, ["Please use letters, spaces, hyphens, or apostrophes only."])
	return _result(true, [])


func _name_chars_ok(n: String) -> bool:
	for i in n.length():
		var ch := n.unicode_at(i)
		if ch == 32 or ch == 45 or ch == 39:
			continue
		if (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122):
			continue
		if ch > 127:
			continue
		return false
	return true


func _validate_gear(rec: Dictionary) -> Dictionary:
	if str(rec.get("class_id", "")) != "" and str(rec.get("kit_name", "")) == "":
		return _result(false, ["Please pick a class."])
	var equipment: Dictionary = rec.get("equipment", {})
	for slot in equipment.keys():
		if SLOT_NAMES.find(slot) == -1:
			return _result(false, ["Please pick a class."])
	return _result(true, [])


func _starting_role(rec: Dictionary) -> Dictionary:
	var job := str(rec.get("job", ""))
	var label := label_for("class_id", str(rec.get("class_id", "")))
	if job != "" and job != "new_arrival":
		label = label_for("job", job)
	return {"current_role": label, "history": []}


func _merge_gear(equipment: Dictionary, incoming: Dictionary) -> void:
	for slot in incoming.keys():
		if SLOT_NAMES.find(str(slot)) == -1:
			continue
		equipment[slot] = incoming[slot]


func _is_option(field: String, id: String) -> bool:
	if id == "":
		return false
	for item in options_for(field):
		if str(item.get("id", "")) == id:
			return true
	return false


func _ids(list: Array) -> Array:
	var out: Array = []
	for item in list:
		out.append(str(item.get("id", "")))
	return out


func _pick(options: Array) -> Variant:
	if options.is_empty():
		return ""
	return options[rng.randi_range(0, options.size() - 1)]


func _add_field_errors(errors: Array, check: Dictionary) -> void:
	if bool(check.get("ok", false)):
		return
	for line in check.get("errors", []):
		if errors.find(line) == -1:
			errors.append(line)


func _result(ok: bool, errors: Array) -> Dictionary:
	return {"ok": ok, "errors": errors}
