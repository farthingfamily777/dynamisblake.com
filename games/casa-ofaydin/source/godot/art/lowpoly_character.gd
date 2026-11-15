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
		_mat.roughness = 0.95
		_mat.metallic_specular = 0.2
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
	# Pick boxes for each LOD and build one skinned mesh per LOD.
	var boxes: Array = parts["_boxes"]
	_drop_hidden(boxes)
	_cull_faces(boxes)
	body.set_meta("tris_wanted", _tris(boxes))
	var lod0 := _fit(boxes, LOD0_CAP, false)
	var lod1 := _fit(boxes, LOD1_CAP, true)
	var tri0 := _tris(lod0)
	var tri1 := _tris(lod1)
	for lod in [[lod0, "LOD0"], [lod1, "LOD1"]]:
		var mi := MeshInstance3D.new()
		mi.name = lod[1]
		mi.mesh = _commit(lod[0], rest)
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


# ---------------------------------------------------------------- box primitive

## Tapered, rotatable box with flat faces and a top-to-bottom color fade.
## tt / tb scale the top / bottom face (x, z). rot is degrees.
## Boxes are recorded first; build() picks which ones fit each LOD's budget.
static func bx(parts: Dictionary, part: String, c: Vector3, s: Vector3, color: Color,
		tt := Vector2.ONE, tb := Vector2.ONE, rot := Vector3.ZERO, shade := 0.22) -> void:
	var area := s.x * s.y + s.y * s.z + s.x * s.z
	parts["_boxes"].append({"part": part, "c": c, "s": s, "color": color, "tt": tt, "tb": tb,
		"rot": rot, "shade": shade, "area": area, "ess": bool(parts.get("_ess", false)),
		"order": parts["_boxes"].size(), "tris": 12, "main": false, "faces": [true, true, true, true, true, true]})


## Drop boxes sealed inside a bigger box on the same part (skin under sleeves, etc.).
static func _drop_hidden(boxes: Array) -> void:
	var keep: Array = []
	for a in boxes:
		var hidden := false
		for b in boxes:
			if b == a or b["part"] != a["part"] or b["area"] <= a["area"] or b["rot"] != Vector3.ZERO:
				continue
			if _inside_all(a, b):
				hidden = true
				break
		if not hidden:
			keep.append(a)
	boxes.clear()
	boxes.append_array(keep)


const FACES := [[0, 1, 2, 3], [4, 7, 6, 5], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]]


## Drop single faces buried inside another box on the same part (the top of a
## shin inside a knee, a sleeve end inside a glove...). Saves triangles for gear.
static func _cull_faces(boxes: Array) -> void:
	var info := []
	for b in boxes:
		var cs := _corners(b)
		var r := 0.0
		for p in cs:
			r = maxf(r, (p - (b["c"] as Vector3)).length())
		info.append({"cs": cs, "r": r})
	for i in boxes.size():
		var a: Dictionary = boxes[i]
		var cs: Array = info[i]["cs"]
		var faces: Array = a["faces"]
		var n := 0
		for fi in 6:
			var f: Array = FACES[fi]
			for j in boxes.size():
				if j == i:
					continue
				var b: Dictionary = boxes[j]
				if b["part"] != a["part"] or b["rot"] != Vector3.ZERO:
					continue
				if ((a["c"] as Vector3) - (b["c"] as Vector3)).length() > info[i]["r"] + info[j]["r"]:
					continue
				var all_in := true
				for k in f:
					if not _point_in(cs[k], b, 0.003):
						all_in = false
						break
				if all_in:
					faces[fi] = false
					break
			if faces[fi]:
				n += 1
		a["tris"] = n * 2


static func _point_in(p: Vector3, b: Dictionary, tol: float) -> bool:
	var bs: Vector3 = b["s"]
	var l: Vector3 = p - (b["c"] as Vector3)
	var hy := bs.y * 0.5
	if absf(l.y) > hy + tol:
		return false
	var f := clampf((l.y + hy) / (2.0 * hy), 0.0, 1.0)
	var sx: float = lerpf(b["tb"].x, b["tt"].x, f) * bs.x * 0.5
	var sz: float = lerpf(b["tb"].y, b["tt"].y, f) * bs.z * 0.5
	return absf(l.x) <= sx + tol and absf(l.z) <= sz + tol


static func _corners(a: Dictionary) -> Array:
	var s: Vector3 = a["s"]; var tt: Vector2 = a["tt"]; var tb: Vector2 = a["tb"]
	var hx := s.x * 0.5; var hy := s.y * 0.5; var hz := s.z * 0.5
	var basis := Basis.from_euler(a["rot"] * (PI / 180.0))
	var out := []
	for v in [Vector3(-hx * tb.x, -hy, -hz * tb.y), Vector3(hx * tb.x, -hy, -hz * tb.y),
			Vector3(hx * tb.x, -hy, hz * tb.y), Vector3(-hx * tb.x, -hy, hz * tb.y),
			Vector3(-hx * tt.x, hy, -hz * tt.y), Vector3(hx * tt.x, hy, -hz * tt.y),
			Vector3(hx * tt.x, hy, hz * tt.y), Vector3(-hx * tt.x, hy, hz * tt.y)]:
		out.append(basis * v + a["c"])
	return out


static func _inside_all(a: Dictionary, b: Dictionary) -> bool:
	var bs: Vector3 = b["s"]; var bc: Vector3 = b["c"]
	var hy := bs.y * 0.5
	for p in _corners(a):
		var l: Vector3 = p - bc
		if absf(l.y) > hy - 0.002:
			return false
		var f := (l.y + hy) / (2.0 * hy)
		var sx: float = lerpf(b["tb"].x, b["tt"].x, f) * bs.x * 0.5
		var sz: float = lerpf(b["tb"].y, b["tt"].y, f) * bs.z * 0.5
		if absf(l.x) > sx - 0.002 or absf(l.z) > sz - 0.002:
			return false
	return true


## Keep boxes until the triangle cap. LOD0 keeps everything if it fits, then sheds
## the smallest trim first (never the body). LOD1 ranks purely by size.
static func _fit(boxes: Array, cap: int, far: bool) -> Array:
	var ranked := boxes.duplicate()
	if far:
		ranked.sort_custom(func(x, y): return x["area"] > y["area"])
	else:
		ranked.sort_custom(func(x, y):
			if x["ess"] != y["ess"]:
				return x["ess"]
			if x["main"] != y["main"]:
				return x["main"]
			return x["area"] > y["area"])
	var out: Array = []
	var n := 0
	for b in ranked:
		var t := int(b["tris"])
		if t == 0:
			continue
		if far and float(b["area"]) < 0.012:
			continue
		if n + t > cap:
			continue
		out.append(b)
		n += t
	out.sort_custom(func(x, y): return x["order"] < y["order"])
	return out


static func _tris(list: Array) -> int:
	var n := 0
	for b in list:
		n += int(b["tris"])
	return n


static func _commit(list: Array, rest: Dictionary) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [[0, 1, 2, 3], [4, 7, 6, 5], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]]
	var bones := PackedInt32Array([0, 0, 0, 0])
	var weights := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
	for a in list:
		var r: Dictionary = rest[a["part"]]
		var xf: Transform3D = r["xf"]
		bones[0] = int(r["bone"])
		var w := []
		for v in _corners(a):
			w.append(xf * v)
		var cc: Vector3 = xf * (a["c"] as Vector3)
		var color: Color = a["color"]
		var bot := color.darkened(float(a["shade"]))
		var cols := [bot, bot, bot, bot, color, color, color, color]
		var mask: Array = a["faces"]
		for fi in 6:
			if not mask[fi]:
				continue
			var f: Array = faces[fi]
			var fc: Vector3 = (w[f[0]] + w[f[1]] + w[f[2]] + w[f[3]]) * 0.25
			var out: Vector3 = fc - cc
			for tri in [[f[0], f[1], f[2]], [f[0], f[2], f[3]]]:
				var p0: Vector3 = w[tri[0]]; var p1: Vector3 = w[tri[1]]; var p2: Vector3 = w[tri[2]]
				var n := (p1 - p0).cross(p2 - p0)
				if n.length_squared() < 1e-14:
					n = out
				var order := [tri[0], tri[1], tri[2]]
				# Godot front faces are clockwise when seen from outside.
				if n.dot(out) > 0.0:
					order = [tri[0], tri[2], tri[1]]
					n = -n
				var nn := -n.normalized()
				for idx in order:
					st.set_normal(nn)
					st.set_color(cols[idx])
					st.set_bones(bones)
					st.set_weights(weights)
					st.add_vertex(w[idx])
	return st.commit()


# ---------------------------------------------------------------- body + underclothes

static func _body(parts: Dictionary, P: Dictionary, gear: Dictionary) -> void:
	var skin: Color = P["skin"]
	var sw: float = P["sw"]; var hw: float = P["hw"]; var limb: float = P["limb"]; var belly: float = P["belly"]
	var under: Color = P["under"]; var shorts: Color = P["shorts"]
	parts["_ess"] = true
	# chest part is local to Hips (y 0.92)
	bx(parts, "chest", Vector3(0, 0.04, 0), Vector3(hw, 0.17, 0.22), shorts, Vector2(1.02, 1.0), Vector2(0.95, 0.95))
	bx(parts, "chest", Vector3(0, 0.17, 0.0 + belly * 0.5), Vector3(hw * 0.92 + belly, 0.12, 0.2 + belly), under, Vector2(1.0, 1.0), Vector2(1.0, 1.0), Vector3.ZERO, 0.1)
	bx(parts, "chest", Vector3(0, 0.35, 0), Vector3(sw, 0.26, 0.25), under, Vector2(1.0, 1.0), Vector2(0.78, 0.86), Vector3.ZERO, 0.12)
	# trapezius / shoulder top in skin, neck base
	bx(parts, "chest", Vector3(0, 0.5, -0.01), Vector3(sw * 0.72, 0.05, 0.2), skin, Vector2(0.7, 0.8))
	# Head (local to neck pivot y 1.45)
	var h := "head"
	bx(parts, h, Vector3(0, 0.03, 0), Vector3(0.12, 0.09, 0.12), skin.darkened(0.08))
	bx(parts, h, Vector3(0, 0.2, 0), Vector3(0.29, 0.31, 0.28), skin, Vector2(1.0, 1.0), Vector2(0.8, 0.88), Vector3.ZERO, 0.12)
	# brow ridge: casts the shadow where eyes would be (no eyes drawn)
	bx(parts, h, Vector3(0, 0.255, 0.145), Vector3(0.26, 0.045, 0.04), skin.darkened(0.12), Vector2(1, 1), Vector2(1, 1), Vector3(-12, 0, 0), 0.35)
	# nose wedge
	bx(parts, h, Vector3(0, 0.18, 0.15), Vector3(0.05, 0.09, 0.05), skin.darkened(0.05), Vector2(0.6, 0.4), Vector2(1.0, 1.2), Vector3.ZERO, 0.25)
	# mouth
	bx(parts, h, Vector3(0, 0.1, 0.143), Vector3(0.09, 0.018, 0.012), Color(0.38, 0.18, 0.15), Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
	# cheeks / jaw planes for the faceted look
	# Ears hide under hoods and helms (they used to poke through as two dots).
	var hs := str(item(str(gear.get("head", ""))).get("style", ""))
	for sx in [-1.0, 1.0]:
		bx(parts, h, Vector3(sx * 0.1, 0.13, 0.12), Vector3(0.07, 0.08, 0.05), skin.darkened(0.04), Vector2(0.8, 0.8), Vector2(1, 1), Vector3(0, sx * 25.0, 0), 0.15)
		if not hs in ["hood", "crest", "kettle"]:
			bx(parts, h, Vector3(sx * 0.152, 0.19, 0.0), Vector3(0.03, 0.08, 0.06), skin.darkened(0.1))
	parts["_ess"] = false
	var head_item := item(str(gear.get("head", "")))
	var covers := str(head_item.get("style", "")) in ["hood", "crest", "kettle"]
	var cap := str(head_item.get("style", "")) in ["cap", "brim"]
	_hair(parts, P, covers, cap)
	if P["beard"]:
		var hc: Color = P["hair_col"]
		bx(parts, h, Vector3(0, 0.065, 0.11), Vector3(0.22, 0.1, 0.1), hc, Vector2(1.0, 1.0), Vector2(0.6, 0.7))
		bx(parts, h, Vector3(0, 0.125, 0.15), Vector3(0.12, 0.02, 0.02), hc)
	# Arms: short undershirt sleeve, skin below, oversized hands
	parts["_ess"] = true
	for s in ["l", "r"]:
		var t := limb
		bx(parts, "arm_" + s, Vector3(0, -0.02, 0), Vector3(0.15 * t, 0.12, 0.15 * t), under, Vector2(0.9, 0.9))
		bx(parts, "arm_" + s, Vector3(0, -0.16, 0), Vector3(0.12 * t, 0.26, 0.12 * t), skin, Vector2(1, 1), Vector2(0.88, 0.88))
		bx(parts, "fore_" + s, Vector3(0, -0.12, 0), Vector3(0.105 * t, 0.25, 0.105 * t), skin, Vector2(1, 1), Vector2(0.85, 0.85), Vector3.ZERO, 0.12)
		bx(parts, "fore_" + s, Vector3(0, -0.31, 0.01), Vector3(0.115, 0.13, 0.095), skin, Vector2(1, 1), Vector2(0.9, 0.8))
		# thumb block
		var sx := 1.0 if s == "l" else -1.0
		bx(parts, "fore_" + s, Vector3(-sx * 0.0, -0.29, 0.06), Vector3(0.04, 0.07, 0.04), skin.darkened(0.06))
		# Legs: shorts top, skin below, bare feet
		bx(parts, "leg_" + s, Vector3(0, -0.08, 0), Vector3(0.17, 0.17, 0.18), shorts, Vector2(1.0, 1.0), Vector2(0.95, 0.95))
		bx(parts, "leg_" + s, Vector3(0, -0.29, 0), Vector3(0.14, 0.26, 0.15), skin, Vector2(1, 1), Vector2(0.85, 0.85))
		bx(parts, "shin_" + s, Vector3(0, -0.2, 0), Vector3(0.12, 0.38, 0.13), skin, Vector2(1, 1), Vector2(0.8, 0.8))
		bx(parts, "shin_" + s, Vector3(0, -0.445, 0.04), Vector3(0.12, 0.08, 0.22), skin.darkened(0.06), Vector2(1.0, 0.8))
	parts["_ess"] = false


static func _hair(parts: Dictionary, P: Dictionary, covered: bool, cap: bool) -> void:
	var hc: Color = P["hair_col"]
	var style: String = P["hair"]
	var h := "head"
	if covered or style == "bald":
		return
	if not cap:
		bx(parts, h, Vector3(0, 0.37, -0.01), Vector3(0.31, 0.06, 0.3), hc, Vector2(0.9, 0.85))
		# chunky fringe blocks above the brow
		for i in 3:
			bx(parts, h, Vector3(-0.09 + i * 0.09, 0.33, 0.13), Vector3(0.09, 0.07, 0.05), hc.lightened(0.04 * i), Vector2(1, 1), Vector2(0.7, 1.0), Vector3(-15, 0, 0))
	# sides and back
	bx(parts, h, Vector3(0, 0.25, -0.13), Vector3(0.31, 0.2, 0.06), hc)
	for sx in [-1.0, 1.0]:
		bx(parts, h, Vector3(sx * 0.15, 0.28, -0.03), Vector3(0.03, 0.14, 0.2), hc)
	match style:
		"long":
			bx(parts, h, Vector3(0, 0.08, -0.15), Vector3(0.3, 0.3, 0.06), hc, Vector2(1, 1), Vector2(0.85, 1))
		"topknot":
			if not cap:
				bx(parts, h, Vector3(0, 0.44, -0.04), Vector3(0.1, 0.1, 0.1), hc, Vector2(0.7, 0.7))
		"shag":
			for i in 4:
				bx(parts, h, Vector3(-0.12 + i * 0.08, 0.12, -0.14), Vector3(0.07, 0.14, 0.05), hc.darkened(0.05 * (i % 2)))
		"braid":
			bx(parts, h, Vector3(0, 0.08, -0.17), Vector3(0.07, 0.16, 0.07), hc)
			bx(parts, h, Vector3(0, -0.06, -0.18), Vector3(0.06, 0.14, 0.06), hc.darkened(0.08))


static func _weapon(parts: Dictionary, weapon: String) -> void:
	var f := "fore_r"
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

static func _draw_item(parts: Dictionary, P: Dictionary, slot: String, it: Dictionary) -> void:
	var c := col(it.get("color", "#6b5a44"))
	var t := col(it.get("trim", ""), c.darkened(0.3))
	var style := str(it.get("style", ""))
	var sw: float = P["sw"]; var hw: float = P["hw"]; var L: float = P["limb"]; var belly: float = P["belly"]
	var side := slot.right(1)
	var sx := 1.0 if side == "l" else -1.0
	match slot:
		"head":
			_head_item(parts, style, c, t)
		"shirt":
			var long := style in ["smock", "quilted", "doublet"]
			bx(parts, "chest", Vector3(0, 0.34, belly * 0.3), Vector3(sw + 0.02, 0.36, 0.27 + belly), c, Vector2(1, 1), Vector2(0.78, 0.86), Vector3.ZERO, 0.15)
			bx(parts, "chest", Vector3(0, 0.12, belly * 0.5), Vector3(hw * 0.95 + 0.02 + belly, 0.14, 0.22 + belly), c.darkened(0.06))
			if style == "vest":
				bx(parts, "chest", Vector3(0, 0.3, 0.14 + belly * 0.5), Vector3(0.05, 0.4, 0.02), t)
				for s2 in [-1.0, 1.0]:
					bx(parts, "chest", Vector3(s2 * sw * 0.3, 0.3, 0.14), Vector3(sw * 0.26, 0.36, 0.02), t.lightened(0.05))
			else:
				for s3 in ["l", "r"]:
					bx(parts, "arm_" + s3, Vector3(0, -0.06, 0), Vector3(0.16 * L, 0.2, 0.16 * L), c, Vector2(0.95, 0.95))
					if long:
						bx(parts, "arm_" + s3, Vector3(0, -0.2, 0), Vector3(0.135 * L, 0.2, 0.135 * L), c.darkened(0.04))
						bx(parts, "fore_" + s3, Vector3(0, -0.11, 0), Vector3(0.12 * L, 0.24, 0.12 * L), c.darkened(0.06), Vector2(1, 1), Vector2(0.9, 0.9))
			if style == "quilted":
				for i in 4:
					bx(parts, "chest", Vector3(0, 0.2 + i * 0.08, 0.135 + belly * 0.3), Vector3(sw * 0.9, 0.012, 0.012), t, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
			if style == "doublet":
				for i in 4:
					bx(parts, "chest", Vector3(0, 0.2 + i * 0.08, 0.14 + belly * 0.3), Vector3(0.035, 0.03, 0.02), t)
			if style == "tunic":
				bx(parts, "chest", Vector3(0, 0.46, 0.11), Vector3(0.14, 0.05, 0.04), t)
		"pants":
			if style == "kilt":
				bx(parts, "chest", Vector3(0, -0.07, 0), Vector3(hw + 0.08, 0.36, 0.28), c, Vector2(1, 1), Vector2(1.18, 1.18), Vector3.ZERO, 0.25)
				for i in 3:
					bx(parts, "chest", Vector3(-0.1 + i * 0.1, -0.07, 0.15), Vector3(0.014, 0.34, 0.012), t, Vector2.ONE, Vector2(1.2, 1), Vector3.ZERO, 0.0)
			else:
				bx(parts, "chest", Vector3(0, 0.05, 0), Vector3(hw + 0.02, 0.19, 0.24), c)
				for s4 in ["l", "r"]:
					var wide := 1.15 if style == "wide" else 1.0
					bx(parts, "leg_" + s4, Vector3(0, -0.2, 0), Vector3(0.18 * wide, 0.44, 0.19 * wide), c, Vector2(1, 1), Vector2(0.9, 0.9))
					if style == "breeches":
						bx(parts, "shin_" + s4, Vector3(0, -0.02, 0), Vector3(0.15, 0.08, 0.16), t)
						bx(parts, "shin_" + s4, Vector3(0, -0.2, 0), Vector3(0.13, 0.32, 0.14), Color(0.78, 0.72, 0.6), Vector2(1, 1), Vector2(0.85, 0.85))
					else:
						bx(parts, "shin_" + s4, Vector3(0, -0.17, 0), Vector3(0.14 * wide, 0.36, 0.15 * wide), c.darkened(0.04), Vector2(1, 1), Vector2(0.9 * wide, 0.9 * wide))
					if style == "padded":
						for i in 3:
							bx(parts, "leg_" + s4, Vector3(0, -0.06 - i * 0.12, 0.1), Vector3(0.17, 0.014, 0.012), t, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
		"boots":
			for s5 in ["l", "r"]:
				var foot_c := c
				match style:
					"sandals":
						bx(parts, "shin_" + s5, Vector3(0, -0.478, 0.04), Vector3(0.14, 0.025, 0.25), c, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.1)
						bx(parts, "shin_" + s5, Vector3(0, -0.44, 0.06), Vector3(0.13, 0.02, 0.04), t)
						bx(parts, "shin_" + s5, Vector3(0, -0.36, 0), Vector3(0.13, 0.02, 0.14), t)
					"shoes":
						bx(parts, "shin_" + s5, Vector3(0, -0.44, 0.045), Vector3(0.14, 0.095, 0.25), foot_c, Vector2(1, 0.85))
						bx(parts, "shin_" + s5, Vector3(0, -0.385, 0.0), Vector3(0.135, 0.04, 0.15), t)
					"tall", "fur":
						bx(parts, "shin_" + s5, Vector3(0, -0.44, 0.05), Vector3(0.15, 0.1, 0.27), foot_c, Vector2(1, 0.85))
						bx(parts, "shin_" + s5, Vector3(0, -0.24, 0), Vector3(0.145, 0.34, 0.155), foot_c.darkened(0.05), Vector2(1.05, 1.05))
						bx(parts, "shin_" + s5, Vector3(0, -0.06, 0), Vector3(0.17, 0.07, 0.18), t, Vector2(1.1, 1.1))
						if style == "fur":
							bx(parts, "shin_" + s5, Vector3(0, -0.02, 0), Vector3(0.19, 0.09, 0.2), t.lightened(0.1), Vector2(1.15, 1.15))
					"sabatons":
						bx(parts, "shin_" + s5, Vector3(0, -0.44, 0.05), Vector3(0.15, 0.1, 0.28), c, Vector2(0.9, 0.8), Vector2.ONE, Vector3.ZERO, 0.3)
						for i in 3:
							bx(parts, "shin_" + s5, Vector3(0, -0.41, 0.1 + i * 0.045), Vector3(0.152, 0.02, 0.02), t)
						bx(parts, "shin_" + s5, Vector3(0, -0.33, 0), Vector3(0.145, 0.12, 0.155), c.darkened(0.05))
		"greaves":
			for s6 in ["l", "r"]:
				# knee cop
				bx(parts, "shin_" + s6, Vector3(0, 0.0, 0.05), Vector3(0.15, 0.11, 0.1), t, Vector2(0.8, 0.8), Vector2(1, 1), Vector3.ZERO, 0.3)
				match style:
					"chain":
						bx(parts, "leg_" + s6, Vector3(0, -0.22, 0), Vector3(0.195, 0.4, 0.2), c, Vector2(1, 1), Vector2(0.9, 0.9), Vector3.ZERO, 0.15)
						bx(parts, "shin_" + s6, Vector3(0, -0.18, 0), Vector3(0.155, 0.3, 0.165), c.darkened(0.05))
					"chitin":
						bx(parts, "shin_" + s6, Vector3(0, -0.18, 0.03), Vector3(0.16, 0.32, 0.14), c, Vector2(1.1, 1.2), Vector2(0.8, 0.9), Vector3.ZERO, 0.35)
						bx(parts, "leg_" + s6, Vector3(0, -0.24, 0.04), Vector3(0.19, 0.3, 0.16), c.darkened(0.05), Vector2(1.1, 1.1), Vector2(0.9, 0.9))
					_:
						bx(parts, "shin_" + s6, Vector3(0, -0.18, 0.02), Vector3(0.16, 0.32, 0.16), c, Vector2(1.08, 1.08), Vector2(0.88, 0.88), Vector3.ZERO, 0.3)
						if style == "plate" or style == "brass":
							bx(parts, "leg_" + s6, Vector3(0, -0.22, 0.03), Vector3(0.2, 0.36, 0.17), c.lightened(0.04), Vector2(1, 1), Vector2(0.88, 0.88), Vector3.ZERO, 0.3)
						if style == "brass":
							bx(parts, "shin_" + s6, Vector3(0, -0.1, 0.1), Vector3(0.162, 0.03, 0.02), t)
							bx(parts, "shin_" + s6, Vector3(0, -0.26, 0.095), Vector3(0.15, 0.03, 0.02), t)
		"cuirass":
			var d := 0.3 + belly
			var w := sw + 0.06
			match style:
				"chain":
					bx(parts, "chest", Vector3(0, 0.3, belly * 0.4), Vector3(w, 0.44, d), c, Vector2(1, 1), Vector2(0.86, 0.9), Vector3.ZERO, 0.18)
					bx(parts, "chest", Vector3(0, 0.0, 0), Vector3(hw + 0.08, 0.2, 0.27), c.darkened(0.06), Vector2(1, 1), Vector2(1.1, 1.1))
					for s7 in ["l", "r"]:
						bx(parts, "arm_" + s7, Vector3(0, -0.07, 0), Vector3(0.17 * L, 0.22, 0.17 * L), c)
				"leather":
					bx(parts, "chest", Vector3(0, 0.32, belly * 0.4), Vector3(w, 0.38, d), c, Vector2(1, 1), Vector2(0.8, 0.88), Vector3.ZERO, 0.2)
					bx(parts, "chest", Vector3(0, 0.33, 0.155 + belly * 0.5), Vector3(0.025, 0.34, 0.02), t)
					for s8 in [-1.0, 1.0]:
						bx(parts, "chest", Vector3(s8 * 0.07, 0.3, 0.155 + belly * 0.5), Vector3(0.025, 0.02, 0.02), t)
				_:
					# plate / scale / brass: chunky breastplate + backplate + tassets
					bx(parts, "chest", Vector3(0, 0.33, belly * 0.4 + 0.01), Vector3(w, 0.38, d), c, Vector2(1.05, 1.0), Vector2(0.8, 0.88), Vector3.ZERO, 0.32)
					bx(parts, "chest", Vector3(0, 0.36, 0.16 + belly * 0.5), Vector3(sw * 0.55, 0.22, 0.03), c.lightened(0.08), Vector2(0.9, 1), Vector2(0.7, 1), Vector3(-6, 0, 0), 0.25)
					bx(parts, "chest", Vector3(0, 0.5, 0), Vector3(sw * 0.7, 0.04, d - 0.02), t)
					bx(parts, "chest", Vector3(0, 0.12, belly * 0.4), Vector3(hw + 0.08, 0.06, d - 0.04), t)
					for s9 in [-1.0, 1.0]:
						bx(parts, "chest", Vector3(s9 * hw * 0.3, -0.02, 0.07), Vector3(hw * 0.45, 0.2, 0.18), c.darkened(0.06), Vector2(1, 1), Vector2(1.1, 1.1), Vector3(-6, 0, s9 * 6), 0.3)
					if style == "scale":
						for i in 4:
							bx(parts, "chest", Vector3(0, 0.2 + i * 0.075, 0.165 + belly * 0.4), Vector3(w * 0.85 - i * 0.02, 0.015, 0.012), t, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
					if style == "brass":
						bx(parts, "chest", Vector3(0, 0.26, 0.165 + belly * 0.5), Vector3(w * 0.8, 0.03, 0.02), t)
						bx(parts, "chest", Vector3(0, 0.38, 0.17 + belly * 0.5), Vector3(w * 0.7, 0.03, 0.02), t)
		"belt":
			var bw := hw * 0.98 + 0.05 + belly
			var y := 0.12
			match style:
				"rope":
					bx(parts, "chest", Vector3(0, y, belly * 0.5), Vector3(bw, 0.035, 0.24 + belly), c, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.1)
					bx(parts, "chest", Vector3(0.06, y - 0.08, 0.13 + belly), Vector3(0.025, 0.14, 0.025), c)
				"sash":
					bx(parts, "chest", Vector3(0, y, belly * 0.5), Vector3(bw, 0.09, 0.25 + belly), c, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.15)
					bx(parts, "chest", Vector3(-0.09, y - 0.12, 0.13 + belly), Vector3(0.07, 0.2, 0.02), c.darkened(0.08), Vector2(1, 1), Vector2(1.2, 1))
				_:
					bx(parts, "chest", Vector3(0, y, belly * 0.5), Vector3(bw, 0.06, 0.25 + belly), c, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.1)
					bx(parts, "chest", Vector3(0, y, 0.13 + belly), Vector3(0.07, 0.07, 0.02), t, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
					if style == "pouches" or style == "coin":
						for s10 in [-1.0, 1.0]:
							bx(parts, "chest", Vector3(s10 * bw * 0.4, y - 0.07, 0.1), Vector3(0.08, 0.1, 0.06), t.darkened(0.2), Vector2(0.9, 0.9))
					if style == "plate":
						bx(parts, "chest", Vector3(0, y + 0.02, 0.13 + belly), Vector3(bw * 0.6, 0.1, 0.02), t)
		"glove_l", "glove_r":
			var f := "fore_" + side
			match style:
				"wraps":
					bx(parts, f, Vector3(0, -0.29, 0.01), Vector3(0.122, 0.07, 0.1), c)
					bx(parts, f, Vector3(0, -0.2, 0), Vector3(0.112, 0.06, 0.112), c.darkened(0.06))
				"bracer":
					bx(parts, f, Vector3(0, -0.13, 0), Vector3(0.125 * L, 0.2, 0.125 * L), c, Vector2(1.1, 1.1), Vector2(0.95, 0.95), Vector3.ZERO, 0.3)
					bx(parts, f, Vector3(0, -0.13, 0.0), Vector3(0.13 * L, 0.03, 0.13 * L), t)
				"gauntlet", "chitin":
					bx(parts, f, Vector3(0, -0.32, 0.01), Vector3(0.14, 0.15, 0.115), c, Vector2(1, 1), Vector2(0.9, 0.8), Vector3.ZERO, 0.3)
					bx(parts, f, Vector3(0, -0.17, 0), Vector3(0.14 * L, 0.18, 0.14 * L), c.lightened(0.04), Vector2(1.18, 1.18), Vector2(0.95, 0.95), Vector3.ZERO, 0.3)
					bx(parts, f, Vector3(0, -0.26, 0.065), Vector3(0.12, 0.025, 0.02), t)
				_:
					bx(parts, f, Vector3(0, -0.31, 0.01), Vector3(0.128, 0.14, 0.108), c, Vector2(1, 1), Vector2(0.9, 0.8))
					bx(parts, f, Vector3(0, -0.21, 0), Vector3(0.125 * L, 0.08, 0.125 * L), t, Vector2(1.1, 1.1))
		"pauldron_l", "pauldron_r":
			var a := "arm_" + side
			var tilt := Vector3(0, 0, sx * 18.0)
			match style:
				"fur":
					bx(parts, a, Vector3(sx * 0.02, 0.02, 0), Vector3(0.24 * L, 0.12, 0.24 * L), c, Vector2(0.8, 0.8), Vector2(1.1, 1.1), tilt, 0.35)
				"chitin":
					bx(parts, a, Vector3(sx * 0.03, 0.03, 0), Vector3(0.22 * L, 0.1, 0.24 * L), c, Vector2(0.55, 0.7), Vector2(1.1, 1.1), tilt, 0.4)
					bx(parts, a, Vector3(sx * 0.05, -0.05, 0), Vector3(0.2 * L, 0.07, 0.22 * L), c.darkened(0.08), Vector2(0.9, 0.9), Vector2(1.1, 1.1), tilt, 0.3)
				"layered", "brass":
					for i in 3:
						bx(parts, a, Vector3(sx * (0.02 + i * 0.012), 0.04 - i * 0.055, 0), Vector3((0.22 - i * 0.01) * L, 0.06, (0.23 - i * 0.01) * L), c.darkened(0.05 * i), Vector2(0.85, 0.85), Vector2(1, 1), tilt, 0.3)
					if style == "brass":
						bx(parts, a, Vector3(sx * 0.01, 0.075, 0), Vector3(0.14 * L, 0.03, 0.16 * L), t, Vector2(0.8, 0.8))
				_:
					bx(parts, a, Vector3(sx * 0.02, 0.02, 0), Vector3(0.23 * L, 0.13, 0.24 * L), c, Vector2(0.6, 0.7), Vector2(1.05, 1.05), tilt, 0.35)
					bx(parts, a, Vector3(sx * 0.035, -0.045, 0), Vector3(0.235 * L, 0.025, 0.245 * L), t, Vector2.ONE, Vector2.ONE, tilt)
		"robe":
			match style:
				"robe", "coat":
					var length := 0.98 if style == "robe" else 0.7
					var cy := 0.14 - length * 0.5
					bx(parts, "chest", Vector3(0, 0.33, belly * 0.4), Vector3(sw + 0.08, 0.4, 0.31 + belly), c, Vector2(1, 1), Vector2(0.85, 0.9), Vector3.ZERO, 0.15)
					bx(parts, "chest", Vector3(0, cy, 0), Vector3(hw + 0.14 + belly, length, 0.3 + belly), c.darkened(0.04), Vector2(1, 1), Vector2(1.45, 1.35), Vector3.ZERO, 0.3)
					bx(parts, "chest", Vector3(0, cy, 0.16 + belly * 0.5), Vector3(0.05, length, 0.02), t, Vector2.ONE, Vector2(1.0, 1.4), Vector3(-9, 0, 0), 0.1)
					for s11 in ["l", "r"]:
						bx(parts, "arm_" + s11, Vector3(0, -0.12, 0), Vector3(0.18 * L, 0.3, 0.18 * L), c, Vector2(1, 1), Vector2(1.05, 1.05))
						bx(parts, "fore_" + s11, Vector3(0, -0.1, 0), Vector3(0.15 * L, 0.24, 0.15 * L), c.darkened(0.05), Vector2(1, 1), Vector2(1.25, 1.25))
						bx(parts, "fore_" + s11, Vector3(0, -0.22, 0), Vector3(0.19 * L, 0.03, 0.19 * L), t)
				"cloak":
					bx(parts, "chest", Vector3(0, -0.02, -0.17 - belly * 0.3), Vector3(sw + 0.16, 1.02, 0.05), c, Vector2(0.85, 1), Vector2(1.25, 1), Vector3(8, 0, 0), 0.3)
					bx(parts, "chest", Vector3(0, 0.5, -0.02), Vector3(sw + 0.1, 0.07, 0.3), c.lightened(0.04), Vector2(0.85, 0.9))
					bx(parts, "chest", Vector3(0, 0.49, 0.15), Vector3(0.06, 0.06, 0.03), t)
				"tabard":
					bx(parts, "chest", Vector3(0, 0.12, 0.16 + belly * 0.5), Vector3(sw * 0.6, 0.78, 0.025), c, Vector2(1, 1), Vector2(0.9, 1), Vector3.ZERO, 0.2)
					bx(parts, "chest", Vector3(0, 0.12, -0.16), Vector3(sw * 0.6, 0.78, 0.025), c, Vector2(1, 1), Vector2(0.9, 1), Vector3.ZERO, 0.2)
					bx(parts, "chest", Vector3(0, 0.3, 0.175 + belly * 0.5), Vector3(sw * 0.3, 0.12, 0.01), t)
				"mantle":
					bx(parts, "chest", Vector3(0, 0.45, 0), Vector3(sw + 0.2, 0.18, 0.36 + belly), c, Vector2(0.8, 0.8), Vector2(1.05, 1.05), Vector3.ZERO, 0.3)
					bx(parts, "chest", Vector3(0, 0.37, 0), Vector3(sw + 0.22, 0.03, 0.37 + belly), t)
		"amulet":
			var z := 0.17 + belly * 0.5
			bx(parts, "chest", Vector3(0, 0.44, z - 0.01), Vector3(0.16, 0.012, 0.012), t, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
			match style:
				"tooth":
					bx(parts, "chest", Vector3(0, 0.37, z), Vector3(0.035, 0.08, 0.02), c, Vector2(1, 1), Vector2(0.2, 0.5), Vector3.ZERO, 0.1)
				"key":
					bx(parts, "chest", Vector3(0, 0.36, z), Vector3(0.02, 0.09, 0.015), c)
					bx(parts, "chest", Vector3(0.015, 0.33, z), Vector3(0.03, 0.015, 0.015), c)
				"knot":
					bx(parts, "chest", Vector3(0, 0.375, z), Vector3(0.05, 0.05, 0.02), c, Vector2.ONE, Vector2.ONE, Vector3(0, 0, 45))
				_:
					bx(parts, "chest", Vector3(0, 0.375, z), Vector3(0.06, 0.06, 0.02), c, Vector2(0.7, 1), Vector2(0.7, 1), Vector3.ZERO, 0.1)
		"ring_l", "ring_r":
			bx(parts, "fore_" + side, Vector3(0, -0.34, 0.058), Vector3(0.05, 0.02, 0.02), c, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)
			if style != "band":
				bx(parts, "fore_" + side, Vector3(0, -0.34, 0.07), Vector3(0.025, 0.025, 0.012), t, Vector2.ONE, Vector2.ONE, Vector3.ZERO, 0.0)


static func _head_item(parts: Dictionary, style: String, c: Color, t: Color) -> void:
	var h := "head"
	match style:
		"hood":
			# Deep hood: open face, brow shadow under the rim. No eyes.
			bx(parts, h, Vector3(0, 0.25, -0.02), Vector3(0.36, 0.37, 0.35), c, Vector2(0.86, 0.88), Vector2(1, 1), Vector3.ZERO, 0.25)
			bx(parts, h, Vector3(0, 0.44, -0.06), Vector3(0.16, 0.1, 0.16), c, Vector2(0.3, 0.3), Vector2(1, 1), Vector3(-15, 0, 0))
			bx(parts, h, Vector3(0, 0.33, 0.15), Vector3(0.3, 0.07, 0.06), c.darkened(0.08), Vector2(1, 1), Vector2(1, 1), Vector3(-20, 0, 0))
			for s in [-1.0, 1.0]:
				bx(parts, h, Vector3(s * 0.155, 0.17, 0.08), Vector3(0.045, 0.3, 0.14), c.darkened(0.05))
			bx(parts, h, Vector3(0, -0.02, -0.01), Vector3(0.36, 0.1, 0.32), c.darkened(0.1), Vector2(1, 1), Vector2(1.2, 1.15))
		"cap":
			bx(parts, h, Vector3(0, 0.37, -0.01), Vector3(0.32, 0.1, 0.31), c, Vector2(0.85, 0.85), Vector2(1, 1), Vector3.ZERO, 0.2)
			bx(parts, h, Vector3(0, 0.33, 0), Vector3(0.325, 0.04, 0.315), t)
		"brim":
			bx(parts, h, Vector3(0, 0.38, 0), Vector3(0.3, 0.13, 0.29), c, Vector2(0.85, 0.85), Vector2(1, 1), Vector3.ZERO, 0.2)
			bx(parts, h, Vector3(0, 0.33, 0.01), Vector3(0.52, 0.025, 0.5), c.darkened(0.08), Vector2.ONE, Vector2.ONE, Vector3(-4, 0, 0), 0.1)
			bx(parts, h, Vector3(0, 0.36, 0), Vector3(0.305, 0.035, 0.295), t)
		"kettle":
			bx(parts, h, Vector3(0, 0.37, -0.01), Vector3(0.33, 0.14, 0.32), c, Vector2(0.7, 0.7), Vector2(1, 1), Vector3.ZERO, 0.3)
			bx(parts, h, Vector3(0, 0.3, 0), Vector3(0.46, 0.03, 0.44), c.darkened(0.06), Vector2.ONE, Vector2(0.95, 0.95), Vector3.ZERO, 0.2)
			bx(parts, h, Vector3(0, 0.22, -0.12), Vector3(0.32, 0.18, 0.07), Color(0.42, 0.40, 0.38))
		"crest":
			# Open-faced bronze helm with nose guard and crest. No eye slits.
			bx(parts, h, Vector3(0, 0.34, -0.01), Vector3(0.34, 0.2, 0.33), c, Vector2(0.75, 0.75), Vector2(1, 1), Vector3.ZERO, 0.3)
			bx(parts, h, Vector3(0, 0.2, 0.152), Vector3(0.035, 0.12, 0.03), c.darkened(0.05))
			for s2 in [-1.0, 1.0]:
				bx(parts, h, Vector3(s2 * 0.16, 0.16, 0.06), Vector3(0.035, 0.18, 0.13), c.darkened(0.06), Vector2(1, 1), Vector2(0.9, 0.8))
			bx(parts, h, Vector3(0, 0.18, -0.15), Vector3(0.3, 0.22, 0.04), c.darkened(0.08))
			bx(parts, h, Vector3(0, 0.49, -0.02), Vector3(0.05, 0.1, 0.34), t, Vector2(1, 0.8), Vector2(1, 1), Vector3.ZERO, 0.2)
			bx(parts, h, Vector3(0, 0.29, 0.0), Vector3(0.345, 0.03, 0.335), t)


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
