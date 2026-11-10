extends Object
# Primitive props shared by the town builder. Compatibility-safe, no heavy shaders.

const Tex = preload("res://art/tex.gd")

static func add_mesh(parent: Node, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scale
	parent.add_child(mi)
	return mi


static func box(w: float, h: float, d: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(w, h, d)
	return b


static func cyl(r: float, h: float, segs := 8, r2 := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r if r2 < 0.0 else r2
	c.bottom_radius = r
	c.height = h
	c.radial_segments = segs
	return c


static func sph(r: float, segs := 8) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = max(3, segs / 2)
	return s


static func crate(parent: Node, pos: Vector3, yaw := 0.0, scale := 1.0) -> void:
	var m := Tex.mat("wood", Color(0.75, 0.62, 0.42))
	add_mesh(parent, box(0.7 * scale, 0.55 * scale, 0.7 * scale), m, pos + Vector3(0, 0.28 * scale, 0), Vector3(0, yaw, 0))
	# bands
	var iron := Tex.mat("rust", Color(0.6, 0.45, 0.3), 0.6, 0.25)
	add_mesh(parent, box(0.74 * scale, 0.05 * scale, 0.74 * scale), iron, pos + Vector3(0, 0.1 * scale, 0), Vector3(0, yaw, 0))
	add_mesh(parent, box(0.74 * scale, 0.05 * scale, 0.74 * scale), iron, pos + Vector3(0, 0.48 * scale, 0), Vector3(0, yaw, 0))


static func barrel(parent: Node, pos: Vector3, yaw := 0.0) -> void:
	var m := Tex.mat("wood", Color(0.6, 0.42, 0.25))
	add_mesh(parent, cyl(0.32, 0.7, 10, 0.28), m, pos + Vector3(0, 0.35, 0), Vector3(0, yaw, 0))
	var iron := Tex.mat("rust", Color(0.55, 0.4, 0.28), 0.55, 0.3)
	add_mesh(parent, cyl(0.33, 0.06, 10), iron, pos + Vector3(0, 0.12, 0))
	add_mesh(parent, cyl(0.33, 0.06, 10), iron, pos + Vector3(0, 0.58, 0))


static func puddle(parent: Node, pos: Vector3, sx := 1.4, sz := 1.0) -> void:
	var m := Tex.mat("water", Color(0.25, 0.26, 0.2), 0.18, 0.35)
	var p := cyl(0.6, 0.03, 10)
	add_mesh(parent, p, m, pos + Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(sx, 1, sz))


static func litter(parent: Node, pos: Vector3) -> void:
	var wood := Tex.mat("wood", Color(0.55, 0.4, 0.25))
	var rust := Tex.mat("rust", Color(0.7, 0.5, 0.3))
	add_mesh(parent, box(0.35, 0.04, 0.12), wood, pos + Vector3(0.1, 0.03, 0), Vector3(0, randf_range(-40, 40), 8))
	add_mesh(parent, cyl(0.05, 0.18, 6), rust, pos + Vector3(-0.15, 0.05, 0.08), Vector3(80, 20, 0))
	add_mesh(parent, box(0.18, 0.03, 0.14), wood, pos + Vector3(0.05, 0.025, -0.12), Vector3(0, 50, 0))


static func lamp_post(parent: Node, pos: Vector3, lit := true, store: Array = []) -> void:
	var iron := Tex.mat("rust", Color(0.35, 0.3, 0.28), 0.55, 0.4)
	add_mesh(parent, cyl(0.07, 3.2, 6), iron, pos + Vector3(0, 1.6, 0))
	# arm
	add_mesh(parent, box(0.08, 0.08, 0.7), iron, pos + Vector3(0, 3.15, 0.25))
	var glass_col := Color(1.0, 0.75, 0.4) if lit else Color(0.25, 0.22, 0.18)
	var glass := Tex.unlit_em(glass_col, 2.2 if lit else 0.0)
	if not lit:
		glass = Tex.mat("rust", Color(0.3, 0.25, 0.2), 0.8)
	var lantern := add_mesh(parent, box(0.28, 0.38, 0.28), glass, pos + Vector3(0, 3.0, 0.55))
	add_mesh(parent, box(0.32, 0.06, 0.32), iron, pos + Vector3(0, 3.22, 0.55))
	add_mesh(parent, box(0.32, 0.06, 0.32), iron, pos + Vector3(0, 2.8, 0.55))
	if lit:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.72, 0.4)
		l.light_energy = 1.35
		l.omni_range = 8.0
		l.omni_attenuation = 1.4
		l.position = pos + Vector3(0, 3.0, 0.55)
		parent.add_child(l)
		store.append(l)
	store.append(lantern)


static func scrubby_tree(parent: Node, pos: Vector3, scale := 1.0) -> void:
	var bark := Tex.mat("wood", Color(0.4, 0.3, 0.2))
	var leaf := Tex.mat("moss", Color(0.55, 0.55, 0.35), 1.0)
	add_mesh(parent, cyl(0.12 * scale, 1.4 * scale, 6, 0.07 * scale), bark, pos + Vector3(0, 0.7 * scale, 0))
	# scrubby uneven canopy (not a perfect ball)
	add_mesh(parent, sph(0.55 * scale, 7), leaf, pos + Vector3(0.05 * scale, 1.55 * scale, 0))
	add_mesh(parent, sph(0.35 * scale, 6), leaf, pos + Vector3(-0.3 * scale, 1.35 * scale, 0.15 * scale))
	add_mesh(parent, sph(0.28 * scale, 6), leaf, pos + Vector3(0.25 * scale, 1.7 * scale, -0.15 * scale))


static func boulder(parent: Node, pos: Vector3, scale := 1.0, yaw := 0.0) -> void:
	var m := Tex.mat("rock", Color(0.7, 0.65, 0.58))
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	add_mesh(parent, sph(0.7 * scale, 6), m, pos + Vector3(0, 0.4 * scale, 0), Vector3(15, yaw, 8), Vector3(1.2, 0.75, 1.0))
	if scale > 0.8:
		add_mesh(parent, sph(0.4 * scale, 6), m, pos + Vector3(0.4 * scale, 0.22 * scale, 0.1), Vector3(0, yaw + 20, 0))


static func rope_post(parent: Node, pos: Vector3) -> void:
	var wood := Tex.mat("wood", Color(0.5, 0.35, 0.2))
	add_mesh(parent, cyl(0.07, 1.1, 6), wood, pos + Vector3(0, 0.55, 0))


static func rope_line(parent: Node, a: Vector3, b: Vector3) -> void:
	var m := Tex.mat("leather", Color(0.45, 0.32, 0.18))
	var mid := (a + b) * 0.5
	var d := b - a
	var len := d.length()
	var c := cyl(0.03, len, 5)
	var mi := add_mesh(parent, c, m, mid + Vector3(0, 0.02, 0))
	var aa := a + Vector3(0, 0.02, 0)
	var bb := b + Vector3(0, 0.02, 0)
	var yaxis := (bb - aa).normalized()
	var xaxis := yaxis.cross(Vector3.FORWARD)
	if xaxis.length() < 0.08:
		xaxis = yaxis.cross(Vector3.RIGHT)
	xaxis = xaxis.normalized()
	var zaxis := xaxis.cross(yaxis).normalized()
	mi.basis = Basis(xaxis, yaxis, zaxis)
	mi.position = mid + Vector3(0, 0.02, 0)


static func net_hang(parent: Node, pos: Vector3, yaw := 0.0) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Tex.get_tex("net")
	m.albedo_color = Color(0.7, 0.58, 0.4)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(2.2, 1.6)
	add_mesh(parent, q, m, pos + Vector3(0, 0.9, 0), Vector3(0, yaw, 0))


static func crane(parent: Node, pos: Vector3, yaw := -20.0) -> void:
	var rust := Tex.mat("rust", Color(0.65, 0.45, 0.3), 0.55, 0.35)
	var wood := Tex.mat("wood", Color(0.5, 0.35, 0.2))
	# tower
	add_mesh(parent, box(1.2, 7.0, 1.2), rust, pos + Vector3(0, 3.5, 0), Vector3(0, yaw, 0))
	add_mesh(parent, box(0.2, 7.0, 0.2), rust, pos + Vector3(0.55, 3.5, 0.55), Vector3(0, yaw, 0))
	add_mesh(parent, box(0.2, 7.0, 0.2), rust, pos + Vector3(-0.55, 3.5, 0.55), Vector3(0, yaw, 0))
	# cab
	add_mesh(parent, box(1.6, 1.2, 1.6), rust, pos + Vector3(0, 7.4, 0), Vector3(0, yaw, 0))
	# boom
	var boom := add_mesh(parent, box(0.35, 0.35, 8.5), rust, pos + Vector3(0, 7.6, -3.2), Vector3(12, yaw, 0))
	# stay
	add_mesh(parent, box(0.08, 0.08, 6.0), rust, pos + Vector3(0, 8.6, -2.0), Vector3(-18, yaw, 0))
	# hook
	var hook_pos := pos + Vector3(sin(deg_to_rad(yaw)) * -6.0, 4.2, -cos(deg_to_rad(yaw)) * -6.0)
	# approximate hook under boom tip toward -Z when yaw~0
	add_mesh(parent, cyl(0.03, 3.2, 5), rust, pos + Vector3(0, 5.8, -6.5), Vector3(0, yaw, 0))
	add_mesh(parent, cyl(0.08, 0.25, 6, 0.02), rust, pos + Vector3(0, 4.2, -6.5), Vector3(0, 0, 90))
	add_mesh(parent, box(1.4, 0.4, 1.0), wood, pos + Vector3(1.1, 0.25, 0.2), Vector3(0, yaw, 0))
	store_unused(boom, hook_pos)


static func store_unused(_a, _b) -> void:
	pass


static func lighthouse(parent: Node, pos: Vector3, fx: Dictionary) -> void:
	var stone := Tex.mat("rock", Color(0.62, 0.56, 0.46))
	stone.uv1_triplanar = true
	var rust := Tex.mat("rust", Color(0.55, 0.4, 0.28), 0.6, 0.2)
	var stripe := Tex.mat("peel", Color(0.7, 0.45, 0.28))
	# rock base / jetty
	boulder(parent, pos + Vector3(-1.2, 0, 0.4), 1.6, 20)
	boulder(parent, pos + Vector3(1.4, 0, -0.5), 1.3, 50)
	add_mesh(parent, cyl(2.4, 1.2, 8, 2.1), stone, pos + Vector3(0, 0.6, 0))
	# tower, slightly tapered
	add_mesh(parent, cyl(1.35, 9.0, 10, 0.95), stone, pos + Vector3(0, 5.5, 0))
	# weathered mid band
	add_mesh(parent, cyl(1.2, 1.6, 10, 1.1), stripe, pos + Vector3(0, 6.5, 0))
	# gallery
	add_mesh(parent, cyl(1.35, 0.18, 10), rust, pos + Vector3(0, 10.1, 0))
	# lantern room
	var glass := Tex.unlit_em(Color(1.0, 0.78, 0.45), 3.0)
	var room := add_mesh(parent, cyl(0.7, 1.3, 8), glass, pos + Vector3(0, 10.85, 0))
	add_mesh(parent, cyl(0.85, 0.2, 8), rust, pos + Vector3(0, 11.55, 0))
	# cap
	add_mesh(parent, cyl(0.85, 0.7, 8, 0.05), rust, pos + Vector3(0, 12.0, 0))
	# door
	add_mesh(parent, box(0.5, 1.3, 0.12), Tex.mat("wood", Color(0.35, 0.22, 0.12)), pos + Vector3(0, 1.9, 1.2))
	# rotating beam
	var head := Node3D.new()
	head.name = "LighthouseHead"
	head.position = pos + Vector3(0, 10.85, 0)
	parent.add_child(head)
	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.82, 0.55)
	spot.light_energy = 6.0
	spot.spot_range = 48.0
	spot.spot_angle = 22.0
	spot.spot_attenuation = 0.6
	spot.rotation_degrees = Vector3(-8, 0, 0)
	head.add_child(spot)
	# faint beam quad (unshaded, additive-ish via light emission + alpha scissor stripes)
	var beam_m := StandardMaterial3D.new()
	beam_m.albedo_color = Color(1.0, 0.85, 0.55, 0.18)
	beam_m.emission_enabled = true
	beam_m.emission = Color(1.0, 0.8, 0.5)
	beam_m.emission_energy_multiplier = 0.8
	beam_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var beam := QuadMesh.new()
	beam.size = Vector2(3.5, 22.0)
	var bmi := add_mesh(head, beam, beam_m, Vector3(0, -0.2, -11.5), Vector3(-90, 0, 0))
	bmi.position = Vector3(0, -1.0, -12.0)
	fx["lighthouse"] = head
	fx["lamp_room"] = room


static func cave_mouth(parent: Node, pos: Vector3, yaw := 40.0) -> void:
	var rock := Tex.mat("rock", Color(0.5, 0.46, 0.4))
	rock.uv1_triplanar = true
	# mound of boulders
	for i in 7:
		var a := TAU * float(i) / 7.0
		boulder(parent, pos + Vector3(cos(a) * 2.6, 0, sin(a) * 1.6), randf_range(1.1, 1.8), rad_to_deg(a))
	add_mesh(parent, sph(3.2, 7), rock, pos + Vector3(0, 1.4, -0.8), Vector3(0, yaw, 0), Vector3(1.3, 0.85, 1.0))
	add_mesh(parent, sph(2.2, 7), rock, pos + Vector3(-1.6, 2.0, -0.4), Vector3(0, yaw, 0))
	add_mesh(parent, sph(2.4, 7), rock, pos + Vector3(1.8, 1.8, -0.5), Vector3(0, yaw, 0))
	# Dark mouth (no interior) — a deep hole framed by a rocky ring, facing town.
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.025, 0.02, 0.015)
	dark.roughness = 1.0
	var fwd := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	var ring := Tex.mat("rock", Color(0.38, 0.34, 0.28))
	ring.uv1_triplanar = true
	add_mesh(parent, cyl(1.85, 0.7, 10, 1.85), ring, pos + Vector3(0, 1.45, 0) + fwd * 1.6, Vector3(90, yaw, 0))
	var mouth := cyl(1.45, 1.4, 10, 1.15)
	add_mesh(parent, mouth, dark, pos + Vector3(0, 1.45, 0) + fwd * 1.2, Vector3(90, yaw, 0))
	# inner shadow disc so the hole reads at a distance
	add_mesh(parent, cyl(1.2, 0.15, 10), dark, pos + Vector3(0, 1.45, 0) + fwd * 0.4, Vector3(90, yaw, 0))
	# little crates hinting at smugglers
	crate(parent, pos + fwd * 2.4 + Vector3(-1.0, 0, 0), 20, 0.8)
	barrel(parent, pos + fwd * 2.2 + Vector3(1.0, 0, 0), 15)
	var sign := Label3D.new()
	sign.text = "KEEP OUT"
	sign.font_size = 48
	sign.pixel_size = 0.006
	sign.modulate = Color(0.25, 0.12, 0.08)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sign.position = pos + fwd * 2.3 + Vector3(0.6, 1.7, 0)
	sign.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(sign)


static func silt_strider(parent: Node, pos: Vector3, yaw := -30.0) -> void:
	# Flea-on-stilts silhouette (Morrowind silt strider), not a water tower.
	# No face, no eyes.
	var chitin := Tex.mat("leather", Color(0.30, 0.20, 0.13), 0.9)
	var dark := Tex.mat("leather", Color(0.16, 0.11, 0.08), 0.92)
	var wood := Tex.mat("wood", Color(0.38, 0.26, 0.15))
	var canvas := Tex.mat("peel", Color(0.48, 0.36, 0.22))
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(root)
	# Hunched flea thorax, long on Z
	add_mesh(root, sph(2.5, 8), chitin, Vector3(0, 10.6, -0.2), Vector3(22, 0, 0), Vector3(1.05, 0.9, 1.85))
	# Drooping abdomen
	add_mesh(root, sph(2.15, 8), dark, Vector3(0, 9.6, 2.8), Vector3(32, 0, 0), Vector3(1.1, 0.85, 1.4))
	# Head lump + downward snout (no eye sockets)
	add_mesh(root, sph(1.15, 7), dark, Vector3(0, 10.3, -2.7), Vector3(35, 0, 0), Vector3(0.95, 0.8, 1.15))
	add_mesh(root, cyl(0.5, 2.2, 7, 0.1), dark, Vector3(0, 9.0, -4.0), Vector3(58, 0, 0))
	# Small howdah: open wooden platform and canvas fly, not a tank cap
	add_mesh(root, box(2.1, 0.18, 2.5), wood, Vector3(0, 12.35, -0.15))
	for xz in [Vector3(-0.9, 0, -1.05), Vector3(0.9, 0, -1.05), Vector3(-0.9, 0, 1.0), Vector3(0.9, 0, 1.0)]:
		add_mesh(root, box(0.08, 1.15, 0.08), wood, Vector3(xz.x, 12.95, xz.z))
	add_mesh(root, box(2.2, 0.08, 2.6), canvas, Vector3(0, 13.55, -0.15))
	add_mesh(root, box(2.15, 0.12, 0.08), wood, Vector3(0, 12.7, -1.15))
	# Six splayed legs with knees kicked outward
	var feet := [
		Vector3(-3.4, 0, -2.6), Vector3(3.4, 0, -2.4),
		Vector3(-4.4, 0, 0.3), Vector3(4.4, 0, 0.5),
		Vector3(-3.0, 0, 3.2), Vector3(3.1, 0, 3.3)
	]
	for f in feet:
		var hip := Vector3(signf(f.x) * 1.35, 10.2, f.z * 0.4)
		var knee := Vector3(signf(f.x) * (absf(f.x) + 1.6), 5.6, f.z * 0.85)
		_leg(root, chitin, dark, hip, knee, f)


static func _leg(root: Node, chitin: Material, dark: Material, hip: Vector3, knee: Vector3, foot: Vector3) -> void:
	_bone(root, chitin, hip, knee, 0.32)
	_bone(root, dark, knee, foot + Vector3(0, 0.25, 0), 0.20)
	add_mesh(root, sph(0.42, 6), dark, knee)
	add_mesh(root, sph(0.48, 6), dark, foot + Vector3(0, 0.28, 0), Vector3.ZERO, Vector3(1.5, 0.45, 1.1))


static func _bone(root: Node, mat: Material, a: Vector3, b: Vector3, r: float) -> void:
	var mid := (a + b) * 0.5
	var len := a.distance_to(b)
	if len < 0.001:
		return
	var c := cyl(r, len, 6, r * 0.7)
	var mi := add_mesh(root, c, mat, mid)
	var yaxis := (b - a).normalized()
	var xaxis := yaxis.cross(Vector3.FORWARD)
	if xaxis.length() < 0.08:
		xaxis = yaxis.cross(Vector3.RIGHT)
	xaxis = xaxis.normalized()
	var zaxis := xaxis.cross(yaxis).normalized()
	mi.basis = Basis(xaxis, yaxis, zaxis)
	mi.position = mid


static func style_bug(b: MeshInstance3D) -> void:
	var chitin := Tex.mat("leather", Color(0.22, 0.16, 0.1), 0.85)
	b.material_override = chitin
	# already a stretched sphere; add a little shell bump as child if empty
	if b.get_child_count() == 0:
		var shell := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radial_segments = 6
		s.rings = 3
		s.radius = 0.45
		s.height = 0.7
		shell.mesh = s
		shell.material_override = Tex.mat("leather", Color(0.3, 0.2, 0.1))
		shell.position = Vector3(0, 0.15, -0.05)
		b.add_child(shell)
		# legs as tiny boxes, no face
		for i in 3:
			var leg := MeshInstance3D.new()
			leg.mesh = box(0.06, 0.08, 0.35)
			leg.material_override = chitin
			leg.position = Vector3(-0.35, -0.15, -0.2 + i * 0.2)
			b.add_child(leg)
			var leg2 := MeshInstance3D.new()
			leg2.mesh = box(0.06, 0.08, 0.35)
			leg2.material_override = chitin
			leg2.position = Vector3(0.35, -0.15, -0.2 + i * 0.2)
			b.add_child(leg2)


static func style_fairy(fairy: MeshInstance3D) -> void:
	if fairy.mesh is SphereMesh:
		var sm: SphereMesh = fairy.mesh
		sm.radius = 0.08
		sm.height = 0.16
	fairy.material_override = Tex.unlit_em(Color(1.0, 0.78, 0.45), 0.9)
	for c in fairy.get_children():
		if c is OmniLight3D:
			c.light_color = Color(1.0, 0.78, 0.45)
			c.light_energy = 0.8
			c.omni_range = 3.5
	# soft motes
	var p := CPUParticles3D.new()
	p.amount = 6
	p.lifetime = 1.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2
	p.direction = Vector3(0, 1, 0)
	p.spread = 80
	p.gravity = Vector3(0, 0.2, 0)
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.35
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.7
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(1, 0.9, 0.6, 0.7)
	pm.emission_enabled = true
	pm.emission = Color(1, 0.85, 0.5)
	pm.emission_energy_multiplier = 1.2
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	p.mesh = q
	p.material_override = pm
	fairy.add_child(p)


static func stray_dog(parent: Node, pos: Vector3, fx_list: Array) -> void:
	var fur := Tex.mat("leather", Color(0.4, 0.3, 0.2))
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	add_mesh(root, box(0.22, 0.2, 0.45), fur, Vector3(0, 0.28, 0))
	add_mesh(root, sph(0.12, 6), fur, Vector3(0, 0.34, -0.28))  # head, no face details
	add_mesh(root, box(0.04, 0.1, 0.08), fur, Vector3(-0.08, 0.44, -0.28))
	add_mesh(root, box(0.04, 0.1, 0.08), fur, Vector3(0.08, 0.44, -0.28))
	add_mesh(root, cyl(0.03, 0.22, 5), fur, Vector3(0, 0.3, 0.28), Vector3(70, 0, 0))
	for x in [-0.08, 0.08]:
		for z in [-0.14, 0.14]:
			add_mesh(root, cyl(0.03, 0.22, 5), fur, Vector3(x, 0.11, z))
	fx_list.append({"node": root, "home": pos, "r": 2.5, "speed": 0.7, "t": randf() * TAU, "kind": "dog"})


static func stray_cat(parent: Node, pos: Vector3, fx_list: Array) -> void:
	var fur := Tex.mat("leather", Color(0.28, 0.24, 0.2) if randf() > 0.5 else Color(0.55, 0.42, 0.28))
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	add_mesh(root, box(0.14, 0.12, 0.28), fur, Vector3(0, 0.16, 0))
	add_mesh(root, sph(0.08, 6), fur, Vector3(0, 0.2, -0.18))
	add_mesh(root, box(0.03, 0.08, 0.04), fur, Vector3(-0.05, 0.28, -0.18))
	add_mesh(root, box(0.03, 0.08, 0.04), fur, Vector3(0.05, 0.28, -0.18))
	add_mesh(root, cyl(0.02, 0.28, 5), fur, Vector3(0, 0.28, 0.18), Vector3(-50, 0, 0))
	for x in [-0.05, 0.05]:
		for z in [-0.08, 0.08]:
			add_mesh(root, cyl(0.02, 0.14, 5), fur, Vector3(x, 0.07, z))
	fx_list.append({"node": root, "home": pos, "r": 1.8, "speed": 0.45, "t": randf() * TAU, "kind": "cat"})


static func collider(parent: Node, pos: Vector3, size: Vector3, rot := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	parent.add_child(body)
	return body


static func palm(parent: Node, pos: Vector3, scale := 1.0) -> void:
	var trunk := Tex.mat("wood", Color(0.45, 0.32, 0.16))
	var frond := Tex.mat("moss", Color(0.25, 0.62, 0.28), 1.0)
	add_mesh(parent, cyl(0.14 * scale, 3.2 * scale, 6, 0.08 * scale), trunk, pos + Vector3(0, 1.6 * scale, 0))
	# simple frond crown
	for i in 5:
		var a := float(i) * TAU / 5.0
		var q := QuadMesh.new()
		q.size = Vector2(1.6 * scale, 0.7 * scale)
		var m := frond.duplicate()
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		add_mesh(parent, q, m, pos + Vector3(cos(a) * 0.45 * scale, 3.3 * scale, sin(a) * 0.45 * scale), Vector3(-40, rad_to_deg(a), 0))
	add_mesh(parent, sph(0.35 * scale, 6), frond, pos + Vector3(0, 3.25 * scale, 0))


static func bush(parent: Node, pos: Vector3, scale := 1.0) -> void:
	var leaf := Tex.mat("moss", Color(0.22, 0.55, 0.24), 1.0)
	add_mesh(parent, sph(0.45 * scale, 6), leaf, pos + Vector3(0, 0.35 * scale, 0), Vector3.ZERO, Vector3(1.2, 0.8, 1.0))
	add_mesh(parent, sph(0.3 * scale, 6), leaf, pos + Vector3(0.25 * scale, 0.4 * scale, 0.1 * scale))
