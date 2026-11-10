extends Object
# Market street, crowd, bank, smithy, and neon towers. Color contrast for v3.

const Tex = preload("res://art/tex.gd")
const Props = preload("res://art/props.gd")

const AWNINGS := [
	Color(0.82, 0.14, 0.14),  # red
	Color(0.05, 0.52, 0.52),  # teal
	Color(0.92, 0.68, 0.10),  # saffron
	Color(0.22, 0.16, 0.62),  # indigo
	Color(0.12, 0.48, 0.22),  # green
	Color(0.78, 0.28, 0.45)   # rose
]

const CLOTHES := [
	Color(0.78, 0.15, 0.12), Color(0.08, 0.50, 0.48), Color(0.90, 0.70, 0.12),
	Color(0.20, 0.16, 0.58), Color(0.18, 0.42, 0.22), Color(0.85, 0.85, 0.80),
	Color(0.15, 0.22, 0.55), Color(0.55, 0.22, 0.12), Color(0.45, 0.12, 0.35),
	Color(0.12, 0.12, 0.14), Color(0.70, 0.45, 0.15), Color(0.25, 0.45, 0.55)
]


static func build(main: Node3D, fx: Dictionary) -> void:
	_stalls(main)
	_bank(main)
	_smithy(main, fx)
	_neon_towers(main, fx)
	_crowd(main, fx)
	# plants in the market
	for p in [Vector3(-6.5, 0, 3.5), Vector3(6.8, 0, 4.0), Vector3(-5.8, 0, -2.2),
			Vector3(5.6, 0, -1.8), Vector3(-6.2, 0, -9.5), Vector3(6.0, 0, -9.0)]:
		Props.palm(main, p, randf_range(0.7, 1.05))
	for b in [Vector3(-4.2, 0, 3.0), Vector3(4.4, 0, 2.2), Vector3(-3.6, 0, -10.5), Vector3(3.8, 0, 5.5)]:
		Props.bush(main, b, randf_range(0.8, 1.2))


static func _stalls(main: Node3D) -> void:
	# Line both sides of the street toward the harbor so they read from spawn.
	var spots := [
		Vector3(-4.6, 0, 3.2), Vector3(-4.6, 0, 0.6), Vector3(-4.6, 0, -2.0),
		Vector3(-4.6, 0, -4.4), Vector3(-4.7, 0, -9.6), Vector3(-4.7, 0, -12.0),
		Vector3(4.6, 0, 3.0), Vector3(4.6, 0, 0.4), Vector3(4.6, 0, -2.2),
		Vector3(4.6, 0, -4.6), Vector3(4.7, 0, -9.4), Vector3(4.7, 0, -12.2)
	]
	var yaws := [90.0, 90.0, 90.0, 90.0, 90.0, 90.0, -90.0, -90.0, -90.0, -90.0, -90.0, -90.0]
	for i in spots.size():
		_stall(main, spots[i], yaws[i], AWNINGS[i % AWNINGS.size()])


static func _stall(main: Node3D, pos: Vector3, yaw: float, awning: Color) -> void:
	var wood := Tex.mat("wood", Color(0.5, 0.35, 0.2))
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = awning
	cloth.roughness = 0.9
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	main.add_child(root)
	# counter + posts
	Props.add_mesh(root, Props.box(2.4, 0.85, 1.5), wood, Vector3(0, 0.42, 0))
	for x in [-1.05, 1.05]:
		Props.add_mesh(root, Props.cyl(0.06, 2.2, 5), wood, Vector3(x, 1.1, -0.6))
		Props.add_mesh(root, Props.cyl(0.06, 2.2, 5), wood, Vector3(x, 1.1, 0.6))
	# colorful awning
	Props.add_mesh(root, Props.box(2.6, 0.06, 1.8), cloth, Vector3(0, 2.15, 0), Vector3(8, 0, 0))
	# hanging goods
	for x in [-0.7, 0.0, 0.7]:
		var g := StandardMaterial3D.new()
		g.albedo_color = AWNINGS[absi(int(x * 10.0) + int(pos.z * 3.0)) % AWNINGS.size()]
		Props.add_mesh(root, Props.box(0.18, 0.35, 0.18), g, Vector3(x, 1.55, -0.2))
		Props.add_mesh(root, Props.cyl(0.08, 0.3, 6), g, Vector3(x * 0.7, 1.15, 0.45))
	# lantern
	var glow := Tex.unlit_em(Color(1.0, 0.75, 0.4), 1.3)
	Props.add_mesh(root, Props.sph(0.1, 6), glow, Vector3(0, 1.85, 0.2))
	# a few crates of stock
	Props.crate(root, Vector3(-0.7, 0, 0.9), 15, 0.55)
	Props.collider(root, Vector3(0, 0.7, 0), Vector3(2.4, 1.4, 1.6))


static func _bank(main: Node3D) -> void:
	var pos := Vector3(-12.2, 0, -5.0)
	var stone := Tex.mat("clean_stone", Color(0.90, 0.88, 0.80))
	var trim := Tex.mat("trim", Color(0.78, 0.65, 0.35), 0.6, 0.2)
	Props.add_mesh(main, Props.box(7.0, 4.6, 5.4), stone, pos + Vector3(0, 2.3, 0), Vector3(0, 90, 0))
	# columns facing the street (+X)
	for z in [-1.6, -0.55, 0.55, 1.6]:
		Props.add_mesh(main, Props.cyl(0.22, 3.4, 8), trim, pos + Vector3(2.85, 1.7, z))
	var pr := PrismMesh.new()
	pr.size = Vector3(5.6, 1.4, 0.5)
	Props.add_mesh(main, pr, stone, pos + Vector3(2.9, 5.0, 0), Vector3(0, 90, 0))
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.09, 0.06)
	Props.add_mesh(main, Props.box(0.1, 2.0, 1.2), dark, pos + Vector3(2.8, 1.1, 0))
	var lb := Label3D.new()
	lb.text = "BANK"
	lb.font_size = 72
	lb.pixel_size = 0.012
	lb.modulate = Color(0.25, 0.18, 0.08)
	lb.shaded = false
	lb.position = pos + Vector3(3.1, 3.6, 0)
	lb.rotation_degrees = Vector3(0, 90, 0)
	main.add_child(lb)
	Props.collider(main, pos + Vector3(0, 2.3, 0), Vector3(5.4, 4.6, 7.0))


static func _smithy(main: Node3D, fx: Dictionary) -> void:
	var pos := Vector3(12.2, 0, -5.2)
	var brick := Tex.mat("peel", Color(0.55, 0.32, 0.22))
	var stone := Tex.mat("rock", Color(0.4, 0.36, 0.32))
	Props.add_mesh(main, Props.box(6.4, 3.6, 5.0), brick, pos + Vector3(0, 1.8, 0), Vector3(0, -90, 0))
	Props.add_mesh(main, Props.box(7.0, 0.2, 5.6), Tex.mat("tin", Color(0.45, 0.35, 0.28), 0.5, 0.25), pos + Vector3(0, 3.7, 0))
	# open forge mouth facing the street (-X from pos, i.e. toward origin)
	var forge := Tex.unlit_em(Color(1.0, 0.45, 0.12), 2.8)
	var glow := Props.add_mesh(main, Props.box(0.2, 1.1, 1.3), forge, pos + Vector3(-2.65, 1.0, 0))
	fx["forge"] = glow
	var om := OmniLight3D.new()
	om.light_color = Color(1.0, 0.5, 0.15)
	om.light_energy = 1.6
	om.omni_range = 7.0
	om.position = pos + Vector3(-2.4, 1.1, 0)
	main.add_child(om)
	# anvil + chimney
	Props.add_mesh(main, Props.box(0.7, 0.5, 0.35), stone, pos + Vector3(-2.0, 0.45, 1.1))
	Props.add_mesh(main, Props.cyl(0.28, 2.2, 6), brick, pos + Vector3(1.4, 4.6, 0.8))
	var sm := CPUParticles3D.new()
	sm.amount = 8
	sm.lifetime = 2.8
	sm.position = pos + Vector3(1.4, 5.8, 0.8)
	sm.direction = Vector3(0.1, 1, 0)
	sm.spread = 12
	sm.gravity = Vector3(0, 0.15, 0)
	sm.initial_velocity_min = 0.3
	sm.initial_velocity_max = 0.7
	sm.scale_amount_min = 0.7
	sm.scale_amount_max = 1.3
	var q := QuadMesh.new()
	q.size = Vector2(0.25, 0.25)
	sm.mesh = q
	var smm := StandardMaterial3D.new()
	smm.albedo_color = Color(0.3, 0.3, 0.3, 0.4)
	smm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material_override = smm
	main.add_child(sm)
	var lb := Label3D.new()
	lb.text = "SMITHY"
	lb.font_size = 64
	lb.pixel_size = 0.012
	lb.modulate = Color(0.85, 0.7, 0.35)
	lb.shaded = false
	lb.position = pos + Vector3(-2.7, 2.9, 0)
	lb.rotation_degrees = Vector3(0, -90, 0)
	main.add_child(lb)
	Props.collider(main, pos + Vector3(0, 1.8, 0), Vector3(5.0, 3.6, 6.4))


static func _neon_towers(main: Node3D, fx: Dictionary) -> void:
	# Two or three tall towers with pink / cyan neon strips.
	var towers: Array = []
	towers.append(_tower(main, Vector3(-13.0, 0, -15.2), Color(1.0, 0.25, 0.7), "PORT"))
	towers.append(_tower(main, Vector3(13.2, 0, -15.0), Color(0.15, 0.95, 1.0), "STAR"))
	towers.append(_tower(main, Vector3(-7.2, 0, -13.8), Color(1.0, 0.35, 0.75), ""))
	fx["neon_towers"] = towers


static func _tower(main: Node3D, pos: Vector3, col: Color, label: String) -> Dictionary:
	var rust := Tex.mat("rust", Color(0.35, 0.3, 0.28), 0.55, 0.3)
	Props.add_mesh(main, Props.box(1.6, 11.0, 1.6), rust, pos + Vector3(0, 5.5, 0))
	var strip := Tex.unlit_em(col, 2.6)
	Props.add_mesh(main, Props.box(0.18, 9.0, 0.12), strip, pos + Vector3(0.85, 5.5, 0.0))
	Props.add_mesh(main, Props.box(0.18, 9.0, 0.12), strip, pos + Vector3(-0.85, 5.5, 0.0))
	Props.add_mesh(main, Props.box(0.12, 9.0, 0.18), strip, pos + Vector3(0.0, 5.5, 0.85))
	Props.add_mesh(main, Props.box(0.12, 9.0, 0.18), strip, pos + Vector3(0.0, 5.5, -0.85))
	# cap bar
	var cap := Props.add_mesh(main, Props.box(2.0, 0.4, 0.3), strip, pos + Vector3(0, 11.2, 0.9))
	if label != "":
		var lb := Label3D.new()
		lb.text = label
		lb.font_size = 80
		lb.pixel_size = 0.018
		lb.modulate = col
		lb.shaded = false
		lb.position = pos + Vector3(0, 9.6, 0.9)
		main.add_child(lb)
	Props.collider(main, pos + Vector3(0, 5.5, 0), Vector3(1.8, 11.0, 1.8))
	return {"mat": strip, "cap": cap, "color": col}


static func _crowd(main: Node3D, fx: Dictionary) -> void:
	var people: Array = []
	# 20 walkers around the market / street, none blocking the road center.
	var homes := [
		Vector3(-3.2, 0, 2.5), Vector3(-3.4, 0, 0.2), Vector3(-3.3, 0, -2.5),
		Vector3(-3.5, 0, -10.0), Vector3(-6.0, 0, -5.5), Vector3(-5.5, 0, 4.2),
		Vector3(3.2, 0, 2.2), Vector3(3.4, 0, -0.2), Vector3(3.3, 0, -2.8),
		Vector3(3.5, 0, -10.2), Vector3(6.0, 0, -5.2), Vector3(5.4, 0, 4.0),
		Vector3(-2.8, 0, 5.0), Vector3(2.6, 0, 5.2), Vector3(-6.5, 0, -1.0),
		Vector3(6.6, 0, -1.2), Vector3(-5.8, 0, -12.5), Vector3(5.8, 0, -12.6),
		Vector3(-2.4, 0, -7.0), Vector3(2.5, 0, -7.2)
	]
	for i in homes.size():
		_person(main, homes[i], CLOTHES[i % CLOTHES.size()], people)
	fx["people"] = people


static func _person(main: Node3D, pos: Vector3, cloth: Color, bag: Array) -> void:
	# Cheap figure: boxed body, featureless head (no face, no eyes).
	var root := Node3D.new()
	root.position = pos
	main.add_child(root)
	var tunic := StandardMaterial3D.new()
	tunic.albedo_color = cloth
	tunic.roughness = 0.9
	var skin := StandardMaterial3D.new()
	# muted skin tones, no facial features
	var tones := [Color(0.72, 0.56, 0.42), Color(0.45, 0.32, 0.22), Color(0.82, 0.68, 0.54)]
	skin.albedo_color = tones[absi(int(pos.x * 7.0 + pos.z * 3.0)) % 3]
	Props.add_mesh(root, Props.box(0.32, 0.7, 0.22), tunic, Vector3(0, 0.85, 0))
	Props.add_mesh(root, Props.sph(0.13, 6), skin, Vector3(0, 1.32, 0))
	# optional hat / hood (still no face)
	if randf() > 0.45:
		var hat := StandardMaterial3D.new()
		hat.albedo_color = cloth.darkened(0.25)
		Props.add_mesh(root, Props.cyl(0.16, 0.12, 6, 0.16), hat, Vector3(0, 1.44, 0))
	# legs
	var pant := StandardMaterial3D.new()
	pant.albedo_color = Color(0.18, 0.16, 0.14)
	Props.add_mesh(root, Props.cyl(0.05, 0.45, 5), pant, Vector3(-0.08, 0.28, 0))
	Props.add_mesh(root, Props.cyl(0.05, 0.45, 5), pant, Vector3(0.08, 0.28, 0))
	bag.append({
		"node": root,
		"home": pos,
		"r": randf_range(1.0, 2.2),
		"speed": randf_range(0.4, 0.9),
		"t": randf() * TAU,
		"kind": "person"
	})
