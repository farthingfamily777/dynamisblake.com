extends Object
# Port Paradise: a grimy, kid-friendly harbor town with two clean buildings
# (governor's mansion, high-class tavern) as contrast.

const Tex = preload("res://art/tex.gd")
const Props = preload("res://art/props.gd")
const Harbor = preload("res://art/harbor.gd")
const Market = preload("res://art/market.gd")

static func build(main: Node3D, fx: Dictionary) -> void:
	_ground(main)
	_hills(main)
	_harbor(main, fx)
	Harbor.build(main, fx)
	_bridge_and_canal(main)
	_streets(main)
	_shacks(main, fx)
	_houses(main)
	_domes(main)
	_tavern(main)
	_mansion(main)
	_arch(main)
	Market.build(main, fx)
	_clutter(main, fx)
	_cave_and_strider(main)
	_animals(main, fx)
	_dust(main)


static func _ground(main: Node3D) -> void:
	var earth := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	# End the dirt at the shoreline so it does not cover the harbor water
	# (that hard dark horizon band in v1 was the 90x90 plane sitting on the sea).
	pm.size = Vector2(90, 58)
	earth.mesh = pm
	earth.position = Vector3(0, 0, 7)
	var mat := Tex.mat("dirt", Color(0.85, 0.75, 0.6))
	mat.uv1_scale = Vector3(14, 9, 14)
	earth.material_override = mat
	main.add_child(earth)
	# wet shore band
	var wet := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(90, 14)
	wet.mesh = wp
	var wm := Tex.mat("sand", Color(0.45, 0.38, 0.25), 0.55, 0.05)
	wm.uv1_scale = Vector3(8, 2, 8)
	wet.material_override = wm
	wet.position = Vector3(0, 0.015, -18)
	main.add_child(wet)
	# Cobble road in two segments so it does not lid over the canal.
	var cob := Tex.mat("cobble", Color(0.72, 0.66, 0.55))
	cob.uv1_scale = Vector3(3, 6, 3)
	var road := MeshInstance3D.new()
	var rm := PlaneMesh.new()
	rm.size = Vector2(6.4, 12.5)
	road.mesh = rm
	road.material_override = cob
	road.position = Vector3(0, 0.03, 0.4)
	main.add_child(road)
	var road2 := MeshInstance3D.new()
	var rm2 := PlaneMesh.new()
	rm2.size = Vector2(6.4, 7.0)
	road2.mesh = rm2
	road2.material_override = cob
	road2.position = Vector3(0, 0.03, -15.0)
	main.add_child(road2)
	# square around spawn
	var sq := MeshInstance3D.new()
	var sm := PlaneMesh.new()
	sm.size = Vector2(10, 10)
	sq.mesh = sm
	var cob2 := Tex.mat("cobble", Color(0.68, 0.62, 0.5))
	cob2.uv1_scale = Vector3(5, 5, 5)
	sq.material_override = cob2
	sq.position = Vector3(0, 0.028, 1)
	main.add_child(sq)
	# side alleys
	for xsgn in [-1, 1]:
		var al := MeshInstance3D.new()
		var am := PlaneMesh.new()
		am.size = Vector2(10, 3.2)
		al.mesh = am
		al.material_override = cob
		al.position = Vector3(8 * xsgn, 0.03, -6)
		main.add_child(al)


static func _hills(main: Node3D) -> void:
	var moss := Tex.mat("moss", Color(0.7, 0.65, 0.45))
	moss.uv1_triplanar = true
	moss.uv1_world_triplanar = true
	moss.uv1_scale = Vector3(0.12, 0.12, 0.12)
	var dirt := Tex.mat("dirt", Color(0.7, 0.6, 0.42))
	dirt.uv1_triplanar = true
	dirt.uv1_world_triplanar = true
	dirt.uv1_scale = Vector3(0.1, 0.1, 0.1)
	var spots := [
		Vector3(-38, -4, -8), Vector3(40, -5, -6), Vector3(-34, -3, 18),
		Vector3(36, -4, 22), Vector3(-22, -6, 32), Vector3(18, -8, 36),
		Vector3(-48, -2, -28), Vector3(50, -3, -34), Vector3(8, -10, 42),
		Vector3(-10, -7, -48), Vector3(28, -6, -52), Vector3(-40, -8, -52)
	]
	for i in spots.size():
		var p: Vector3 = spots[i]
		var s := 14.0 + float(i % 4) * 3.0
		Props.add_mesh(main, Props.sph(s, 8), moss if i % 2 == 0 else dirt, p, Vector3.ZERO, Vector3(1.4, 0.45, 1.1))
	# distant rocky outcrops
	for i in 6:
		var a := -0.4 + float(i) * 0.35
		Props.boulder(main, Vector3(cos(a) * 34.0, 0, -8 + sin(a) * 6.0), randf_range(1.4, 2.4), rad_to_deg(a))


static func _harbor(main: Node3D, fx: Dictionary) -> void:
	var water := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(110, 44)
	water.mesh = wp
	var wm := Tex.mat("water", Color(0.22, 0.50, 0.52), 0.28, 0.12)
	wm.uv1_scale = Vector3(10, 6, 10)
	water.material_override = wm
	water.position = Vector3(0, -0.12, -42)
	main.add_child(water)
	# docks
	var plank := Tex.mat("wood", Color(0.6, 0.45, 0.28))
	plank.uv1_scale = Vector3(2, 8, 2)
	var deck := Props.add_mesh(main, Props.box(16, 0.18, 8), plank, Vector3(0, 0.12, -20))
	# pilings
	for x in [-7.5, -2.5, 2.5, 7.5]:
		for z in [-17.0, -23.0]:
			Props.add_mesh(main, Props.cyl(0.16, 1.4, 6), plank, Vector3(x, -0.2, z))
	# three finger piers
	for x in [-6.0, 0.0, 6.0]:
		Props.add_mesh(main, Props.box(2.2, 0.16, 8.5), plank, Vector3(x, 0.14, -26))
		for z in [-23.0, -28.0]:
			Props.add_mesh(main, Props.cyl(0.14, 1.5, 6), plank, Vector3(x - 0.8, -0.15, z))
			Props.add_mesh(main, Props.cyl(0.14, 1.5, 6), plank, Vector3(x + 0.8, -0.15, z))
	# rusty crane
	Props.crane(main, Vector3(11, 0, -21), -15)
	# rope posts and nets
	Props.rope_post(main, Vector3(-8, 0, -17))
	Props.rope_post(main, Vector3(-4, 0, -17))
	Props.rope_line(main, Vector3(-8, 1.0, -17), Vector3(-4, 1.0, -17))
	Props.net_hang(main, Vector3(-10, 0, -18.5), 70)
	Props.net_hang(main, Vector3(8.5, 0, -18), -60)
	# lighthouse on the west jetty
	Props.lighthouse(main, Vector3(-22, 0, -28), fx)
	# jetty stones out to the light
	var rock := Tex.mat("rock", Color(0.6, 0.55, 0.48))
	for i in 6:
		Props.add_mesh(main, Props.box(3.2, 0.6 + float(i) * 0.08, 2.2), rock, Vector3(-10 - float(i) * 2.0, 0.1, -24 - float(i) * 0.6), Vector3(0, 8 * (i % 3), 0))
	# moored skiff (simple, no people)
	var hull := Tex.mat("wood", Color(0.45, 0.3, 0.18))
	Props.add_mesh(main, Props.box(1.2, 0.4, 3.4), hull, Vector3(5.5, 0.05, -29))
	Props.add_mesh(main, Props.cyl(0.08, 2.4, 6), hull, Vector3(5.5, 1.3, -28.5))
	# distant moored hulls in the haze (no figures)
	var far := Tex.mat("wood", Color(0.3, 0.22, 0.15))
	Props.add_mesh(main, Props.box(2.2, 0.7, 6.5), far, Vector3(-8, -0.05, -40))
	Props.add_mesh(main, Props.cyl(0.1, 4.5, 6), far, Vector3(-8, 2.2, -39))
	Props.add_mesh(main, Props.box(1.8, 0.55, 5.0), far, Vector3(14, -0.05, -44))
	Props.add_mesh(main, Props.cyl(0.08, 3.6, 6), far, Vector3(14, 1.8, -43.5))
	var _d := deck


static func _bridge_and_canal(main: Node3D) -> void:
	var water := Tex.mat("water", Color(0.18, 0.42, 0.42), 0.25, 0.15)
	Props.add_mesh(main, Props.box(40, 0.2, 5.4), water, Vector3(0, -0.25, -8.5))
	# muddy banks
	var mud := Tex.mat("dirt", Color(0.45, 0.35, 0.22))
	Props.add_mesh(main, Props.box(40, 0.28, 0.8), mud, Vector3(0, -0.08, -5.9))
	Props.add_mesh(main, Props.box(40, 0.28, 0.8), mud, Vector3(0, -0.08, -11.1))
	# Low stone slab bridge — open in the middle so the harbor stays visible.
	var stone := Tex.mat("rock", Color(0.7, 0.65, 0.55))
	stone.uv1_triplanar = true
	var cob := Tex.mat("cobble", Color(0.62, 0.56, 0.46))
	cob.uv1_scale = Vector3(8, 1, 9)
	# deck sits just above the canal, slight rise
	Props.add_mesh(main, Props.box(6.2, 0.22, 6.4), stone, Vector3(0, 0.24, -8.5))
	Props.add_mesh(main, Props.box(6.0, 0.05, 6.4), cob, Vector3(0, 0.38, -8.5))
	# low parapets
	Props.add_mesh(main, Props.box(0.22, 0.38, 6.4), stone, Vector3(-3.05, 0.52, -8.5))
	Props.add_mesh(main, Props.box(0.22, 0.38, 6.4), stone, Vector3(3.05, 0.52, -8.5))
	# piers at the banks (leave the center open)
	Props.add_mesh(main, Props.box(1.3, 1.1, 1.0), stone, Vector3(-2.2, -0.15, -6.4))
	Props.add_mesh(main, Props.box(1.3, 1.1, 1.0), stone, Vector3(2.2, -0.15, -6.4))
	Props.add_mesh(main, Props.box(1.3, 1.1, 1.0), stone, Vector3(-2.2, -0.15, -10.6))
	Props.add_mesh(main, Props.box(1.3, 1.1, 1.0), stone, Vector3(2.2, -0.15, -10.6))
	# short cobble approaches, almost flat
	Props.add_mesh(main, Props.box(6.0, 0.12, 1.8), cob, Vector3(0, 0.18, -5.2))
	Props.add_mesh(main, Props.box(6.0, 0.12, 1.8), cob, Vector3(0, 0.18, -11.8))


static func _streets(main: Node3D) -> void:
	# lamp posts along the road; only every other one is lit (broken lamps)
	var lamps: Array = []
	var zs := [-13.5, -11.0, -4.0, -1.5, 2.5, 5.5]
	for i in zs.size():
		var lit := (i % 2) == 0
		Props.lamp_post(main, Vector3(-3.4, 0, zs[i]), lit, lamps)
		Props.lamp_post(main, Vector3(3.4, 0, zs[i] - 0.4), (i % 2) == 1, lamps)
	# a few scrubby trees on the edges
	for p in [Vector3(-18, 0, 8), Vector3(22, 0, 10), Vector3(-14, 0, 14), Vector3(15, 0, -14), Vector3(-24, 0, 0), Vector3(26, 0, -12), Vector3(-8, 0, 16), Vector3(9, 0, 18)]:
		Props.scrubby_tree(main, p, randf_range(0.85, 1.35))
	for p2 in [Vector3(-6, 0, 8), Vector3(7, 0, 9), Vector3(-20, 0, -14), Vector3(19, 0, 4), Vector3(12, 0, 16)]:
		Props.boulder(main, p2, randf_range(0.7, 1.4), randf_range(0, 180))


static func _shack_at(main: Node3D, pos: Vector3, yaw: float, w: float, d: float, h: float, tint: Color) -> void:
	var wall := Tex.mat("peel", tint)
	var tin := Tex.mat("tin", Color(0.75, 0.65, 0.5), 0.55, 0.2)
	var wood := Tex.mat("wood", Color(0.5, 0.35, 0.2))
	Props.add_mesh(main, Props.box(w, h, d), wall, pos + Vector3(0, h * 0.5, 0), Vector3(0, yaw, 0))
	# patched tin roof, slightly crooked
	Props.add_mesh(main, Props.box(w + 0.35, 0.08, d + 0.35), tin, pos + Vector3(0.05, h + 0.15, 0), Vector3(4, yaw, 3))
	# a darker patch
	Props.add_mesh(main, Props.box(w * 0.4, 0.06, d * 0.45), Tex.mat("rust", Color(0.6, 0.4, 0.25), 0.5, 0.3), pos + Vector3(w * 0.15, h + 0.22, 0), Vector3(4, yaw, 3))
	# door
	Props.add_mesh(main, Props.box(0.5, 1.15, 0.08), wood, pos + Vector3(0, 0.58, d * 0.5), Vector3(0, yaw, 0))
	# crooked window
	var glow := Tex.unlit_em(Color(0.9, 0.6, 0.3), 0.7)
	Props.add_mesh(main, Props.box(0.4, 0.4, 0.06), glow, pos + Vector3(w * 0.28, 1.15, d * 0.5), Vector3(0, yaw, 8))


static func _shacks(main: Node3D, fx: Dictionary) -> void:
	# messy dockside cluster (left)
	_shack_at(main, Vector3(-11, 0, -16.5), 8, 4.2, 3.4, 2.3, Color(0.7, 0.5, 0.32))
	_shack_at(main, Vector3(-15.5, 0, -14.5), -18, 3.4, 3.0, 2.0, Color(0.55, 0.45, 0.35))
	_shack_at(main, Vector3(-12.5, 0, -12.2), 12, 3.0, 2.6, 1.8, Color(0.5, 0.38, 0.28))
	# right dock shacks
	_shack_at(main, Vector3(13, 0, -16), -12, 4.0, 3.2, 2.2, Color(0.62, 0.42, 0.3))
	_shack_at(main, Vector3(16.5, 0, -13.5), 22, 3.2, 2.8, 1.9, Color(0.48, 0.4, 0.32))
	# broken neon on the left dock shack
	var neon := Label3D.new()
	neon.name = "NeonBait"
	neon.text = "BAIT"
	neon.font_size = 96
	neon.pixel_size = 0.012
	neon.modulate = Color(1.0, 0.45, 0.15)
	neon.outline_modulate = Color(0.4, 0.1, 0.0)
	neon.outline_size = 8
	neon.shaded = false
	neon.position = Vector3(-11, 2.7, -14.7)
	neon.rotation_degrees = Vector3(0, 8, -4)
	main.add_child(neon)
	fx["neon"] = neon
	var rooms := Label3D.new()
	rooms.text = "ROOMS"
	rooms.font_size = 72
	rooms.pixel_size = 0.01
	rooms.modulate = Color(0.35, 0.7, 0.45)
	rooms.shaded = false
	rooms.position = Vector3(13, 2.55, -14.3)
	rooms.rotation_degrees = Vector3(0, -12, 3)
	main.add_child(rooms)
	fx["neon2"] = rooms


static func _house_at(main: Node3D, pos: Vector3, yaw: float, w: float, d: float, h: float, tint: Color) -> void:
	var wall := Tex.mat("plaster", tint)
	var wood := Tex.mat("wood", Color(0.45, 0.3, 0.18))
	var roof := Tex.mat("wood", Color(0.35, 0.2, 0.12))
	Props.add_mesh(main, Props.box(w, h, d), wall, pos + Vector3(0, h * 0.5, 0), Vector3(0, yaw, 0))
	# timber frame
	Props.add_mesh(main, Props.box(w + 0.05, 0.12, d + 0.05), wood, pos + Vector3(0, 0.15, 0), Vector3(0, yaw, 0))
	Props.add_mesh(main, Props.box(w + 0.05, 0.12, d + 0.05), wood, pos + Vector3(0, h - 0.1, 0), Vector3(0, yaw, 0))
	# prism roof
	var pr := PrismMesh.new()
	pr.size = Vector3(d + 0.35, 1.35, w + 0.45)
	Props.add_mesh(main, pr, roof, pos + Vector3(0, h + 0.65, 0), Vector3(0, yaw + 90.0, 0))
	# door + windows
	Props.add_mesh(main, Props.box(0.55, 1.3, 0.08), wood, pos + Vector3(0, 0.65, d * 0.5 + 0.02), Vector3(0, yaw, 0))
	var win := Tex.unlit_em(Color(0.85, 0.6, 0.3), 0.55)
	Props.add_mesh(main, Props.box(0.45, 0.5, 0.06), win, pos + Vector3(w * 0.28, 1.4, d * 0.5 + 0.02), Vector3(0, yaw, 0))
	Props.add_mesh(main, Props.box(0.45, 0.5, 0.06), win, pos + Vector3(-w * 0.28, 1.4, d * 0.5 + 0.02), Vector3(0, yaw, 0))


static func _houses(main: Node3D) -> void:
	# earthy plaster houses lining the street, facing inward
	_house_at(main, Vector3(-8.2, 0, -3.5), 90, 5.0, 4.2, 3.2, Color(0.72, 0.58, 0.4))
	_house_at(main, Vector3(-8.6, 0, 2.2), 90, 4.4, 3.8, 2.8, Color(0.93, 0.91, 0.84))
	_house_at(main, Vector3(8.4, 0, -3.2), -90, 5.2, 4.0, 3.4, Color(0.55, 0.45, 0.32))
	_house_at(main, Vector3(8.8, 0, 2.6), -90, 4.2, 3.6, 2.7, Color(0.94, 0.92, 0.86))
	_house_at(main, Vector3(-9.0, 0, 8.0), 70, 4.0, 3.4, 2.6, Color(0.5, 0.4, 0.3))
	_house_at(main, Vector3(9.5, 0, 8.5), -110, 3.8, 3.4, 2.5, Color(0.92, 0.90, 0.82))


static func _dome_hall(main: Node3D, pos: Vector3, r: float, h: float, tint: Color) -> void:
	# Vivec / Balmora-ish canton: tapering drum + dome
	var plaster := Tex.mat("plaster", tint)
	plaster.uv1_triplanar = true
	var stone := Tex.mat("rock", Color(0.55, 0.48, 0.38))
	# plinth
	Props.add_mesh(main, Props.box(r * 2.4, 0.6, r * 2.4), stone, pos + Vector3(0, 0.3, 0))
	# drum
	Props.add_mesh(main, Props.cyl(r, h, 12, r * 0.82), plaster, pos + Vector3(0, 0.6 + h * 0.5, 0))
	# mid ring
	Props.add_mesh(main, Props.cyl(r * 0.92, 0.28, 12, r * 0.92), Tex.mat("trim", Color(0.7, 0.55, 0.3), 0.7, 0.1), pos + Vector3(0, 0.6 + h * 0.55, 0))
	# dome
	var dome := SphereMesh.new()
	dome.radius = r * 0.9
	dome.height = r * 1.15
	dome.radial_segments = 12
	dome.rings = 6
	Props.add_mesh(main, dome, plaster, pos + Vector3(0, 0.6 + h + r * 0.15, 0))
	# finial
	Props.add_mesh(main, Props.cyl(0.12, 1.1, 6, 0.04), Tex.mat("trim", Color(0.75, 0.58, 0.3)), pos + Vector3(0, 0.6 + h + r * 0.75, 0))
	# recessed dark doorway (no interior, no eye motifs)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.06, 0.05)
	Props.add_mesh(main, Props.box(1.2, 2.0, 0.2), dark, pos + Vector3(0, 1.3, r * 0.9))
	# arched frame
	Props.add_mesh(main, Props.cyl(0.85, 0.2, 8), stone, pos + Vector3(0, 2.3, r * 0.92), Vector3(90, 0, 0))


static func _domes(main: Node3D) -> void:
	_dome_hall(main, Vector3(-16.5, 0, -1.0), 4.2, 4.6, Color(0.7, 0.55, 0.38))
	_dome_hall(main, Vector3(17.5, 0, -6.5), 3.6, 4.0, Color(0.62, 0.48, 0.34))
	# smaller side shrine-like dome
	_dome_hall(main, Vector3(-17.0, 0, 8.5), 2.6, 3.0, Color(0.58, 0.46, 0.32))


static func _tavern(main: Node3D) -> void:
	# Clean high-class tavern, left of the street, looking toward harbor.
	var pos := Vector3(-11.5, 0, -7.2)
	var stone := Tex.mat("clean_stone", Color(0.92, 0.86, 0.72))
	var wood := Tex.mat("wood_fine", Color(0.7, 0.5, 0.3))
	var trim := Tex.mat("trim", Color(0.85, 0.7, 0.4), 0.6, 0.2)
	Props.add_mesh(main, Props.box(7.2, 4.4, 5.6), stone, pos + Vector3(0, 2.2, 0), Vector3(0, 18, 0))
	# clean tiled roof
	var roof_m := Tex.mat("rock", Color(0.42, 0.22, 0.16))
	var pr := PrismMesh.new()
	pr.size = Vector3(6.2, 1.6, 8.0)
	Props.add_mesh(main, pr, roof_m, pos + Vector3(0, 5.2, 0), Vector3(0, 18 + 90.0, 0))
	# carved lintel / columns
	Props.add_mesh(main, Props.cyl(0.22, 3.2, 8), trim, pos + Vector3(-1.4, 1.6, 2.7))
	Props.add_mesh(main, Props.cyl(0.22, 3.2, 8), trim, pos + Vector3(1.4, 1.6, 2.9))
	# warm clean windows
	var win := Tex.unlit_em(Color(1.0, 0.8, 0.5), 1.6)
	Props.add_mesh(main, Props.box(1.1, 1.0, 0.08), win, pos + Vector3(-2.2, 2.2, 2.85))
	Props.add_mesh(main, Props.box(1.1, 1.0, 0.08), win, pos + Vector3(2.3, 2.2, 2.95))
	Props.add_mesh(main, Props.box(0.7, 1.6, 0.08), wood, pos + Vector3(0, 0.9, 2.95))
	# hanging sign
	var board := Props.add_mesh(main, Props.box(1.6, 0.9, 0.08), wood, pos + Vector3(0.2, 3.5, 3.3))
	var lb := Label3D.new()
	lb.text = "THE GILDED ANCHOR"
	lb.font_size = 64
	lb.pixel_size = 0.008
	lb.modulate = Color(0.85, 0.7, 0.35)
	lb.outline_size = 4
	lb.outline_modulate = Color(0.15, 0.1, 0.04)
	lb.position = pos + Vector3(0.2, 3.5, 3.38)
	main.add_child(lb)
	# porch lamp
	Props.lamp_post(main, pos + Vector3(2.6, 0, 3.4), true, [])
	var _b := board


static func _mansion(main: Node3D) -> void:
	# Clean governor's mansion on a rise to the right, in view toward the harbor.
	var pos := Vector3(18.5, 0.8, -11.5)
	var stone := Tex.mat("clean_stone", Color(0.95, 0.9, 0.78))
	var trim := Tex.mat("trim", Color(0.85, 0.72, 0.42), 0.55, 0.25)
	# terrace
	Props.add_mesh(main, Props.box(12, 0.8, 9), Tex.mat("clean_stone", Color(0.8, 0.74, 0.6)), Vector3(18.5, 0.4, -11.5))
	Props.add_mesh(main, Props.box(0.3, 1.0, 9), stone, Vector3(12.6, 0.9, -11.5))
	# stairs down toward the road
	for i in 5:
		Props.add_mesh(main, Props.box(2.4, 0.18, 0.7), stone, Vector3(13.8, 0.2 + float(4 - i) * 0.16, -8.2 + float(i) * 0.55))
	# main block
	Props.add_mesh(main, Props.box(9.5, 5.2, 6.5), stone, pos + Vector3(0, 2.6, 0))
	# side wings
	Props.add_mesh(main, Props.box(3.2, 3.6, 4.2), stone, pos + Vector3(-6.0, 1.8, 0.4))
	Props.add_mesh(main, Props.box(3.2, 3.6, 4.2), stone, pos + Vector3(6.0, 1.8, 0.4))
	# pediment
	var pr := PrismMesh.new()
	pr.size = Vector3(9.6, 1.8, 0.6)
	Props.add_mesh(main, pr, stone, pos + Vector3(0, 6.1, 3.1))
	# columns
	for x in [-2.8, -1.0, 1.0, 2.8]:
		Props.add_mesh(main, Props.cyl(0.22, 4.0, 8), trim, pos + Vector3(x, 2.0, 3.3))
	# dark door + warm windows (clean glass, even glow)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.08, 0.05)
	Props.add_mesh(main, Props.box(1.3, 2.2, 0.1), dark, pos + Vector3(0, 1.2, 3.35))
	var win := Tex.unlit_em(Color(1.0, 0.85, 0.55), 1.3)
	for x2 in [-3.2, -1.6, 1.6, 3.2]:
		Props.add_mesh(main, Props.box(0.8, 1.1, 0.08), win, pos + Vector3(x2, 3.4, 3.3))
	# roof
	Props.add_mesh(main, Props.box(10.0, 0.2, 6.9), Tex.mat("tin", Color(0.7, 0.68, 0.6), 0.45, 0.3), pos + Vector3(0, 5.35, 0))
	# flag pole (plain pennant, no symbols)
	Props.add_mesh(main, Props.cyl(0.05, 3.2, 6), trim, pos + Vector3(0, 7.4, 0))
	var penn := StandardMaterial3D.new()
	penn.albedo_color = Color(0.45, 0.15, 0.12)
	penn.cull_mode = BaseMaterial3D.CULL_DISABLED
	Props.add_mesh(main, Props.box(1.2, 0.6, 0.04), penn, pos + Vector3(0.6, 8.6, 0))
	var lb := Label3D.new()
	lb.text = "GOVERNOR"
	lb.font_size = 48
	lb.pixel_size = 0.01
	lb.modulate = Color(0.35, 0.28, 0.16)
	lb.position = pos + Vector3(0, 2.6, 3.5)
	main.add_child(lb)


static func _arch(main: Node3D) -> void:
	# Weathered stone arch at the harbor entrance. Text must be exact.
	var pos := Vector3(0, 0, -14.2)
	var stone := Tex.mat("rock", Color(0.62, 0.55, 0.42))
	stone.uv1_triplanar = true
	var peel := Tex.mat("peel", Color(0.7, 0.55, 0.35))
	# pillars
	Props.add_mesh(main, Props.box(1.1, 5.2, 1.1), stone, pos + Vector3(-4.0, 2.6, 0))
	Props.add_mesh(main, Props.box(1.1, 5.2, 1.1), stone, pos + Vector3(4.0, 2.6, 0))
	# bases / caps
	Props.add_mesh(main, Props.box(1.5, 0.45, 1.5), stone, pos + Vector3(-4.0, 0.22, 0))
	Props.add_mesh(main, Props.box(1.5, 0.45, 1.5), stone, pos + Vector3(4.0, 0.22, 0))
	Props.add_mesh(main, Props.box(1.5, 0.35, 1.5), stone, pos + Vector3(-4.0, 5.3, 0))
	Props.add_mesh(main, Props.box(1.5, 0.35, 1.5), stone, pos + Vector3(4.0, 5.3, 0))
	# lintel (open underneath — no solid fill)
	Props.add_mesh(main, Props.box(9.4, 1.05, 1.3), stone, pos + Vector3(0, 5.85, 0))
	# hanging weathered board on the face of the lintel
	Props.add_mesh(main, Props.box(7.2, 1.2, 0.16), peel, pos + Vector3(0, 5.85, 0.72))
	var lb := Label3D.new()
	lb.text = "PORT PARADISE"
	lb.font_size = 80
	lb.pixel_size = 0.008
	lb.modulate = Color(0.14, 0.08, 0.04)
	lb.outline_size = 8
	lb.outline_modulate = Color(0.4, 0.3, 0.14)
	lb.shaded = false
	lb.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lb.position = pos + Vector3(0, 5.9, 0.88)
	main.add_child(lb)
	# vines / grime
	var moss := Tex.mat("moss", Color(0.5, 0.5, 0.3))
	Props.add_mesh(main, Props.box(0.2, 1.8, 0.2), moss, pos + Vector3(-4.3, 1.2, 0.4))
	Props.add_mesh(main, Props.box(0.25, 2.2, 0.2), moss, pos + Vector3(4.35, 1.5, 0.35))


static func _clutter(main: Node3D, fx: Dictionary) -> void:
	var crates := [
		Vector3(-6.5, 0, -18), Vector3(-5.6, 0, -17.4), Vector3(4.5, 0, -18.2),
		Vector3(5.4, 0, -17.6), Vector3(-7.2, 0, -12.5), Vector3(6.8, 0, -12.0),
		Vector3(-4.8, 0, -4.2), Vector3(5.0, 0, 4.2), Vector3(-5.5, 0, 6.5)
	]
	for i in crates.size():
		Props.crate(main, crates[i], randf_range(-30, 40), randf_range(0.8, 1.15))
	for p in [Vector3(-6.0, 0, -16.5), Vector3(-3.5, 0, -19.5), Vector3(7.2, 0, -19), Vector3(4.2, 0, -12.8), Vector3(-5.8, 0, 3.2), Vector3(4.6, 0, -1.5)]:
		Props.barrel(main, p, randf_range(0, 80))
	for p2 in [Vector3(-2.6, 0, -16.8), Vector3(2.4, 0, -17.5), Vector3(-2.8, 0, -4.6), Vector3(2.5, 0, 3.6), Vector3(-5.0, 0, -12.8), Vector3(3.2, 0, -13.5), Vector3(1.6, 0, 6.4)]:
		Props.puddle(main, p2, randf_range(1.0, 2.0), randf_range(0.7, 1.4))
	for p3 in [Vector3(-7.0, 0, -15.2), Vector3(6.2, 0, -15.5), Vector3(-3.6, 0, 5.2), Vector3(4.8, 0, -4.0), Vector3(-6.4, 0, -2.0)]:
		Props.litter(main, p3)
	var _fx := fx


static func _cave_and_strider(main: Node3D) -> void:
	# Smugglers' cave in the rocks just outside town, right-hand shore.
	Props.cave_mouth(main, Vector3(26, 0, -18), -90)
	# Silt-strider silhouette in the hazy distance, across the harbor.
	Props.silt_strider(main, Vector3(-18, 0, -44), 35)
	# mound under the strider so it stands on land in the haze
	Props.add_mesh(main, Props.sph(7.0, 8), Tex.mat("dirt", Color(0.55, 0.45, 0.3)), Vector3(-18, -2.2, -44), Vector3.ZERO, Vector3(1.6, 0.5, 1.3))


static func _animals(main: Node3D, fx: Dictionary) -> void:
	var list: Array = []
	Props.stray_dog(main, Vector3(-5.5, 0, -15.5), list)
	Props.stray_dog(main, Vector3(4.8, 0, -4.5), list)
	Props.stray_cat(main, Vector3(-7.2, 0, -12.8), list)
	Props.stray_cat(main, Vector3(6.5, 0, 3.5), list)
	Props.stray_cat(main, Vector3(-3.2, 0, 6.2), list)
	fx["animals"] = list


static func _dust(main: Node3D) -> void:
	var p := CPUParticles3D.new()
	p.amount = 24
	p.lifetime = 6.0
	p.preprocess = 2.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(16, 1, 16)
	p.position = Vector3(0, 1.4, -6)
	p.direction = Vector3(0.3, 0.1, 0.1)
	p.spread = 40
	p.gravity = Vector3(0, 0.02, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.8
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.45, 0.32, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var s := QuadMesh.new()
	s.size = Vector2(0.08, 0.08)
	p.mesh = s
	p.material_override = m
	main.add_child(p)
	# chimney smoke from a shack
	var sm := CPUParticles3D.new()
	sm.amount = 12
	sm.lifetime = 3.5
	sm.position = Vector3(-11, 2.9, -16.5)
	sm.direction = Vector3(0.15, 1, 0)
	sm.spread = 12
	sm.gravity = Vector3(0, 0.15, 0)
	sm.initial_velocity_min = 0.3
	sm.initial_velocity_max = 0.7
	sm.scale_amount_min = 0.6
	sm.scale_amount_max = 1.2
	sm.mesh = s
	var smm := StandardMaterial3D.new()
	smm.albedo_color = Color(0.35, 0.32, 0.28, 0.35)
	smm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material_override = smm
	main.add_child(sm)
