extends Object
# Hooded traveler: layered robe, trim, pauldrons. No visible face or eyes.
# Built from primitives + tiny procedural textures.

const Tex = preload("res://art/tex.gd")

static func build(hero: CharacterBody3D) -> void:
	var old := hero.get_node_or_null("Body")
	if old:
		old.free()
	var body := Node3D.new()
	body.name = "Body"
	hero.add_child(body)

	var fabric := StandardMaterial3D.new()
	fabric.albedo_color = Color(0.12, 0.22, 0.55)
	fabric.roughness = 0.88
	var leather := Tex.mat("leather", Color(0.7, 0.55, 0.4), 0.85)
	var trim := Tex.mat("trim", Color(0.85, 0.7, 0.4), 0.7, 0.15)
	var hood_m := StandardMaterial3D.new()
	hood_m.albedo_color = Color(0.08, 0.14, 0.38)
	hood_m.roughness = 0.9
	var boot_m := Tex.mat("leather", Color(0.4, 0.28, 0.18), 0.9)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.04, 0.03, 0.03)
	dark.roughness = 1.0

	# pelvis / legs under robe
	_add(body, _box(0.46, 0.28, 0.28), leather, Vector3(0, 0.55, 0))
	_add(body, _cyl(0.09, 0.55), boot_m, Vector3(-0.13, 0.28, 0.02))
	_add(body, _cyl(0.09, 0.55), boot_m, Vector3(0.13, 0.28, 0.02))
	# boots
	_add(body, _box(0.16, 0.12, 0.26), boot_m, Vector3(-0.13, 0.06, 0.05))
	_add(body, _box(0.16, 0.12, 0.26), boot_m, Vector3(0.13, 0.06, 0.05))

	# robe (flared)
	var robe := CylinderMesh.new()
	robe.top_radius = 0.22
	robe.bottom_radius = 0.52
	robe.height = 0.95
	robe.radial_segments = 10
	_add(body, robe, fabric, Vector3(0, 0.72, 0))
	# trim hem
	var hem := CylinderMesh.new()
	hem.top_radius = 0.49
	hem.bottom_radius = 0.52
	hem.height = 0.08
	hem.radial_segments = 10
	_add(body, hem, trim, Vector3(0, 0.28, 0))
	# chest layer / tunic over robe
	_add(body, _box(0.5, 0.48, 0.34), fabric, Vector3(0, 1.12, 0.02))
	# belt
	var belt := CylinderMesh.new()
	belt.top_radius = 0.32
	belt.bottom_radius = 0.32
	belt.height = 0.08
	belt.radial_segments = 10
	_add(body, belt, trim, Vector3(0, 0.92, 0))
	# buckle
	_add(body, _box(0.1, 0.1, 0.06), trim, Vector3(0, 0.92, 0.3))

	# metal pauldrons
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.62, 0.64, 0.70)
	metal.metallic = 0.82
	metal.roughness = 0.32
	var pL := SphereMesh.new()
	pL.radius = 0.18
	pL.height = 0.28
	pL.radial_segments = 8
	pL.rings = 4
	_add(body, pL, metal, Vector3(-0.32, 1.32, 0.0))
	var pR := SphereMesh.new()
	pR.radius = 0.18
	pR.height = 0.28
	pR.radial_segments = 8
	pR.rings = 4
	_add(body, pR, metal, Vector3(0.32, 1.32, 0.0))
	# pauldron rims
	_add(body, _torus(0.14, 0.025), trim, Vector3(-0.32, 1.32, 0), Vector3(0, 0, 90))
	_add(body, _torus(0.14, 0.025), trim, Vector3(0.32, 1.32, 0), Vector3(0, 0, 90))

	# arms
	_add(body, _cyl(0.07, 0.55), fabric, Vector3(-0.38, 0.95, 0), Vector3(0, 0, 12))
	_add(body, _cyl(0.07, 0.55), fabric, Vector3(0.38, 0.95, 0), Vector3(0, 0, -12))
	# gloves
	_add(body, _sph(0.09), leather, Vector3(-0.46, 0.66, 0.04))
	_add(body, _sph(0.09), leather, Vector3(0.46, 0.66, 0.04))

	# hood (covers head completely — dark void, no face)
	# Grouped under Head so a little pitch can follow the look stick.
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.58, 0)
	body.add_child(head)
	var hood := SphereMesh.new()
	hood.radius = 0.22
	hood.height = 0.4
	hood.radial_segments = 10
	hood.rings = 6
	_add(head, hood, hood_m, Vector3(0, 0, 0))
	# hood drape
	var drape := CylinderMesh.new()
	drape.top_radius = 0.2
	drape.bottom_radius = 0.28
	drape.height = 0.28
	drape.radial_segments = 8
	_add(head, drape, hood_m, Vector3(0, -0.18, -0.02))
	# cowl peak
	var peak := PrismMesh.new()
	peak.size = Vector3(0.28, 0.16, 0.22)
	_add(head, peak, hood_m, Vector3(0, 0.18, -0.02))
	# dark opening (no eyes, just shadow)
	var voidm := SphereMesh.new()
	voidm.radius = 0.1
	voidm.height = 0.14
	_add(head, voidm, dark, Vector3(0, -0.04, 0.14))

	# satchel
	_add(body, _box(0.16, 0.2, 0.08), leather, Vector3(0.28, 0.88, 0.1), Vector3(0, -20, 8))
	# strap
	_add(body, _box(0.04, 0.55, 0.02), leather, Vector3(0.16, 1.15, 0.06), Vector3(0, 0, 28))

	# simple walking staff (left)
	var staff_m := Tex.mat("wood", Color(0.7, 0.55, 0.35), 0.8)
	_add(body, _cyl(0.03, 1.45), staff_m, Vector3(-0.52, 0.75, 0.08))
	var crystal := Tex.unlit_em(Color(0.15, 0.65, 1.0), 1.35)
	_add(body, _sph(0.09), crystal, Vector3(-0.52, 1.52, 0.08))
	var shard := PrismMesh.new()
	shard.size = Vector3(0.1, 0.18, 0.1)
	_add(body, shard, crystal, Vector3(-0.52, 1.66, 0.08))


static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func _box(w: float, h: float, d: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(w, h, d)
	return b


static func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 8
	return c


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 8
	s.rings = 4
	return s


static func _torus(r: float, ir: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = ir
	t.outer_radius = r
	t.rings = 10
	t.ring_segments = 8
	return t
