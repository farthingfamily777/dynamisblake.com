extends Object
# Late-90s low-poly people (PS1 wrestling / FF7 / N64 style), built in code.
# Chunky segmented boxes with vertex-color shading, one shared material.
# Ten meshes per person (chest, head, upper/lower arms, thighs, shins) so the
# limbs can swing. Worn gear is merged INTO those segment meshes, so a fully
# geared hero still costs ten meshes.
#
# No eyes are ever drawn (house rule). Faces read from brow shadow, nose,
# mouth, ears, hair, and beard.
#
# Characters face +Z. The hero's Body is turned 180 degrees in main.gd's world.
#
# Usage:
#   var body := LowPoly.build(parent, {"skin": Color(...), "build": "broad",
#       "hair": "crop", "gear": {"head": "pilgrim_hood", ...}}, clothing_db)
#   LowPoly.animate(body, phase, walk_amount)

const PARTS := ["chest", "head", "arm_l", "fore_l", "arm_r", "fore_r", "leg_l", "shin_l", "leg_r", "shin_r"]

const SKIN := [
	Color(0.86, 0.70, 0.56), Color(0.76, 0.58, 0.43), Color(0.62, 0.45, 0.32),
	Color(0.48, 0.33, 0.23), Color(0.36, 0.25, 0.18), Color(0.80, 0.64, 0.50)
]
const HAIR_COLORS := [
	Color(0.12, 0.09, 0.07), Color(0.28, 0.18, 0.10), Color(0.45, 0.30, 0.16),
	Color(0.62, 0.48, 0.28), Color(0.55, 0.53, 0.50), Color(0.40, 0.17, 0.10)
]
const HAIR_STYLES := ["crop", "long", "topknot", "bald", "shag", "braid"]
const BUILDS := {
	"slim":    {"sw": 0.36, "hw": 0.30, "limb": 0.88, "belly": 0.0},
	"average": {"sw": 0.42, "hw": 0.32, "limb": 1.0, "belly": 0.0},
	"broad":   {"sw": 0.52, "hw": 0.34, "limb": 1.18, "belly": 0.0},
	"stout":   {"sw": 0.46, "hw": 0.38, "limb": 1.08, "belly": 0.07}
}

static var _mat: StandardMaterial3D
static var _items: Dictionary = {}


static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.vertex_color_is_srgb = true
		# N64-style Gouraud: lighting per vertex, smooth normals, soft spec.
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		_mat.roughness = 0.9
		_mat.metallic_specular = 0.15
	return _mat


static func load_items(path := "res://data/clothing.json") -> Dictionary:
	if not _items.is_empty():
		return _items
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return _items
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		for it in data.get("items", []):
			_items[str(it["id"])] = it
	return _items


static func item(id: String) -> Dictionary:
	load_items()
	return _items.get(id, {})


static func col(v, fallback := Color(0.5, 0.5, 0.5)) -> Color:
	if v is Color:
		return v
	if typeof(v) == TYPE_STRING and v != "":
		return Color.html(v)
	return fallback


# ---------------------------------------------------------------- build
# Poly budget (Blake, Nov 15 2026, after Ocarina of Time's Young Link):
#   LOD0 (hero, close people): about 700-760 triangles with gear, cap LOD0_CAP.
#   LOD1 (far / crowd): about 400-450 triangles (OoT used 434), cap LOD1_CAP.
# Each character is ONE skinned mesh per LOD (rigid one-bone-per-vertex skinning,
# like the PS1/N64 era), so a whole geared person is one draw call. Godot's
# visibility_range swaps LOD0 -> LOD1 at LOD_SWAP_M metres from the camera.
const LOD0_CAP := 760
const LOD1_CAP := 450
const LOD_SWAP_M := 14.0
const BONES := ["Hips", "Head", "ArmL", "ForeL", "ArmR", "ForeR", "LegL", "ShinL", "LegR", "ShinR"]
const BONE_PARENT := [-1, -1, -1, 2, -1, 4, -1, 6, -1, 8]
const RigBody = preload("res://art/rig_body.gd")
const N64 = preload("res://art/n64_mesh.gd")


static func build(parent: Node3D, p: Dictionary, name := "Body") -> Node3D:
	var old := parent.get_node_or_null(name)
	if old:
		parent.remove_child(old)
		old.queue_free()
	var body: Node3D = RigBody.new()
	body.name = name
	parent.add_child(body)
	var bd: Dictionary = BUILDS.get(str(p.get("build", "average")), BUILDS["average"])
	var sw: float = bd["sw"]
	var limb: float = bd["limb"]
	# Rig pivots: plain Node3Ds that game code rotates; RigBody copies them to bones.
	var hips := Node3D.new(); hips.name = "Hips"; hips.position = Vector3(0, 0.92, 0); body.add_child(hips)
	var head := Node3D.new(); head.name = "Head"; head.position = Vector3(0, 1.45, 0); body.add_child(head)
	var nodes := {"chest": hips, "head": head}
	for s in [["l", 1.0], ["r", -1.0]]:
		var arm := Node3D.new(); arm.name = "Arm" + s[0].to_upper()
		arm.position = Vector3(s[1] * (sw * 0.5 + 0.06 * limb), 1.38, 0)
		body.add_child(arm)
		var fore := Node3D.new(); fore.name = "Fore" + s[0].to_upper(); fore.position = Vector3(0, -0.29, 0); arm.add_child(fore)
		var leg := Node3D.new(); leg.name = "Leg" + s[0].to_upper()
		leg.position = Vector3(s[1] * (bd["hw"] * 0.5 - 0.075), 0.92, 0)
		body.add_child(leg)
		var shin := Node3D.new(); shin.name = "Shin" + s[0].to_upper(); shin.position = Vector3(0, -0.43, 0); leg.add_child(shin)
		nodes["arm_" + s[0]] = arm; nodes["fore_" + s[0]] = fore
		nodes["leg_" + s[0]] = leg; nodes["shin_" + s[0]] = shin
	var parts := {"_boxes": [], "_ess": false}
	var P := {
		"sw": sw, "hw": bd["hw"], "limb": limb, "belly": bd["belly"],
		"skin": col(p.get("skin", SKIN[1])),
		"hair": str(p.get("hair", "crop")),
		"hair_col": col(p.get("hair_color", HAIR_COLORS[1])),
		"beard": bool(p.get("beard", false)),
		"under": col(p.get("under", Color(0.80, 0.74, 0.62))),
		"shorts": col(p.get("shorts", Color(0.55, 0.47, 0.36))),
	}
	var gear: Dictionary = p.get("gear", {})
	var tints: Dictionary = p.get("tints", {})
	P["paint"] = _paint(P, gear, tints)
	_body(parts, P, gear)
	# Gear, inner to outer.
	for slot in ["pants", "shirt", "boots", "greaves", "cuirass", "belt", "glove_l", "glove_r",
			"pauldron_l", "pauldron_r", "robe", "amulet", "ring_l", "ring_r", "head"]:
		var id := str(gear.get(slot, ""))
		if id == "":
			continue
		var it := item(id)
		if it.is_empty():
			continue
		if tints.has(slot):
			it = it.duplicate()
			it["color"] = tints[slot]
		var first: int = parts["_boxes"].size()
		_draw_item(parts, P, slot, it)
		# The biggest box of each worn piece always survives LOD0, so every item shows.
		var big := -1
		for i in range(first, parts["_boxes"].size()):
			if big < 0 or parts["_boxes"][i]["area"] > parts["_boxes"][big]["area"]:
				big = i
		if big >= 0:
			parts["_boxes"][big]["main"] = true
	var weapon := str(p.get("weapon", "staff" if p.get("staff", false) else ""))
	parts["_ess"] = true
	_weapon(parts, weapon)
	parts["_kind"] = ""
	parts["_ess"] = false
	# Skeleton mirrors the pivots.
	var skel := Skeleton3D.new()
	skel.name = "Skel"
	body.add_child(skel)
	var rest := {}
	for i in BONES.size():
		skel.add_bone(BONES[i])
	for i in BONES.size():
		if BONE_PARENT[i] >= 0:
			skel.set_bone_parent(i, BONE_PARENT[i])
	var key_of := {"Hips": "chest", "Head": "head", "ArmL": "arm_l", "ForeL": "fore_l", "ArmR": "arm_r",
		"ForeR": "fore_r", "LegL": "leg_l", "ShinL": "shin_l", "LegR": "leg_r", "ShinR": "shin_r"}
	var pivots: Array = []
	for i in BONES.size():
		var n: Node3D = nodes[key_of[BONES[i]]]
		skel.set_bone_rest(i, n.transform)
		skel.set_bone_pose_position(i, n.position)
		pivots.append(n)
		# rest pose of the pivot in body space
		var g := n.transform
		if BONE_PARENT[i] >= 0:
			g = (pivots[BONE_PARENT[i]] as Node3D).transform * n.transform
		rest[key_of[BONES[i]]] = {"bone": i, "xf": g}
	body.set("pivots", pivots)
	body.set("skel", skel)
	# Generate both LODs, cull buried pieces, fit the budgets, one skinned mesh per LOD.
	var shapes: Array = parts["_boxes"]
	N64.prepare(shapes, 0, rest)
	N64.prepare(shapes, 1, rest)
	body.set_meta("tris_wanted", N64.count(shapes, 0))
	var lod0 := N64.fit(shapes, 0, LOD0_CAP)
	var lod1 := N64.fit(shapes, 1, LOD1_CAP)
	var tri0 := N64.count(lod0, 0)
	var tri1 := N64.count(lod1, 1)
	for lod in [[lod0, "LOD0", 0], [lod1, "LOD1", 1]]:
		var mi := MeshInstance3D.new()
		mi.name = lod[1]
		mi.mesh = N64.commit(lod[0], lod[2], rest)
		mi.material_override = material()
		skel.add_child(mi)
		mi.skeleton = NodePath("..")
		mi.custom_aabb = AABB(Vector3(-1.2, -0.3, -1.4), Vector3(2.4, 2.6, 2.8))
		if lod[1] == "LOD0":
			mi.visibility_range_end = LOD_SWAP_M
			mi.visibility_range_end_margin = 1.0
		else:
			mi.visibility_range_begin = LOD_SWAP_M
			mi.visibility_range_begin_margin = 1.0
	if weapon == "staff":
		_staff_glow(nodes)
	body.set_meta("tris_lod0", tri0)
	body.set_meta("tris_lod1", tri1)
	body.set_meta("weapon", weapon)
	body.scale = Vector3.ONE * float(p.get("height", 1.0))
	body.set_meta("walk_phase", randf() * TAU)
	return body


# ---------------------------------------------------------------- shape recording

## Generic piece: tapered, rotatable, centred at c with size s. Picks its own
## late-90s shape: thin front/back trim becomes a painted quad, tiny bits stay
## little blocks, everything else is a 6- or 8-sided tapered cylinder with smooth
## (Gouraud) normals. parts["_kind"] can force a kind ("dome", "ell", "box").
## tt / tb scale the top / bottom (x, z). rot is degrees. shade darkens the bottom.
static func bx(parts: Dictionary, part: String, c: Vector3, s: Vector3, color: Color,
		tt := Vector2.ONE, tb := Vector2.ONE, rot := Vector3.ZERO, shade := 0.22) -> Dictionary:
	var kind := str(parts.get("_kind", ""))
	var r := rot
	if kind == "":
		if minf(s.x, s.z) <= 0.026 and s.z <= s.x and absf(c.z) > 0.08 and part in ["chest", "head"]:
			kind = "quad"
			if c.z < 0.0:
				r = rot + Vector3(0, 180, 0)
		elif maxf(s.x, s.z) < 0.07 or minf(s.x, s.z) < 0.03:
			kind = "box"
		else:
			kind = "cyl"
	var sides := 4 if kind == "box" else (8 if maxf(s.x, s.z) >= 0.2 else 6)
	var sh := {"part": part, "kind": kind, "c": c, "s": s, "color": color, "bot": color.darkened(shade),
		"tt": tt, "tb": tb, "rot": r, "sides": sides, "segs": 1, "bulge": 0.0,
		"area": s.x * s.y + s.y * s.z + s.x * s.z, "ess": bool(parts.get("_ess", false)),
		"main": false, "order": parts["_boxes"].size(), "nu": 8, "nv": 6}
	if kind == "dome":
		sh["nu"] = 6; sh["nv"] = 2
	parts["_boxes"].append(sh)
	return sh


## Ellipsoid (heads, beards, hoods, hair). jaw < 1 narrows the lower half.
static func ell(parts: Dictionary, part: String, c: Vector3, s: Vector3, color: Color,
		bot: Color, nu := 8, nv := 6, jaw := 1.0, rot := Vector3.ZERO) -> Dictionary:
	parts["_kind"] = "ell"
	var sh := bx(parts, part, c, s, color, Vector2.ONE, Vector2.ONE, rot, 0.0)
	parts["_kind"] = ""
	sh["bot"] = bot; sh["nu"] = nu; sh["nv"] = nv; sh["jaw"] = jaw
	return sh


## Dome: upper half-ellipsoid on a flat base (c = base centre, s.y = height).
static func dome(parts: Dictionary, part: String, c: Vector3, s: Vector3, color: Color,
		bot: Color, nu := 6, nv := 2, rot := Vector3.ZERO) -> Dictionary:
	parts["_kind"] = "dome"
	var sh := bx(parts, part, c, s, color, Vector2.ONE, Vector2.ONE, rot, 0.0)
	parts["_kind"] = ""
	sh["bot"] = bot; sh["nu"] = nu; sh["nv"] = nv
	return sh


## Lofted tube through rings [[y, rx, rz, Color], ...] (y local to the part).
static func loft(parts: Dictionary, part: String, rings: Array, sides := 8, x := 0.0, z := 0.0) -> Dictionary:
	var y0 := float(rings[0][0]); var y1 := float(rings[rings.size() - 1][0])
	var w := 0.0; var d := 0.0
	for r in rings:
		w = maxf(w, float(r[1]) * 2.0); d = maxf(d, float(r[2]) * 2.0)
	parts["_kind"] = "loft"
	var sh := bx(parts, part, Vector3(x, 0, z), Vector3(w, absf(y1 - y0), d), rings[rings.size() - 1][3])
	parts["_kind"] = ""
	sh["rings"] = rings
	sh["sides"] = sides
	return sh


## Smooth limb segment: 6-sided tapered cylinder with a muscle bulge.
static func limb(parts: Dictionary, part: String, c: Vector3, s: Vector3, color: Color,
		tt := Vector2.ONE, tb := Vector2.ONE, bulge := 0.08, segs := 2, shade := 0.12) -> Dictionary:
	parts["_kind"] = "cyl"
	var sh := bx(parts, part, c, s, color, tt, tb, Vector3.ZERO, shade)
	parts["_kind"] = ""
	sh["sides"] = 6; sh["segs"] = segs; sh["bulge"] = bulge
	return sh


# ---------------------------------------------------------------- body + underclothes

static func _body(parts: Dictionary, P: Dictionary, gear: Dictionary) -> void:
	var skin: Color = P["skin"]
	var sw: float = P["sw"]; var hw: float = P["hw"]; var L: float = P["limb"]; var belly: float = P["belly"]
	var under: Color = P["under"]; var shorts: Color = P["shorts"]
	var shadow := skin.darkened(0.18)
	var pt: Dictionary = P["paint"]
	parts["_ess"] = true
	# Torso: one 8-sided loft, hips -> waist -> chest -> rounded shoulders -> neck base.
	# Chest wider than the waist; the stout build gets a belly ring.
	var waist: Color = pt["waist"]
	loft(parts, "chest", [
		[-0.07, hw * 0.50, 0.105, (pt["hip"] as Color).darkened(0.15)],
		[0.085, hw * 0.52 + belly * 0.5, 0.115 + belly * 0.5, pt["hip"]],
		[0.20, hw * 0.47 + belly, 0.108 + belly, waist.darkened(0.06)],
		[0.35, sw * 0.47, 0.135, pt["chest"]],
		[0.465, sw * 0.5, 0.12, pt["shoulder"]],
		[0.54, sw * 0.22, 0.075, (pt["shoulder"] as Color).darkened(0.05)],
	], 8, 0.0, belly * 0.3)
	# Head: ellipsoid with a jaw taper, chin, nose, mouth, brow shadow. No eyes.
	var h := "head"
	limb(parts, h, Vector3(0, 0.035, -0.005), Vector3(0.11, 0.12, 0.11), skin.darkened(0.1), Vector2(0.95, 0.95), Vector2.ONE, 0.0, 1)
	var head := ell(parts, h, Vector3(0, 0.205, 0.0), Vector3(0.27, 0.32, 0.28), skin.lightened(0.03), shadow, 8, 6, 0.7)
	head["chin"] = 0.18
	parts["_kind"] = "box"
	bx(parts, h, Vector3(0, 0.175, 0.135), Vector3(0.042, 0.075, 0.05), skin.darkened(0.04), Vector2(0.55, 0.3), Vector2(1.0, 1.0), Vector3(-8, 0, 0), 0.25)
	parts["_kind"] = "quad"
	# brow shadow band where eyes would be (painted, no eyes), mouth, cheek blush
	bx(parts, h, Vector3(0, 0.235, 0.123), Vector3(0.17, 0.035, 0.01), skin.darkened(0.3), Vector2(1.0, 1.0), Vector2(0.85, 1.0), Vector3(-8, 0, 0), 0.25)
	bx(parts, h, Vector3(0, 0.112, 0.125), Vector3(0.07, 0.016, 0.01), Color(0.42, 0.20, 0.17), Vector2(1.1, 1), Vector2(0.9, 1), Vector3(14, 0, 0), 0.0)
	parts["_kind"] = ""
	parts["_ess"] = false
	var head_item := item(str(gear.get("head", "")))
	var hs := str(head_item.get("style", ""))
	var covers := hs in ["hood", "crest", "kettle"]
	var cap := hs in ["cap", "brim"]
	if not covers:
		parts["_kind"] = "quad"
		for sx in [-1.0, 1.0]:
			bx(parts, h, Vector3(sx * 0.133, 0.19, 0.0), Vector3(0.05, 0.075, 0.0), skin.darkened(0.1), Vector2(0.8, 1), Vector2(0.9, 1), Vector3(0, sx * 90.0, 0), 0.2)
		parts["_kind"] = ""
	_hair(parts, P, covers, cap)
	if P["beard"]:
		var hc: Color = P["hair_col"]
		var bd := ell(parts, h, Vector3(0, 0.1, 0.055), Vector3(0.24, 0.17, 0.2), hc, hc.darkened(0.2), 6, 4, 0.55)
		bd["chin"] = 0.25
	parts["_ess"] = true
	for s in ["l", "r"]:
		var sx := 1.0 if s == "l" else -1.0
		# Upper arm with a rounded shoulder cap (sleeve colour at the top).
		var up: Color = pt["upper"]
		loft(parts, "arm_" + s, [
			[0.055, 0.04 * L, 0.045 * L, up],
			[-0.02, 0.06 * L, 0.063 * L, up.darkened(0.03)],
			[-0.3, 0.05 * L, 0.052 * L, (pt["upper_lo"] as Color).darkened(0.08)],
		], 6)
		limb(parts, "fore_" + s, Vector3(0, -0.12, 0), Vector3(0.1 * L, 0.26, 0.1 * L), pt["fore"], Vector2(1.0, 1.0), Vector2(0.78, 0.74), 0.1, 1)
		# Mitten hand with a thumb.
		var hc2: Color = pt["hand"]
		var hand := limb(parts, "fore_" + s, Vector3(0, -0.305, 0.008), Vector3(0.085, 0.13, 0.075), hc2.lightened(0.02), Vector2(0.95, 0.95), Vector2(0.72, 0.6), 0.15, 1, 0.15)
		hand["main"] = true
		parts["_kind"] = "box"
		bx(parts, "fore_" + s, Vector3(-sx * 0.0, -0.285, 0.05), Vector3(0.035, 0.07, 0.035), hc2.darkened(0.05), Vector2(0.7, 0.7), Vector2.ONE, Vector3(-25, 0, 0))
		parts["_kind"] = ""
		# Thick thigh (shorts on top) and a calf with a bulge, bare foot with a toe.
		loft(parts, "leg_" + s, [
			[0.04, 0.085, 0.09, pt["thigh"]],
			[-0.1, 0.094, 0.1, (pt["thigh"] as Color).darkened(0.04)],
			[-0.43, 0.06, 0.066, (pt["knee"] as Color).darkened(0.1)],
		], 6)
		limb(parts, "shin_" + s, Vector3(0, -0.2, 0), Vector3(0.12, 0.42, 0.13), pt["calf"], Vector2(1.0, 1.0), Vector2(0.65, 0.68), 0.16, 2)
		# Foot (a boot gets a bigger rounded toe).
		var boot: bool = pt["boot"]
		var fs := Vector3(0.13, 0.09, 0.27) if boot else Vector3(0.11, 0.07, 0.23)
		var foot := limb(parts, "shin_" + s, Vector3(0, -0.44, 0.05), fs, (pt["foot"] as Color).darkened(0.04), Vector2(0.85, 0.8), Vector2(1.0, 1.0), 0.0, 1, 0.3)
		foot["main"] = true
		if boot:
			foot["sides"] = 8
	parts["_ess"] = false


static func _hair(parts: Dictionary, P: Dictionary, covered: bool, cap: bool) -> void:
	var hc: Color = P["hair_col"]
	var style: String = P["hair"]
	var h := "head"
	if covered or style == "bald":
		return
	var dark := hc.darkened(0.25)
	if not cap:
		# Sculpted skull cap of hair, swept a little back, with a fringe.
		dome(parts, h, Vector3(0, 0.235, -0.012), Vector3(0.295, 0.15, 0.305), hc.lightened(0.06), hc, 8, 3)
		parts["_kind"] = "box"
		bx(parts, h, Vector3(0, 0.3, 0.12), Vector3(0.2, 0.05, 0.05), hc, Vector2(1, 1), Vector2(0.8, 1.0), Vector3(-25, 0, 0))
		parts["_kind"] = ""
	# Back and sides of the hair: a rounded shell behind the ears.
	var back := ell(parts, h, Vector3(0, 0.22, -0.05), Vector3(0.29, 0.26, 0.22), hc, dark, 6, 4, 0.9)
	match style:
		"long":
			limb(parts, h, Vector3(0, 0.05, -0.11), Vector3(0.26, 0.28, 0.08), hc, Vector2(1, 1), Vector2(0.8, 1.1), 0.05, 1, 0.3)
		"topknot":
			if not cap:
				ell(parts, h, Vector3(0, 0.41, -0.05), Vector3(0.09, 0.09, 0.09), hc, dark, 6, 4)
		"shag":
			limb(parts, h, Vector3(0, 0.1, -0.1), Vector3(0.28, 0.12, 0.1), hc, Vector2(1, 1), Vector2(1.1, 1.0), 0.0, 1, 0.3)
		"braid":
			limb(parts, h, Vector3(0, 0.06, -0.16), Vector3(0.07, 0.16, 0.07), hc, Vector2(0.9, 0.9), Vector2(0.8, 0.8), 0.15, 1)
			limb(parts, h, Vector3(0, -0.08, -0.17), Vector3(0.06, 0.14, 0.06), dark, Vector2(0.9, 0.9), Vector2(0.6, 0.6), 0.15, 1)


static func _weapon(parts: Dictionary, weapon: String) -> void:
	var f := "fore_r"
	parts["_kind"] = "" if weapon == "staff" else "box"
	match weapon:
		"staff":
			var wood := Color(0.42, 0.30, 0.18)
			bx(parts, f, Vector3(0, -0.28, 0.07), Vector3(0.045, 1.55, 0.045), wood, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.1)
			bx(parts, f, Vector3(0, 0.46, 0.07), Vector3(0.08, 0.06, 0.08), Color(0.62, 0.5, 0.3))
		"sword":
			# Steel arming sword in a lowered grip: the blade runs down and forward from
			# the fist, so it rests along the leg and rises overhead in a slash.
			var steel := Color(0.70, 0.71, 0.72)
			var brass := Color(0.66, 0.52, 0.26)
			var hand := Vector3(0, -0.33, 0.03)
			var d := Vector3(0, -cos(deg_to_rad(30.0)), sin(deg_to_rad(30.0)))
			var r := Vector3(-30, 0, 0)
			bx(parts, f, hand - d * 0.02, Vector3(0.04, 0.16, 0.04), Color(0.30, 0.20, 0.12), Vector2.ONE, Vector2.ONE, r)
			bx(parts, f, hand - d * 0.12, Vector3(0.06, 0.05, 0.06), brass, Vector2.ONE, Vector2.ONE, r)
			bx(parts, f, hand + d * 0.07, Vector3(0.24, 0.04, 0.05), brass, Vector2.ONE, Vector2.ONE, r, 0.3)
			bx(parts, f, hand + d * 0.46, Vector3(0.075, 0.74, 0.025), steel, Vector2.ONE, Vector2(0.85, 1), r, 0.35)
			bx(parts, f, hand + d * 0.88, Vector3(0.064, 0.1, 0.022), steel.lightened(0.1), Vector2.ONE, Vector2(0.15, 0.6), r, 0.2)
		"crossbow":
			# Wooden stock along the forearm (it hangs at the side, and points ahead when
			# raised to aim), a horn bow across the front, the string, and a bone arrow on top.
			var wood2 := Color(0.40, 0.27, 0.15)
			var horn := Color(0.30, 0.22, 0.14)
			var bone := Color(0.90, 0.86, 0.74)
			bx(parts, f, Vector3(0, -0.42, 0.06), Vector3(0.07, 0.62, 0.08), wood2, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.25)
			bx(parts, f, Vector3(0, -0.22, 0.0), Vector3(0.06, 0.08, 0.12), wood2.darkened(0.1))
			bx(parts, f, Vector3(0, -0.70, 0.07), Vector3(0.56, 0.06, 0.045), horn, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.3)
			bx(parts, f, Vector3(0.31, -0.665, 0.07), Vector3(0.12, 0.05, 0.04), horn, Vector2.ONE, Vector2.ONE, Vector3(0, 0, -25))
			bx(parts, f, Vector3(-0.31, -0.665, 0.07), Vector3(0.12, 0.05, 0.04), horn, Vector2.ONE, Vector2.ONE, Vector3(0, 0, 25))
			bx(parts, f, Vector3(0, -0.55, 0.075), Vector3(0.66, 0.012, 0.012), Color(0.82, 0.78, 0.66), Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
			bx(parts, f, Vector3(0, -0.56, 0.115), Vector3(0.025, 0.40, 0.025), bone, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.1)
			bx(parts, f, Vector3(0, -0.78, 0.115), Vector3(0.05, 0.06, 0.045), bone.lightened(0.05), Vector2.ONE, Vector2(0.1, 0.1), Vector3.ZERO, 0.15)


static func _staff_glow(nodes: Dictionary) -> void:
	# The staff crystal stays its own small glowing mesh so it can shine.
	var crystal := MeshInstance3D.new()
	crystal.name = "Crystal"
	var pm := PrismMesh.new(); pm.size = Vector3(0.1, 0.18, 0.1)
	crystal.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.75, 0.85)
	m.emission_enabled = true; m.emission = Color(0.25, 0.7, 0.9); m.emission_energy_multiplier = 1.3
	crystal.material_override = m
	crystal.position = Vector3(0, 0.58, 0.07)
	nodes["fore_r"].add_child(crystal)


# ---------------------------------------------------------------- gear pieces

## N64-style clothing: most cloth and armour is PAINTED onto the body's own
## vertex colours (like the real late-90s models), so a full outfit costs few
## extra triangles. Only silhouette pieces (skirts, robes, helmets, pauldrons,
## cuffs, cloaks) and painted trim add geometry.
static func _paint(P: Dictionary, gear: Dictionary, tints: Dictionary) -> Dictionary:
	var skin: Color = P["skin"]
	var under: Color = P["under"]
	var shorts: Color = P["shorts"]
	var pt := {"hip": shorts, "waist": under, "chest": under, "shoulder": under, "upper": under,
		"upper_lo": skin, "fore": skin, "hand": skin, "thigh": shorts, "knee": skin, "calf": skin,
		"foot": skin, "boot": false}
	var get_it := func(slot: String) -> Dictionary:
		var id := str(gear.get(slot, ""))
		if id == "":
			return {}
		var it := item(id)
		if it.is_empty():
			return {}
		if tints.has(slot):
			it = it.duplicate()
			it["color"] = tints[slot]
		return it
	var c: Color
	var it: Dictionary = get_it.call("pants")
	if not it.is_empty():
		c = col(it.get("color", "#6b5a44"))
		var st := str(it.get("style", ""))
		pt["hip"] = c
		if st != "kilt":
			pt["thigh"] = c; pt["knee"] = c
			pt["calf"] = Color(0.78, 0.72, 0.6) if st == "breeches" else c.darkened(0.05)
	it = get_it.call("shirt")
	if not it.is_empty():
		c = col(it.get("color", "#6b5a44"))
		pt["waist"] = c; pt["chest"] = c; pt["shoulder"] = c
		if str(it.get("style", "")) != "vest":
			pt["upper"] = c
		if str(it.get("style", "")) in ["smock", "quilted", "doublet"]:
			pt["upper_lo"] = c; pt["fore"] = c.darkened(0.04)
	it = get_it.call("cuirass")
	if not it.is_empty():
		c = col(it.get("color", "#6b5a44"))
		pt["chest"] = c; pt["shoulder"] = c.lightened(0.05)
		if str(it.get("style", "")) != "chain":
			pt["waist"] = c.darkened(0.08)
		else:
			pt["waist"] = c; pt["upper"] = c
	it = get_it.call("greaves")
	if not it.is_empty():
		c = col(it.get("color", "#6b5a44"))
		pt["calf"] = c
		if str(it.get("style", "")) in ["plate", "brass", "chain"]:
			pt["knee"] = c
		if str(it.get("style", "")) == "chain":
			pt["thigh"] = c
	it = get_it.call("boots")
	if not it.is_empty():
		c = col(it.get("color", "#6b5a44"))
		var bs := str(it.get("style", ""))
		if bs != "sandals":
			pt["foot"] = c
			pt["boot"] = true
		if bs in ["tall", "fur", "sabatons"]:
			pt["calf"] = c.darkened(0.04)
	for g in ["glove_l", "glove_r"]:
		it = get_it.call(g)
		if not it.is_empty():
			c = col(it.get("color", "#6b5a44"))
			var gs := str(it.get("style", ""))
			if gs != "bracer":
				pt["hand"] = c
			if gs in ["bracer", "gauntlet", "chitin"]:
				pt["fore"] = c
	it = get_it.call("robe")
	if not it.is_empty() and str(it.get("style", "")) in ["robe", "coat"]:
		c = col(it.get("color", "#6b5a44"))
		pt["waist"] = c; pt["chest"] = c; pt["shoulder"] = c; pt["upper"] = c
		pt["upper_lo"] = c; pt["fore"] = c.darkened(0.05)
	return pt


## Open flared cylinder (skirts, sleeves, cuffs, bands): 8 or 6 sides, no end caps.
static func skirt(parts: Dictionary, part: String, c: Vector3, s: Vector3, color: Color,
		flare := 1.3, sides := 8, shade := 0.3) -> Dictionary:
	var sh := limb(parts, part, c, s, color, Vector2.ONE, Vector2(flare, flare), 0.0, 1, shade)
	sh["sides"] = sides
	sh["caps"] = false
	return sh


static func trim(parts: Dictionary, part: String, c: Vector3, s: Vector3, color: Color, rot := Vector3.ZERO) -> Dictionary:
	parts["_kind"] = "quad"
	var r := rot
	if c.z < 0.0:
		r = rot + Vector3(0, 180, 0)
	var sh := bx(parts, part, c, s, color, Vector2.ONE, Vector2.ONE, r, 0.0)
	parts["_kind"] = ""
	return sh


static func _draw_item(parts: Dictionary, P: Dictionary, slot: String, it: Dictionary) -> void:
	var c := col(it.get("color", "#6b5a44"))
	var t := col(it.get("trim", ""), c.darkened(0.3))
	var style := str(it.get("style", ""))
	var sw: float = P["sw"]; var hw: float = P["hw"]; var L: float = P["limb"]; var belly: float = P["belly"]
	var side := slot.right(1)
	var sx := 1.0 if side == "l" else -1.0
	var fz := 0.142 + belly * 0.9   # front of the chest for painted trim
	match slot:
		"head":
			_head_item(parts, style, c, t)
		"shirt":
			match style:
				"tunic", "smock":
					# Body-shaped tunic with a flared skirt.
					skirt(parts, "chest", Vector3(0, -0.04, belly * 0.4), Vector3(hw + 0.05 + belly, 0.2, 0.235 + belly), c.darkened(0.05), 1.22)
					trim(parts, "chest", Vector3(0, 0.47, 0.115), Vector3(0.12, 0.05, 0.0), t)
				"vest":
					for s2 in [-1.0, 1.0]:
						trim(parts, "chest", Vector3(s2 * sw * 0.16, 0.3, fz), Vector3(sw * 0.2, 0.32, 0.0), t)
				"quilted":
					for i in 3:
						trim(parts, "chest", Vector3(0, 0.22 + i * 0.09, fz), Vector3(sw * 0.75, 0.014, 0.0), t)
				"doublet":
					trim(parts, "chest", Vector3(0, 0.3, fz), Vector3(0.03, 0.3, 0.0), t)
		"pants":
			if style == "kilt":
				var k := skirt(parts, "chest", Vector3(0, -0.1, belly * 0.3), Vector3(hw + 0.07 + belly, 0.34, 0.25 + belly), c, 1.28)
				k["main"] = true
				trim(parts, "chest", Vector3(0, -0.24, 0.16 + belly * 0.5), Vector3(0.18, 0.04, 0.0), t)
		"boots":
			for s5 in ["l", "r"]:
				match style:
					"sandals":
						var so := limb(parts, "shin_" + s5, Vector3(0, -0.478, 0.05), Vector3(0.13, 0.025, 0.25), c, Vector2.ONE, Vector2.ONE, 0.0, 1, 0.1)
						so["main"] = true
					"tall", "fur":
						var cf := skirt(parts, "shin_" + s5, Vector3(0, -0.05, 0), Vector3(0.15, 0.08, 0.16), t if style == "tall" else t.lightened(0.15), 1.12, 6, 0.2)
						cf["main"] = true
					"sabatons":
						for i in 2:
							trim(parts, "shin_" + s5, Vector3(0, -0.42, 0.175 - i * 0.05), Vector3(0.12, 0.018, 0.0), t, Vector3(-60, 0, 0))
		"greaves":
			for s6 in ["l", "r"]:
				var kc := dome(parts, "shin_" + s6, Vector3(0, 0.0, 0.035), Vector3(0.13, 0.07, 0.1), t, t.darkened(0.3), 5, 1, Vector3(70, 0, 0))
				kc["main"] = true
		"cuirass":
			match style:
				"chain":
					skirt(parts, "chest", Vector3(0, 0.0, belly * 0.4), Vector3(hw + 0.06 + belly, 0.14, 0.24 + belly), c.darkened(0.06), 1.15)
				"leather":
					trim(parts, "chest", Vector3(0, 0.32, fz + 0.003), Vector3(0.025, 0.3, 0.0), t)
					trim(parts, "chest", Vector3(0, 0.18, fz - 0.01), Vector3(hw * 0.9, 0.025, 0.0), t)
				_:
					# Rounded breastplate shell plus flared tassets.
					var bp := limb(parts, "chest", Vector3(0, 0.33, belly * 0.4 + 0.005), Vector3(sw * 0.97 + 0.02, 0.3, 0.29 + belly), c.lightened(0.06), Vector2(0.92, 0.8), Vector2(0.88, 0.92), 0.06, 1, 0.3)
					bp["sides"] = 8; bp["caps"] = false; bp["main"] = true
					skirt(parts, "chest", Vector3(0, 0.02, belly * 0.4), Vector3(hw + 0.07 + belly, 0.16, 0.25 + belly), c.darkened(0.08), 1.2)
					if style == "scale":
						for i in 3:
							trim(parts, "chest", Vector3(0, 0.24 + i * 0.075, 0.17 + belly * 0.4), Vector3(sw * 0.7 - i * 0.02, 0.014, 0.0), t)
					if style == "brass":
						trim(parts, "chest", Vector3(0, 0.28, 0.17 + belly * 0.5), Vector3(sw * 0.7, 0.03, 0.0), t)
						trim(parts, "chest", Vector3(0, 0.40, 0.165 + belly * 0.5), Vector3(sw * 0.6, 0.03, 0.0), t)
		"belt":
			var bw := hw * 0.98 + 0.03 + belly
			var y := 0.12
			var band := skirt(parts, "chest", Vector3(0, y, belly * 0.5), Vector3(bw, 0.05 if style != "sash" else 0.08, 0.23 + belly), c, 1.0, 8, 0.15)
			band["main"] = true
			match style:
				"rope":
					trim(parts, "chest", Vector3(0.06, y - 0.07, 0.125 + belly), Vector3(0.025, 0.12, 0.0), c)
				"sash":
					trim(parts, "chest", Vector3(-0.08, y - 0.11, 0.125 + belly), Vector3(0.07, 0.18, 0.0), c.darkened(0.08))
				_:
					trim(parts, "chest", Vector3(0, y, 0.124 + belly), Vector3(0.06, 0.05, 0.0), t)
					if style == "pouches" or style == "coin":
						parts["_kind"] = "box"
						for s10 in [-1.0, 1.0]:
							bx(parts, "chest", Vector3(s10 * bw * 0.4, y - 0.06, 0.09), Vector3(0.07, 0.09, 0.05), t.darkened(0.2), Vector2(0.9, 0.9))
						parts["_kind"] = ""
		"glove_l", "glove_r":
			var f := "fore_" + side
			match style:
				"bracer":
					var br := skirt(parts, f, Vector3(0, -0.15, 0), Vector3(0.105 * L, 0.16, 0.105 * L), t, 1.0, 6, 0.2)
					br["main"] = true
				"gauntlet", "chitin":
					var gc := skirt(parts, f, Vector3(0, -0.2, 0), Vector3(0.115 * L, 0.1, 0.115 * L), c.lightened(0.05), 0.85, 6, 0.3)
					gc["main"] = true
				"leather":
					var lc := skirt(parts, f, Vector3(0, -0.225, 0), Vector3(0.1 * L, 0.05, 0.1 * L), t, 0.95, 6, 0.1)
					lc["main"] = true
		"pauldron_l", "pauldron_r":
			# Rounded shoulder guards: domes tipped out over the shoulder.
			var a := "arm_" + side
			var tilt := Vector3(0, 0, sx * 22.0)
			match style:
				"fur":
					var pf := dome(parts, a, Vector3(sx * 0.01, -0.02, 0), Vector3(0.22 * L, 0.12, 0.23 * L), c.lightened(0.05), c.darkened(0.2), 6, 2, tilt)
					pf["main"] = true
				"chitin", "layered", "brass":
					var p1 := dome(parts, a, Vector3(sx * 0.015, 0.0, 0), Vector3(0.22 * L, 0.1, 0.23 * L), c, c.darkened(0.3), 6, 2, tilt)
					p1["main"] = true
					dome(parts, a, Vector3(sx * 0.04, -0.07, 0), Vector3(0.2 * L, 0.07, 0.22 * L), c.darkened(0.08), c.darkened(0.3), 6, 1, tilt)
				_:
					var pd := dome(parts, a, Vector3(sx * 0.01, -0.03, 0), Vector3(0.23 * L, 0.13, 0.24 * L), c.lightened(0.06), c.darkened(0.25), 6, 2, tilt)
					pd["main"] = true
		"robe":
			match style:
				"robe", "coat":
					var length := 0.9 if style == "robe" else 0.62
					var cy := 0.12 - length * 0.5
					var rb := skirt(parts, "chest", Vector3(0, cy, belly * 0.3), Vector3(hw + 0.07 + belly, length, 0.25 + belly), c.darkened(0.04), 1.55)
					rb["main"] = true
					trim(parts, "chest", Vector3(0, cy, 0.17 + belly * 0.5), Vector3(0.05, length, 0.0), t, Vector3(-11, 0, 0))
					for s11 in ["l", "r"]:
						skirt(parts, "fore_" + s11, Vector3(0, -0.17, 0), Vector3(0.12 * L, 0.14, 0.12 * L), c.darkened(0.06), 1.35, 6)
				"cloak":
					var ck := limb(parts, "chest", Vector3(0, -0.02, -0.165 - belly * 0.3), Vector3(sw + 0.14, 1.0, 0.06), c, Vector2(0.8, 1), Vector2(1.2, 1), 0.0, 1, 0.3)
					ck["rot"] = Vector3(7, 0, 0); ck["sides"] = 8; ck["main"] = true
					skirt(parts, "chest", Vector3(0, 0.49, -0.01), Vector3(sw * 0.62, 0.07, 0.24), c.lightened(0.05), 1.25, 8, 0.2)
					trim(parts, "chest", Vector3(0, 0.47, 0.135), Vector3(0.05, 0.05, 0.0), t)
				"tabard":
					var tb1 := trim(parts, "chest", Vector3(0, 0.14, 0.15 + belly * 0.5), Vector3(sw * 0.55, 0.74, 0.0), c)
					tb1["main"] = true
					trim(parts, "chest", Vector3(0, 0.14, -0.15), Vector3(sw * 0.55, 0.74, 0.0), c)
					trim(parts, "chest", Vector3(0, 0.32, 0.153 + belly * 0.5), Vector3(sw * 0.26, 0.12, 0.0), t)
				"mantle":
					var mt := dome(parts, "chest", Vector3(0, 0.37, belly * 0.2), Vector3(sw + 0.18, 0.18, 0.34 + belly), c, c.darkened(0.2), 8, 2)
					mt["main"] = true
		"amulet":
			var z := 0.15 + belly * 0.5
			trim(parts, "chest", Vector3(0, 0.44, z - 0.012), Vector3(0.14, 0.012, 0.0), t)
			var am := trim(parts, "chest", Vector3(0, 0.38, z), Vector3(0.05 if style != "tooth" else 0.03, 0.06, 0.0), c)
			am["main"] = true
		"ring_l", "ring_r":
			parts["_kind"] = "box"
			var rg := bx(parts, "fore_" + side, Vector3(0, -0.33, 0.042), Vector3(0.045, 0.02, 0.02), c, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
			parts["_kind"] = ""
			rg["main"] = true


static func _head_item(parts: Dictionary, style: String, c: Color, t: Color) -> void:
	var h := "head"
	var dk := c.darkened(0.25)
	match style:
		"hood":
			# Sculpted deep hood: a rounded shell set back so the face shows, a soft
			# peak, a rim that shades the brow, and a drape over the shoulders. No eyes.
			var shell := ell(parts, h, Vector3(0, 0.235, -0.045), Vector3(0.345, 0.385, 0.33), c, dk, 8, 5, 0.92)
			shell["main"] = true
			ell(parts, h, Vector3(0, 0.40, -0.09), Vector3(0.14, 0.14, 0.15), c, c.darkened(0.1), 5, 3, 1.0, Vector3(-30, 0, 0))
			limb(parts, h, Vector3(0, 0.33, 0.085), Vector3(0.3, 0.05, 0.1), c.darkened(0.12), Vector2(0.9, 0.9), Vector2(1, 1), 0.0, 1, 0.3)
			limb(parts, h, Vector3(0, 0.0, -0.02), Vector3(0.34, 0.12, 0.3), c.darkened(0.08), Vector2(1, 1), Vector2(1.25, 1.2), 0.0, 1, 0.3)
		"cap":
			dome(parts, h, Vector3(0, 0.27, -0.01), Vector3(0.315, 0.13, 0.32), c, c.darkened(0.12), 8, 2)
			limb(parts, h, Vector3(0, 0.275, 0.0), Vector3(0.32, 0.035, 0.325), t, Vector2.ONE, Vector2.ONE, 0.0, 1, 0.1)
		"brim":
			dome(parts, h, Vector3(0, 0.28, 0.0), Vector3(0.3, 0.17, 0.3), c, c.darkened(0.1), 8, 2)
			limb(parts, h, Vector3(0, 0.29, 0.01), Vector3(0.52, 0.02, 0.5), c.darkened(0.08), Vector2.ONE, Vector2.ONE, 0.0, 1, 0.1)
			limb(parts, h, Vector3(0, 0.31, 0), Vector3(0.305, 0.035, 0.305), t, Vector2.ONE, Vector2.ONE, 0.0, 1, 0.1)
		"kettle":
			dome(parts, h, Vector3(0, 0.27, -0.01), Vector3(0.33, 0.18, 0.33), c, c.darkened(0.15), 8, 3)
			limb(parts, h, Vector3(0, 0.27, 0), Vector3(0.46, 0.025, 0.44), c.darkened(0.06), Vector2.ONE, Vector2(0.95, 0.95), 0.0, 1, 0.2)
			ell(parts, h, Vector3(0, 0.18, -0.08), Vector3(0.3, 0.2, 0.2), Color(0.42, 0.40, 0.38), Color(0.30, 0.29, 0.28), 6, 4)
		"crest":
			# Open-faced bronze helm, nose guard, cheek guards, crest. No eye slits.
			var helm := dome(parts, h, Vector3(0, 0.245, -0.01), Vector3(0.33, 0.2, 0.33), c, c.darkened(0.2), 8, 3)
			helm["main"] = true
			parts["_kind"] = "box"
			bx(parts, h, Vector3(0, 0.22, 0.155), Vector3(0.03, 0.11, 0.025), c.darkened(0.05))
			parts["_kind"] = ""
			for s2 in [-1.0, 1.0]:
				limb(parts, h, Vector3(s2 * 0.145, 0.15, 0.04), Vector3(0.04, 0.17, 0.13), c.darkened(0.08), Vector2(1, 1), Vector2(0.8, 0.7), 0.0, 1, 0.25)
			ell(parts, h, Vector3(0, 0.17, -0.09), Vector3(0.3, 0.22, 0.18), c.darkened(0.08), c.darkened(0.25), 6, 4)
			parts["_kind"] = "box"
			bx(parts, h, Vector3(0, 0.46, -0.02), Vector3(0.04, 0.09, 0.32), t, Vector2(1, 0.8), Vector2(1, 1), Vector3.ZERO, 0.2)
			parts["_kind"] = ""
			limb(parts, h, Vector3(0, 0.25, 0.0), Vector3(0.335, 0.03, 0.335), t, Vector2.ONE, Vector2.ONE, 0.0, 1, 0.1)


# ---------------------------------------------------------------- animation

## phase advances with distance walked; amount 0 = idle, 1 = full stride.
## A real walk, not a pendulum: the swing leg lifts with a bent knee, the
## stance leg stays nearly straight, the heel strikes ahead of the body, the
## hips dip twice per stride, the torso counter-turns and leans in, and the
## arms swing opposite the legs with a soft elbow that bends more going forward.
## Actions (body meta "action" = "slash" | "aim" | "shoot" | "cast", "action_t" 0..1)
## play on top of the walk for the upper body.
static func animate(body: Node3D, phase: float, amount: float, t := 0.0) -> void:
	if body == null:
		return
	var a := clampf(amount, 0.0, 1.0)
	var s := sin(phase)
	var idle := sin(t * 1.6) * 0.03 * (1.0 - a)
	# Thighs (negative x = forward): forward reach is bigger than the back push,
	# so the heel lands ahead of the body.
	var fl := s
	var fr := -s
	_rx(body, "LegL", -(0.52 if fl > 0.0 else 0.34) * fl * a)
	_rx(body, "LegR", -(0.52 if fr > 0.0 else 0.34) * fr * a)
	# Knees (positive x = bend) fold most while that leg swings through, and stay
	# almost straight while it carries the weight.
	_rx(body, "LegL/ShinL", (maxf(0.0, cos(phase + 0.3)) * 1.0 + 0.06) * a)
	_rx(body, "LegR/ShinR", (maxf(0.0, cos(phase + PI + 0.3)) * 1.0 + 0.06) * a)
	# Arms opposite the legs; forearms bend more on the forward swing.
	var arm := 0.5 * s * a
	_rx(body, "ArmL", arm + idle)
	_rx(body, "ArmR", -arm - idle)
	_rx(body, "ArmL/ForeL", -0.22 - maxf(0.0, -s) * 0.45 * a)
	_rx(body, "ArmR/ForeR", -0.22 - maxf(0.0, s) * 0.45 * a)
	_rz(body, "ArmL", 0.04)
	_rz(body, "ArmR", -0.04)
	var hips := body.get_node_or_null("Hips")
	if hips:
		# Two dips per stride: low at heel strike, high when the legs pass.
		hips.position.y = 0.92 - absf(cos(phase)) * 0.045 * a + 0.02 * a + idle * 0.3
		hips.rotation.y = -s * 0.10 * a
		hips.rotation.x = 0.06 * a
		hips.rotation.z = cos(phase) * 0.03 * a
	var head := body.get_node_or_null("Head")
	if head:
		head.position.y = 1.45 - absf(cos(phase)) * 0.045 * a + 0.02 * a
	for n in ["ArmL", "ArmR"]:
		var nd: Node3D = body.get_node_or_null(n)
		if nd:
			nd.position.y = 1.38 - absf(cos(phase)) * 0.045 * a + 0.02 * a
	_action(body)


static func _action(body: Node3D) -> void:
	var act := str(body.get_meta("action", ""))
	if act == "":
		return
	var k := clampf(float(body.get_meta("action_t", 0.0)), 0.0, 1.0)
	match act:
		"slash":
			# Wind up high over the right shoulder, then cut down and across.
			var up := smoothstep(0.0, 0.35, k)
			var cut := smoothstep(0.35, 0.7, k)
			var back := smoothstep(0.7, 1.0, k)
			var ax := lerpf(lerpf(0.0, -2.6, up), -0.5, cut)
			ax = lerpf(ax, 0.0, back)
			_rx(body, "ArmR", ax)
			_rz(body, "ArmR", lerpf(lerpf(-0.04, -0.5, up), 0.35, cut) * (1.0 - back))
			_rx(body, "ArmR/ForeR", lerpf(-0.9 * up, -0.2, cut))
			var hips := body.get_node_or_null("Hips")
			if hips:
				hips.rotation.y += lerpf(0.25 * up, -0.35, cut) * (1.0 - back)
		"aim", "shoot":
			# Crossbow at the shoulder, both hands on it; a kick on the shot.
			var kick := sin(k * PI) * 0.25 if act == "shoot" else 0.0
			_rx(body, "ArmR", -1.25 - kick)
			_rx(body, "ArmR/ForeR", -0.30)
			_rz(body, "ArmR", 0.22)
			_rx(body, "ArmL", -1.05 - kick)
			_rx(body, "ArmL/ForeL", -0.75)
			_rz(body, "ArmL", -0.55)
		"cast":
			# Right hand thrown forward, fingers first (lightning leaves the fingertips).
			var push := smoothstep(0.0, 0.3, k) * (1.0 - smoothstep(0.75, 1.0, k))
			_rx(body, "ArmR", -1.5 * push)
			_rx(body, "ArmR/ForeR", -0.1 * push)
			_rx(body, "ArmL", -0.5 * push)


static func _rx(body: Node3D, path: String, a: float) -> void:
	var n := body.get_node_or_null(path)
	if n:
		n.rotation.x = a


static func _rz(body: Node3D, path: String, a: float) -> void:
	var n := body.get_node_or_null(path)
	if n:
		n.rotation.z = a


# ---------------------------------------------------------------- crowd helper

## Random townsperson for a role. rng keeps the town the same each load.
static func random_params(role: String, rng: RandomNumberGenerator) -> Dictionary:
	var skin: Color = SKIN[rng.randi() % SKIN.size()]
	var hair: String = HAIR_STYLES[rng.randi() % HAIR_STYLES.size()]
	var hc: Color = HAIR_COLORS[rng.randi() % HAIR_COLORS.size()]
	var builds := ["slim", "average", "average", "broad", "stout"]
	var p := {
		"skin": skin, "hair": hair, "hair_color": hc, "beard": rng.randf() < 0.35,
		"build": builds[rng.randi() % builds.size()], "height": rng.randf_range(0.92, 1.06),
		"under": Color(0.78, 0.72, 0.6).darkened(rng.randf_range(0.0, 0.2)),
		"gear": {}
	}
	var pick := func(options: Array) -> String:
		return str(options[rng.randi() % options.size()])
	var g: Dictionary = p["gear"]
	match role:
		"guard":
			p["build"] = "broad" if rng.randf() < 0.6 else "average"
			g["head"] = pick.call(["saltiron_kettle", "bronze_crest_helm"])
			g["shirt"] = "quilted_gambeson"
			g["cuirass"] = pick.call(["rusted_chain_shirt", "harbor_plate", "brass_banded"])
			g["pants"] = "dock_trousers"
			g["greaves"] = pick.call(["harbor_plate_greaves", "chain_leggings"])
			g["boots"] = "tall_riding_boots"
			g["pauldron_l"] = pick.call(["harbor_plate_pauldron", "round_iron_pauldron"])
			g["pauldron_r"] = g["pauldron_l"]
			g["glove_l"] = "leather_gloves"; g["glove_r"] = "leather_gloves"
			g["belt"] = "plain_leather_belt"
		"sailor":
			g["head"] = pick.call(["dockhand_cap", "", ""])
			g["shirt"] = pick.call(["fisher_smock", "linen_tunic", "patchwork_vest"])
			g["pants"] = pick.call(["sailor_wide_trousers", "knee_breeches"])
			g["boots"] = pick.call(["reed_sandals", "low_shoes"])
			g["belt"] = "rope_belt"
			if rng.randf() < 0.5:
				g["glove_l"] = "cloth_wraps"; g["glove_r"] = "cloth_wraps"
		"merchant":
			g["head"] = pick.call(["ledger_brim_hat", "", "dockhand_cap"])
			g["shirt"] = pick.call(["silk_doublet", "linen_tunic"])
			g["robe"] = pick.call(["market_coat", "", "shoulder_mantle"])
			g["pants"] = pick.call(["dock_trousers", "padded_hose"])
			g["boots"] = "low_shoes"
			g["belt"] = "coin_pouch_belt"
			g["amulet"] = pick.call(["", "copper_disc"])
		"banker":
			p["build"] = pick.call(["stout", "average"])
			g["head"] = "ledger_brim_hat"
			g["shirt"] = "silk_doublet"
			g["robe"] = "counting_robe"
			g["pants"] = "dock_trousers"
			g["boots"] = "low_shoes"
			g["belt"] = "coin_pouch_belt"
			g["amulet"] = "ledger_key"
			g["ring_l"] = "brass_signet"
		_:
			g["shirt"] = pick.call(["linen_tunic", "fisher_smock", "patchwork_vest", "quilted_gambeson"])
			g["pants"] = pick.call(["dock_trousers", "knee_breeches", "weaver_kilt", "sailor_wide_trousers"])
			g["boots"] = pick.call(["reed_sandals", "low_shoes", "tall_riding_boots"])
			g["belt"] = pick.call(["rope_belt", "plain_leather_belt", "dyed_sash"])
			if rng.randf() < 0.3:
				g["head"] = pick.call(["dockhand_cap", "pilgrim_hood", "ledger_brim_hat"])
			if rng.randf() < 0.25:
				g["robe"] = pick.call(["shoulder_mantle", "traveler_cloak", "market_coat"])
	for k in g.keys():
		if str(g[k]) == "":
			g.erase(k)
	return p
