extends Object
# Harbor set dressing visible from spawn (camera looks -Z): ships, cranes, pads.
# Low-poly primitives, Compatibility-safe. Collision on new solids.

const Tex = preload("res://art/tex.gd")
const Props = preload("res://art/props.gd")

static func build(main: Node3D, fx: Dictionary) -> void:
	# Two sailing ships, a paddle steamboat (center, reads through the arch),
	# a cargo barge, a second (and third) tall crane, two landing pads.
	_sailer(main, Vector3(-9.5, 0, -34.0), 90.0, Color(0.90, 0.88, 0.78))
	_sailer(main, Vector3(11.0, 0, -38.0), 90.0, Color(0.85, 0.82, 0.72))
	_steamboat(main, Vector3(0.0, 0, -33.0), 90.0, fx)
	_barge(main, Vector3(15.0, 0, -30.0), -20.0)
	# Existing crane sits at (11, -21); add two taller ones.
	_crane(main, Vector3(-15.5, 0, -21.0), 25.0, 11.0)
	_crane(main, Vector3(17.5, 0, -23.5), -18.0, 12.5)
	_pad(main, Vector3(21.0, 0, -21.0), -15.0, true)
	_pad(main, Vector3(-20.0, 0, -22.0), 20.0, false)
	# Palms along the dock edge
	for p in [Vector3(-10, 0, -16.2), Vector3(-7, 0, -16.0), Vector3(9.5, 0, -16.2), Vector3(7, 0, -15.8), Vector3(-13, 0, -18)]:
		Props.palm(main, p, randf_range(0.85, 1.15))
		Props.bush(main, p + Vector3(0.8, 0, 0.4), randf_range(0.7, 1.1))


static func _sailer(main: Node3D, pos: Vector3, yaw: float, sail_col: Color) -> void:
	var wood := Tex.mat("wood", Color(0.38, 0.24, 0.14))
	var dark := Tex.mat("wood", Color(0.22, 0.14, 0.08))
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	main.add_child(root)
	# hull
	Props.add_mesh(root, Props.box(3.4, 1.5, 11.5), wood, Vector3(0, 0.35, 0))
	Props.add_mesh(root, Props.box(2.6, 0.9, 2.4), wood, Vector3(0, 0.5, -6.4), Vector3(18, 0, 0))  # bow
	Props.add_mesh(root, Props.box(3.0, 0.8, 2.0), dark, Vector3(0, 1.2, 3.6))  # cabin
	# masts
	Props.add_mesh(root, Props.cyl(0.12, 11.0, 6), dark, Vector3(0, 6.2, -1.2))
	Props.add_mesh(root, Props.cyl(0.10, 8.0, 6), dark, Vector3(0, 4.8, 2.6))
	# yards + sails (quads)
	var sail_m := StandardMaterial3D.new()
	sail_m.albedo_color = sail_col
	sail_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	sail_m.roughness = 0.95
	var s1 := QuadMesh.new()
	s1.size = Vector2(5.4, 6.5)
	Props.add_mesh(root, s1, sail_m, Vector3(0.0, 6.4, -1.2), Vector3(0, 90, 0))
	var s2 := QuadMesh.new()
	s2.size = Vector2(4.0, 4.6)
	Props.add_mesh(root, s2, sail_m, Vector3(0.0, 5.0, 2.6), Vector3(0, 90, 0))
	Props.add_mesh(root, Props.box(0.08, 0.08, 5.6), dark, Vector3(0, 8.8, -1.2))
	Props.collider(root, Vector3(0, 0.5, 0), Vector3(3.4, 1.6, 12.0))


static func _steamboat(main: Node3D, pos: Vector3, yaw: float, fx: Dictionary) -> void:
	var iron := Tex.mat("rust", Color(0.55, 0.42, 0.32), 0.55, 0.25)
	var wood := Tex.mat("wood_fine", Color(0.7, 0.62, 0.48))
	var white := Tex.mat("plaster", Color(0.92, 0.90, 0.84))
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	main.add_child(root)
	Props.add_mesh(root, Props.box(4.6, 1.6, 14.0), iron, Vector3(0, 0.3, 0))
	Props.add_mesh(root, Props.box(4.0, 1.5, 6.5), white, Vector3(0, 1.8, 1.0))  # superstructure
	Props.add_mesh(root, Props.box(2.4, 0.9, 2.6), white, Vector3(0, 2.9, 1.2))
	# two tall stacks
	var soot := Tex.mat("rust", Color(0.2, 0.18, 0.16), 0.7, 0.1)
	Props.add_mesh(root, Props.cyl(0.38, 5.2, 8), soot, Vector3(-0.7, 4.8, -2.2))
	Props.add_mesh(root, Props.cyl(0.38, 5.2, 8), soot, Vector3(0.7, 4.8, -2.2))
	Props.add_mesh(root, Props.cyl(0.42, 0.25, 8), iron, Vector3(-0.7, 7.4, -2.2))
	Props.add_mesh(root, Props.cyl(0.42, 0.25, 8), iron, Vector3(0.7, 7.4, -2.2))
	# paddle wheel
	var wheel := Node3D.new()
	wheel.name = "PaddleWheel"
	wheel.position = Vector3(2.5, 1.0, 0.5)
	root.add_child(wheel)
	Props.add_mesh(wheel, Props.cyl(1.6, 0.8, 10), wood, Vector3.ZERO, Vector3(0, 0, 90))
	for i in 8:
		var a := float(i) * 22.5
		Props.add_mesh(wheel, Props.box(0.08, 2.8, 0.5), wood, Vector3.ZERO, Vector3(0, 0, a))
	fx["paddle"] = wheel
	# stack smoke
	for x in [-0.7, 0.7]:
		var sm := CPUParticles3D.new()
		sm.amount = 10
		sm.lifetime = 3.0
		sm.position = Vector3(x, 7.6, -2.2)
		sm.direction = Vector3(0.1, 1, 0)
		sm.spread = 10
		sm.gravity = Vector3(0, 0.2, 0)
		sm.initial_velocity_min = 0.4
		sm.initial_velocity_max = 0.9
		sm.scale_amount_min = 0.8
		sm.scale_amount_max = 1.6
		var q := QuadMesh.new()
		q.size = Vector2(0.35, 0.35)
		sm.mesh = q
		var smm := StandardMaterial3D.new()
		smm.albedo_color = Color(0.35, 0.34, 0.32, 0.4)
		smm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		smm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.material_override = smm
		root.add_child(sm)
	Props.collider(root, Vector3(0, 0.6, 0), Vector3(4.6, 2.0, 14.0))


static func _barge(main: Node3D, pos: Vector3, yaw: float) -> void:
	var rust := Tex.mat("rust", Color(0.5, 0.38, 0.28), 0.6, 0.2)
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	main.add_child(root)
	Props.add_mesh(root, Props.box(4.2, 0.9, 9.0), rust, Vector3(0, 0.1, 0))
	# colored containers
	var cols := [
		Color(0.78, 0.16, 0.14), Color(0.08, 0.52, 0.50),
		Color(0.90, 0.68, 0.12), Color(0.22, 0.18, 0.62),
		Color(0.18, 0.45, 0.22), Color(0.75, 0.35, 0.10)
	]
	var i := 0
	for z in [-2.4, 0.0, 2.4]:
		for x in [-1.1, 1.1]:
			var m := StandardMaterial3D.new()
			m.albedo_color = cols[i % cols.size()]
			m.roughness = 0.7
			Props.add_mesh(root, Props.box(1.9, 1.5, 2.1), m, Vector3(x, 1.25, z))
			i += 1
	Props.collider(root, Vector3(0, 0.5, 0), Vector3(4.2, 1.6, 9.0))


static func _crane(main: Node3D, pos: Vector3, yaw: float, height: float) -> void:
	var rust := Tex.mat("rust", Color(0.62, 0.42, 0.28), 0.55, 0.35)
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	main.add_child(root)
	Props.add_mesh(root, Props.box(1.4, height, 1.4), rust, Vector3(0, height * 0.5, 0))
	Props.add_mesh(root, Props.box(0.3, 0.3, height * 0.95), rust, Vector3(0, height + 0.2, -height * 0.35), Vector3(18, 0, 0))
	Props.add_mesh(root, Props.box(1.8, 1.2, 1.8), rust, Vector3(0, height + 0.4, 0))
	Props.add_mesh(root, Props.cyl(0.04, height * 0.55, 5), rust, Vector3(0, height * 0.55, -height * 0.55))
	Props.collider(root, Vector3(0, height * 0.5, 0), Vector3(1.6, height, 1.6))


static func _pad(main: Node3D, pos: Vector3, yaw: float, with_ship: bool) -> void:
	var stone := Tex.mat("clean_stone", Color(0.7, 0.7, 0.68))
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	main.add_child(root)
	Props.add_mesh(root, Props.box(10.0, 0.18, 10.0), stone, Vector3(0, 0.1, 0))
	# edge lights
	var lite := Tex.unlit_em(Color(1.0, 0.85, 0.4), 1.8)
	for i in 8:
		var a := float(i) * TAU / 8.0
		Props.add_mesh(root, Props.box(0.28, 0.18, 0.28), lite, Vector3(cos(a) * 4.6, 0.28, sin(a) * 4.6))
	# markings
	var mark := StandardMaterial3D.new()
	mark.albedo_color = Color(0.85, 0.75, 0.2)
	Props.add_mesh(root, Props.box(0.25, 0.04, 7.0), mark, Vector3(0, 0.21, 0))
	Props.add_mesh(root, Props.box(7.0, 0.04, 0.25), mark, Vector3(0, 0.21, 0))
	Props.collider(root, Vector3(0, 0.1, 0), Vector3(10, 0.25, 10))
	if with_ship:
		_starship(root, Vector3(0, 0.2, 0))


static func _starship(root: Node, pos: Vector3) -> void:
	# Simple parked lander. Dark canopy panel — no cockpit face or eyes.
	var hull := StandardMaterial3D.new()
	hull.albedo_color = Color(0.55, 0.58, 0.62)
	hull.metallic = 0.55
	hull.roughness = 0.4
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.09, 0.12)
	var accent := Tex.unlit_em(Color(0.3, 0.75, 1.0), 1.2)
	Props.add_mesh(root, Props.box(2.8, 1.2, 7.2), hull, pos + Vector3(0, 1.4, 0))
	Props.add_mesh(root, Props.box(2.0, 0.8, 2.2), hull, pos + Vector3(0, 1.5, -4.2), Vector3(18, 0, 0))  # nose
	Props.add_mesh(root, Props.box(1.4, 0.5, 1.2), dark, pos + Vector3(0, 1.7, -3.4))  # dark canopy
	# fins
	Props.add_mesh(root, Props.box(0.12, 1.8, 2.0), hull, pos + Vector3(-1.5, 2.0, 2.4))
	Props.add_mesh(root, Props.box(0.12, 1.8, 2.0), hull, pos + Vector3(1.5, 2.0, 2.4))
	Props.add_mesh(root, Props.box(3.6, 0.1, 0.8), hull, pos + Vector3(0, 1.3, 2.2))  # wing
	# gear
	for x in [-1.0, 1.0]:
		for z in [-2.2, 2.4]:
			Props.add_mesh(root, Props.cyl(0.08, 1.1, 6), hull, pos + Vector3(x, 0.65, z))
	# running lights
	Props.add_mesh(root, Props.sph(0.08, 6), accent, pos + Vector3(0, 1.5, -5.0))
	Props.add_mesh(root, Props.sph(0.08, 6), Tex.unlit_em(Color(1.0, 0.25, 0.15), 1.2), pos + Vector3(0, 1.5, 3.7))
	Props.collider(root, pos + Vector3(0, 1.2, 0), Vector3(3.0, 2.2, 7.5))
