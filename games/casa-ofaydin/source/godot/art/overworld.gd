extends Node3D
## The open land outside Port Paradise, made fresh from the world seed:
## fields, woods, hills, ruins, roaming deer and rabbits by day, and silly
## (never scary-gory) vampires and werewolves at night that Lux scares off.
## Founded villages and towns are drawn here too. N64-style: flat-shaded
## colour gradients, few triangles, MultiMesh for trees and rocks.

const Props = preload("res://art/props.gd")
const Batcher = preload("res://art/batcher.gd")
const CHUNK := 42.0   # trees / rocks live in 42 m chunks; far chunks are culled by distance
const LowPoly = preload("res://art/lowpoly_character.gd")

const SIZE := 252.0
const CELL := 6.0
var main: Node3D
var noise := FastNoiseLite.new()
var noise2 := FastNoiseLite.new()
var wildlife: Array = []
var creatures: Array = []   # night folk: {node, body, kind, t, flee}
var village_root: Node3D
var _night_timer := 3.0
var _event_t := 25.0
var landmarks: Array = []   # {pos, kind}


static func in_city(x: float, z: float) -> bool:
	return (absf(x) < 46.0 and z < 37.0) or (absf(x) < 57.0 and z < -13.0)


func setup(m: Node3D, seed_value: int) -> void:
	main = m
	noise.seed = seed_value
	noise.frequency = 0.018
	noise2.seed = seed_value + 3
	noise2.frequency = 0.05
	_ground()
	_scatter(seed_value)
	village_root = Node3D.new()
	village_root.name = "Villages"
	add_child(village_root)
	for i in 8:
		_spawn_animal(i)


func biome(x: float, z: float) -> String:
	var v := noise.get_noise_2d(x, z)
	if v > 0.22:
		return "woods"
	if v < -0.28:
		return "hills"
	return "fields"


func _ground_color(x: float, z: float) -> Color:
	var v := noise.get_noise_2d(x, z)
	var w := noise2.get_noise_2d(x, z) * 0.5 + 0.5
	var grass := Color(0.42, 0.62, 0.28).lerp(Color(0.56, 0.68, 0.3), w)
	if v > 0.22:
		grass = Color(0.26, 0.45, 0.2).lerp(Color(0.32, 0.5, 0.22), w)
	elif v < -0.28:
		grass = Color(0.55, 0.58, 0.36).lerp(Color(0.62, 0.55, 0.4), w)
	if w > 0.78 and v <= 0.22 and v >= -0.28:
		grass = grass.lerp(Color(0.86, 0.78, 0.36), 0.45)   # wheat and flowers
	return grass


func _ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(SIZE / CELL)
	var half := SIZE * 0.5
	for i in n:
		for j in n:
			var x0 := -half + i * CELL
			var z0 := -half + j * CELL
			var cx := x0 + CELL * 0.5
			var cz := z0 + CELL * 0.5
			if in_city(cx, cz) and in_city(x0, z0) and in_city(x0 + CELL, z0 + CELL):
				continue
			var pts := [Vector3(x0, -0.03, z0), Vector3(x0 + CELL, -0.03, z0), Vector3(x0 + CELL, -0.03, z0 + CELL), Vector3(x0, -0.03, z0 + CELL)]
			var cols := []
			for p in pts:
				cols.append(_ground_color(p.x, p.z))
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(cols[k])
				st.set_normal(Vector3.UP)
				st.add_vertex(pts[k])
	var mi := MeshInstance3D.new()
	mi.name = "Land"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	mi.material_override = m
	add_child(mi)


func _mm(mesh: Mesh, mat: Material, xforms: Array, colors := []) -> void:
	# Split into chunks so only nearby ones draw (visibility range set by Quality).
	var buckets := {}
	for i in xforms.size():
		var o: Vector3 = (xforms[i] as Transform3D).origin
		var k := Vector2i(int(floor(o.x / CHUNK)), int(floor(o.z / CHUNK)))
		if not buckets.has(k):
			buckets[k] = [[], []]
		buckets[k][0].append(xforms[i])
		if not colors.is_empty():
			buckets[k][1].append(colors[i])
	for k in buckets:
		var c := Vector3((k.x + 0.5) * CHUNK, 0, (k.y + 0.5) * CHUNK)
		var local: Array = []
		for x in buckets[k][0]:
			var t: Transform3D = x
			t.origin -= c
			local.append(t)
		_mm_one(mesh, mat, local, buckets[k][1], c)


func _mm_one(mesh: Mesh, mat: Material, xforms: Array, colors: Array, at: Vector3) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.position = at
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.add_to_group("ow_chunk")
	add_child(mmi)


func _vc_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	return m


func _scatter(seed_value: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value + 5
	var trunks: Array = []; var crowns: Array = []; var crown_c: Array = []
	var pines: Array = []; var pine_c: Array = []
	var rocks: Array = []; var rock_c: Array = []
	var mounds: Array = []; var mound_c: Array = []
	var bushes: Array = []; var bush_c: Array = []
	var half := SIZE * 0.5 - 4.0
	for k in 1400:
		var x := r.randf_range(-half, half)
		var z := r.randf_range(-half, half)
		if in_city(x, z) or (absf(x) < 50 and z < 42 and z > -20):
			continue
		if Vector2(x, z).length() < 50.0:
			continue
		var b := biome(x, z)
		var s := r.randf_range(0.8, 1.4)
		var yaw := r.randf() * TAU
		match b:
			"woods":
				if r.randf() < 0.75:
					if r.randf() < 0.5:
						trunks.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), Vector3(x, 1.1 * s, z)))
						crowns.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s * 1.1, s * 0.9, s * 1.1)), Vector3(x, 3.0 * s, z)))
						crown_c.append(Color(0.24, 0.5, 0.2).lerp(Color(0.4, 0.58, 0.18), r.randf()))
					else:
						pines.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s * 1.2, s)), Vector3(x, 2.2 * s * 1.2, z)))
						pine_c.append(Color(0.16, 0.38, 0.22).lerp(Color(0.22, 0.44, 0.25), r.randf()))
			"hills":
				if r.randf() < 0.22:
					var hs := r.randf_range(4.0, 9.0)
					mounds.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(hs * 1.3, hs * 0.45, hs)), Vector3(x, -hs * 0.12, z)))
					mound_c.append(Color(0.5, 0.56, 0.32).lerp(Color(0.58, 0.52, 0.38), r.randf()))
				elif r.randf() < 0.4:
					rocks.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s * 0.7, s)), Vector3(x, 0.25 * s, z)))
					rock_c.append(Color(0.55, 0.53, 0.5).lerp(Color(0.66, 0.62, 0.55), r.randf()))
			_:
				if r.randf() < 0.12:
					bushes.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s * 0.7, s)), Vector3(x, 0.35 * s, z)))
					bush_c.append(Color(0.3, 0.52, 0.22).lerp(Color(0.5, 0.6, 0.25), r.randf()))
				elif r.randf() < 0.03:
					trunks.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), Vector3(x, 1.1 * s, z)))
					crowns.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s * 1.2, s, s * 1.2)), Vector3(x, 3.0 * s, z)))
					crown_c.append(Color(0.35, 0.56, 0.2))
	var bark := StandardMaterial3D.new(); bark.albedo_color = Color(0.42, 0.3, 0.2)
	_mm(Props.cyl(0.22, 2.2, 6, 0.3), bark, trunks)
	_mm(_round(1.6, 6, 4), _vc_mat(), crowns, crown_c)
	var cone := CylinderMesh.new(); cone.top_radius = 0.0; cone.bottom_radius = 1.3; cone.height = 4.4; cone.radial_segments = 7; cone.rings = 1
	_mm(cone, _vc_mat(), pines, pine_c)
	_mm(_round(1.0, 6, 3), _vc_mat(), rocks, rock_c)
	_mm(_round(1.0, 8, 4), _vc_mat(), mounds, mound_c)
	_mm(_round(0.8, 6, 3), _vc_mat(), bushes, bush_c)
	# Ruins: a few broken stone rings with pillars, to explore.
	var stone := StandardMaterial3D.new(); stone.albedo_color = Color(0.7, 0.66, 0.58)
	var placed := 0
	var tries := 0
	while placed < 5 and tries < 200:
		tries += 1
		var x := r.randf_range(-half + 10, half - 10)
		var z := r.randf_range(-half + 10, half - 10)
		if in_city(x, z) or Vector2(x, z).length() < 65.0:
			continue
		placed += 1
		var c := Vector3(x, 0, z)
		landmarks.append({"pos": c, "kind": "ruin"})
		var ruin := Node3D.new()
		add_child(ruin)
		for p in 7:
			var a := TAU * p / 7.0
			var h := r.randf_range(0.8, 3.4)
			Props.add_mesh(ruin, Props.cyl(0.42, h, 7, 0.48), stone, c + Vector3(cos(a) * 4.0, h * 0.5, sin(a) * 4.0))
			if p % 3 == 0:
				Props.add_mesh(ruin, Props.box(1.4, 0.4, 0.9), stone, c + Vector3(cos(a) * 5.2, 0.2, sin(a) * 5.2), Vector3(0, a, 0.2))
		Props.add_mesh(ruin, Props.cyl(1.6, 0.35, 10, 1.8), stone, c + Vector3(0, 0.17, 0))
		_merge_into_chunks(ruin)


func _merge_into_chunks(n: Node3D) -> void:
	Batcher.merge(n, [])
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh != null:
			mi.add_to_group("ow_chunk")
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _round(r: float, segs: int, rings: int) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r; s.height = r * 2.0; s.radial_segments = segs; s.rings = rings
	return s


# ---------------------------------------------------------------- wildlife

func _spawn_animal(i: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = noise.seed + 100 + i
	var deer := i % 2 == 0
	var root := Node3D.new()
	var a := r.randf() * PI + 0.0
	root.position = Vector3(cos(a) * r.randf_range(60, 110), 0, absf(sin(a)) * r.randf_range(50, 110))
	add_child(root)
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.62, 0.44, 0.26) if deer else Color(0.78, 0.72, 0.64)
	var sc := 1.0 if deer else 0.35
	Props.add_mesh(root, _round(0.5, 6, 4), fur, Vector3(0, 1.0 * sc, 0), Vector3.ZERO, Vector3(0.7, 0.7, 1.3) * sc)
	Props.add_mesh(root, _round(0.25, 6, 4), fur, Vector3(0, 1.45 * sc, 0.55 * sc), Vector3.ZERO, Vector3(0.8, 0.9, 1.2) * sc)
	if deer:
		for lx in [-0.18, 0.18]:
			for lz in [-0.4, 0.4]:
				Props.add_mesh(root, Props.cyl(0.05, 0.75, 5), fur, Vector3(lx, 0.38, lz))
	else:
		for ex in [-0.07, 0.07]:
			Props.add_mesh(root, Props.cyl(0.03, 0.35, 5), fur, Vector3(ex, 0.75, 0.2), Vector3(0.2, 0, 0))
	wildlife.append({"node": root, "deer": deer, "t": r.randf() * TAU, "dir": r.randf() * TAU, "hop": 0.0})


func _spawn_creature() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	var vamp := r.randf() < 0.5
	var hp: Vector3 = main.hero.global_position
	var a := r.randf() * TAU
	var pos := hp + Vector3(cos(a), 0, sin(a)) * 18.0
	if in_city(pos.x, pos.z):
		return
	pos.y = 0
	var root := Node3D.new()
	root.position = pos
	root.add_to_group("tag_target")
	add_child(root)
	var p := {}
	if vamp:
		p = {"skin": "#d8d0d8", "hair": "long", "hair_color": Color(0.1, 0.08, 0.12), "build": "slim",
			"gear": {"shirt": "silk_doublet", "robe": "traveler_cloak", "pants": "padded_hose", "boots": "low_shoes", "pauldron_l": "", "belt": "dyed_sash"},
			"tints": {"robe": "#2a1a3a", "shirt": "#5a2040", "belt": "#c9a24a"}}
	else:
		p = {"skin": "#8a6440", "hair": "shag", "hair_color": Color(0.36, 0.26, 0.16), "beard": true, "build": "broad",
			"gear": {"shirt": "patchwork_vest", "pants": "knee_breeches", "pauldron_l": "fur_mantle_pauldron", "pauldron_r": "fur_mantle_pauldron", "boots": "fur_lined_boots"},
			"tints": {"shirt": "#5a4630"}}
	var g: Dictionary = p["gear"]
	for k in g.keys():
		if str(g[k]) == "": g.erase(k)
	var body := LowPoly.build(root, p)
	var lb := Label3D.new()
	lb.text = "Silly Vampire" if vamp else "Fuzzy Werewolf"
	lb.font_size = 40; lb.pixel_size = 0.006; lb.outline_size = 6
	lb.modulate = Color(0.85, 0.75, 1.0) if vamp else Color(1.0, 0.85, 0.6)
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.position = Vector3(0, 2.25, 0)
	root.add_child(lb)
	creatures.append({"node": root, "body": body, "kind": "vampire" if vamp else "werewolf", "t": 0.0, "flee": 0.0, "met": false, "phase": 0.0})


## Lux: every night creature within reach runs off giggling. Returns how many.
func scare(at: Vector3, reach: float) -> int:
	var n := 0
	for c in creatures:
		if c["flee"] <= 0.0 and c["node"].global_position.distance_to(at) < reach:
			c["flee"] = 3.0
			n += 1
	return n


func remove_creature(c: Dictionary) -> void:
	creatures.erase(c)
	if is_instance_valid(c["node"]):
		c["node"].queue_free()


func clear_night() -> void:
	for c in creatures.duplicate():
		remove_creature(c)


func _process(delta: float) -> void:
	if main == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var hp: Vector3 = main.hero.global_position
	for w in wildlife:
		var nd: Node3D = w["node"]
		var away: Vector3 = nd.position - hp
		away.y = 0
		var spd := 0.8 if w["deer"] else 0.6
		if away.length() < 9.0:
			w["dir"] = atan2(away.x, away.z)
			spd = 6.0 if w["deer"] else 5.0
		else:
			w["t"] += delta
			if w["t"] > 4.0:
				w["t"] = 0.0
				w["dir"] += randf_range(-1.2, 1.2)
		var step := Vector3(sin(w["dir"]), 0, cos(w["dir"])) * spd * delta
		var np: Vector3 = nd.position + step
		if in_city(np.x, np.z) or absf(np.x) > 120 or absf(np.z) > 120:
			w["dir"] += PI
		else:
			nd.position = np
		nd.rotation.y = lerp_angle(nd.rotation.y, w["dir"], clampf(delta * 4.0, 0, 1))
		w["hop"] += delta * spd * 2.0
		nd.position.y = absf(sin(w["hop"])) * (0.12 if w["deer"] else 0.25)
	# night folk come out after dark, outside the city
	var night: bool = main.is_night()
	var out := not in_city(hp.x, hp.z)
	if night and out and not main.panel_open():
		_night_timer -= delta
		var cap := 2 if main.realm.has_perk("guard") else 3
		if _night_timer <= 0.0 and creatures.size() < cap:
			_night_timer = 14.0
			_spawn_creature()
	elif not night and not creatures.is_empty():
		for c in creatures:
			c["flee"] = maxf(c["flee"], 2.0)
	for c in creatures.duplicate():
		var nd: Node3D = c["node"]
		var to: Vector3 = hp - nd.global_position
		to.y = 0
		var d := to.length()
		var dir := to.normalized() if d > 0.01 else Vector3.FORWARD
		var spd := 1.6
		if c["flee"] > 0.0:
			c["flee"] -= delta
			dir = -dir
			spd = 7.0
			nd.scale = Vector3.ONE * maxf(0.05, c["flee"] / 3.0)
			if c["flee"] <= 0.0:
				main.creature_scared(c["kind"])
				remove_creature(c)
				continue
		elif d < 2.2:
			spd = 0.0
			if not c["met"]:
				c["met"] = true
				main.creature_meet(c)
		elif d > 40.0:
			remove_creature(c)
			continue
		nd.position += dir * spd * delta
		nd.rotation.y = atan2(dir.x, dir.z)
		c["phase"] += spd * delta * 2.2
		LowPoly.animate(c["body"], c["phase"], clampf(spd / 2.0, 0, 1), t)
	# random wilderness events on the dice
	if out and not main.panel_open() and main.hero.position.y < 2.0:
		_event_t -= delta
		if _event_t <= 0.0:
			_event_t = randf_range(35.0, 55.0)
			main.wild_event(biome(hp.x, hp.z))


# ---------------------------------------------------------------- villages

func draw_villages(villages: Array) -> void:
	for ch in village_root.get_children():
		ch.queue_free()
	for v in villages:
		_draw_village(v)
		clear_around(Vector3(float(v["x"]), 0, float(v["z"])), 17.0)


## Settlers clear the trees and rocks where a village stands.
func clear_around(at: Vector3, r: float) -> void:
	for c in get_children():
		if not (c is MultiMeshInstance3D):
			continue
		var mmi := c as MultiMeshInstance3D
		if Vector2(mmi.position.x - at.x, mmi.position.z - at.z).length() > CHUNK + r:
			continue
		var mm := mmi.multimesh
		for i in mm.instance_count:
			var t := mm.get_instance_transform(i)
			var w := mmi.position + t.origin
			if Vector2(w.x - at.x, w.z - at.z).length() < r:
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.0001), t.origin))


func _draw_village(v: Dictionary) -> void:
	var root := Node3D.new()
	root.position = Vector3(float(v["x"]), 0, float(v["z"]))
	village_root.add_child(root)
	var wall := StandardMaterial3D.new(); wall.albedo_color = Color(0.86, 0.78, 0.62)
	var roof := StandardMaterial3D.new(); roof.albedo_color = Color(0.62, 0.28, 0.2)
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.5, 0.36, 0.22)
	var gold := StandardMaterial3D.new(); gold.albedo_color = Color(1.0, 0.85, 0.4); gold.emission_enabled = true; gold.emission = Color(1.0, 0.8, 0.35); gold.emission_energy_multiplier = 0.6
	var town: bool = v["tier"] == "Town"
	# village square and a well
	Props.add_mesh(root, Props.cyl(5.5, 0.06, 12), wood if false else _plain(Color(0.7, 0.62, 0.46)), Vector3(0, 0.0, 0))
	Props.add_mesh(root, Props.cyl(0.7, 0.8, 8), _plain(Color(0.6, 0.6, 0.58)), Vector3(-3.5, 0.4, 3.5))
	Props.add_mesh(root, Props.cyl(0.8, 0.12, 8), _plain(Color(0.25, 0.45, 0.55)), Vector3(-3.5, 0.82, 3.5))
	if v["hall"]:
		_house(root, Vector3(0, 0, -8), 6.0, 4.5, 3.4, wall, roof)
		Props.add_mesh(root, Props.cyl(0.08, 3.0, 5), wood, Vector3(2.6, 5.4, -8))
		Props.add_mesh(root, Props.box(1.2, 0.7, 0.05), _plain(Color(0.8, 0.2, 0.2)), Vector3(3.2, 6.5, -8))
	for k in int(v["homes"]):
		var a := -1.1 + k * 0.55
		var p := Vector3(sin(a) * 11.0, 0, cos(a) * 11.0 - 2.0)
		_house(root, p, 3.2, 3.0, 2.2, wall, roof, a)
	if v["market"]:
		var stall := Vector3(7.5, 0, -3)
		for sx in [-1.2, 1.2]:
			for sz in [-0.8, 0.8]:
				Props.add_mesh(root, Props.cyl(0.07, 2.0, 5), wood, stall + Vector3(sx, 1.0, sz))
		Props.add_mesh(root, Props.box(2.8, 0.1, 2.0), _plain(Color(0.9, 0.6, 0.2)), stall + Vector3(0, 2.05, 0), Vector3(0, 0, 0.12))
		Props.add_mesh(root, Props.box(2.4, 0.8, 0.9), wood, stall + Vector3(0, 0.4, 0))
		Props.crate(root, stall + Vector3(1.8, 0, 1.2))
	if v["shrine"]:
		var sp := Vector3(-7.5, 0, -3)
		Props.add_mesh(root, Props.cyl(1.4, 0.4, 10), _plain(Color(0.8, 0.78, 0.72)), sp + Vector3(0, 0.2, 0))
		for k in 4:
			var a := TAU * k / 4.0 + 0.4
			Props.add_mesh(root, Props.cyl(0.14, 2.2, 6), _plain(Color(0.88, 0.86, 0.8)), sp + Vector3(cos(a) * 1.1, 1.3, sin(a) * 1.1))
		var dome := SphereMesh.new(); dome.radius = 1.4; dome.height = 1.4; dome.is_hemisphere = true; dome.radial_segments = 10; dome.rings = 3
		Props.add_mesh(root, dome, _plain(Color(0.86, 0.72, 0.4)), sp + Vector3(0, 2.4, 0))
		Props.add_mesh(root, _round(0.3, 8, 4), gold, sp + Vector3(0, 1.2, 0))
	if town:
		var post := _plain(Color(0.52, 0.38, 0.24))
		for k in 22:
			var a := TAU * k / 22.0
			if absf(a - PI * 0.5) < 0.25:
				continue
			Props.add_mesh(root, Props.cyl(0.25, 2.6, 6, 0.3), post, Vector3(cos(a) * 15.5, 1.3, sin(a) * 15.5))
	var lb := Label3D.new()
	lb.text = Realm_clean("%s  (%s)" % [v["name"], v["tier"]])
	lb.font_size = 64; lb.pixel_size = 0.01; lb.outline_size = 10
	lb.modulate = Color(1.0, 0.92, 0.6); lb.outline_modulate = Color(0.15, 0.1, 0.05)
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.position = Vector3(0, 7.5, 0)
	root.add_child(lb)
	Batcher.merge(root, [])


static func Realm_clean(s: String) -> String:
	if TavernSafe.contains_forbidden(s):
		return s.replace("6".repeat(3), "6 6 6")
	return s


static func _plain(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


func _house(root: Node3D, p: Vector3, w: float, d: float, h: float, wall: Material, roof: Material, yaw := 0.0) -> void:
	var hn := Node3D.new()
	hn.position = p
	hn.rotation.y = yaw
	root.add_child(hn)
	Props.add_mesh(hn, Props.box(w, h, d), wall, Vector3(0, h * 0.5, 0))
	var pr := PrismMesh.new(); pr.size = Vector3(w + 0.5, h * 0.6, d + 0.5)
	Props.add_mesh(hn, pr, roof, Vector3(0, h + h * 0.3, 0))
	Props.add_mesh(hn, Props.box(0.8, 1.5, 0.06), _plain(Color(0.4, 0.28, 0.18)), Vector3(0, 0.75, d * 0.5 + 0.03))
