extends Node3D
## Elemental magic: enemy casters, bolts, elemental wards, and levitation.
## Settings in res://data/spells.json. Kid-safe: hits flash and push you back;
## beaten casters vanish in a puff of light and run home.

const LowPoly = preload("res://art/lowpoly_character.gd")

var main: Node3D
var cfg: Dictionary = {}
var elements: Array = []
var element_index := 0
# player ward
var ward_element := ""
var ward_left := 0.0
var ward_node: MeshInstance3D
# levitation
var levitating := false
var lev_left := 0.0
var lift := 0.0           # -1..1 from Up / Down buttons
var lev_light: OmniLight3D
var lev_disc: MeshInstance3D
# enemies / bolts
var enemies: Array = []
var bolts: Array = []
var spawn_timer := 10.0
var rng := RandomNumberGenerator.new()
var enabled := true

const SPAWNS := [
	Vector3(-1.5, 0, 12.0), Vector3(2.0, 0, 11.0), Vector3(-9.0, 0, 6.0), Vector3(9.0, 0, 7.0),
	Vector3(0.0, 0, -17.5), Vector3(-7.5, 0, -16.0), Vector3(8.5, 0, -17.0), Vector3(-14.0, 0, 3.0),
	Vector3(14.0, 0, 1.0)
]


func setup(m: Node3D) -> void:
	main = m
	rng.seed = 7
	var f := FileAccess.open("res://data/spells.json", FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			cfg = d
	elements = cfg.get("elements", [])
	spawn_timer = float(_e().get("first_spawn_seconds", 10))


func _e() -> Dictionary:
	return cfg.get("enemy", {})


func element() -> Dictionary:
	return elements[element_index] if elements.size() > 0 else {"id": "fire", "name": "Fire", "color": "#e07a3a", "beats": "frost"}


func el(id: String) -> Dictionary:
	for e in elements:
		if e["id"] == id:
			return e
	return {"id": id, "name": id.capitalize(), "color": "#ffffff", "beats": ""}


func el_color(id: String) -> Color:
	return Color.html(str(el(id).get("color", "#ffffff")))


func beats(a: String, b: String) -> bool:
	return str(el(a).get("beats", "")) == b


func next_element() -> void:
	element_index = (element_index + 1) % maxi(1, elements.size())


# ---------------------------------------------------------------- player spells

func cast_bolt() -> String:
	var b: Dictionary = cfg.get("bolt", {})
	var cost := float(b.get("mana", 12))
	if main.mana < cost:
		return "Not enough mana. The fairy will refill you."
	main.mana -= cost
	var from: Vector3 = fingertips()
	var target = _nearest_enemy(float(b.get("range", 22)))
	var dir: Vector3
	if target:
		dir = (target["node"].global_position + Vector3(0, 1.1, 0) - from).normalized()
	else:
		dir = -main.hero.global_transform.basis.z
	var id := str(element()["id"])
	var speed := float(b.get("speed", 13))
	if id == "lightning":
		speed *= 2.4
		_spark(from, el_color(id))
	_spawn_bolt(from + dir * 0.3, dir * speed, id, false, float(b.get("damage", 14)))
	return ""


## Right-hand fingertips in world space (bolts leave the hand, not the chest).
func fingertips() -> Vector3:
	# The cast pose throws the right arm straight ahead, so start where that hand will be.
	var arm: Node3D = main.hero.get_node_or_null("Body/ArmR")
	var fwd: Vector3 = -main.hero.global_transform.basis.z
	if arm:
		return arm.global_position + fwd * 0.8 + Vector3(0, -0.05, 0)
	return main.hero.global_position + Vector3(0, 0.35, 0)


func weapon_cfg(id: String) -> Dictionary:
	return cfg.get("weapons", {}).get(id, {})


# ---------------------------------------------------------------- sword and crossbow

## Sword: hits every caster in a wedge in front of the hero. Wards do not stop steel,
## but a warded caster only takes half.
func sword_slash() -> void:
	var w := weapon_cfg("sword")
	var reach := float(w.get("reach", 2.6))
	var half := deg_to_rad(float(w.get("arc_degrees", 110)) * 0.5)
	var fwd: Vector3 = -main.hero.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var hit := 0
	for e in enemies.duplicate():
		var to: Vector3 = e["node"].global_position - main.hero.global_position
		to.y = 0.0
		if to.length() > reach + 0.5 or to.length() < 0.01:
			continue
		if fwd.angle_to(to.normalized()) > half:
			continue
		hit += 1
		var dmg := float(w.get("damage", 16))
		if e["ward"] != "":
			dmg *= 0.5
		_puff(e["node"].global_position + Vector3(0, 1.1, 0), Color(0.95, 0.95, 1.0), 1.2)
		_hurt(e, dmg, to.normalized())
	_swoosh()
	if hit == 0:
		main.toast("Swish! Get closer to slash.")


## Crossbow: a fast bone arrow straight down the aim line (auto-aims at the nearest caster ahead).
func shoot_arrow() -> void:
	var w := weapon_cfg("crossbow")
	var from: Vector3 = main.hero.global_position + Vector3(0, 0.45, 0)
	var fore: Node3D = main.hero.get_node_or_null("Body/ArmR/ForeR")
	if fore:
		from = fore.global_transform * Vector3(0, -0.8, 0.115)
	var dir: Vector3 = -main.hero.global_transform.basis.z
	var target = _nearest_enemy(float(w.get("range", 30)))
	if target:
		var to: Vector3 = target["node"].global_position + Vector3(0, 1.1, 0) - from
		if to.normalized().dot(dir) > 0.5:
			dir = to.normalized()
	var n := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.035, 0.035, 0.5)
	n.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.88, 0.76)
	n.material_override = m
	var tip := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.07, 0.1, 0.05)
	tip.mesh = pm
	tip.rotation.x = -PI / 2
	tip.position = Vector3(0, 0, -0.29)
	tip.material_override = m
	n.add_child(tip)
	add_child(n)
	n.global_position = from
	n.look_at(from + dir, Vector3.UP)
	bolts.append({"node": n, "vel": dir * float(w.get("speed", 26)), "el": "arrow", "hostile": false,
		"dmg": float(w.get("damage", 18)), "life": 2.0, "arrow": true})


func _hurt(e: Dictionary, dmg: float, push_dir: Vector3) -> void:
	e["health"] -= dmg
	e["node"].position += push_dir * 0.7
	if e["health"] <= 0.0:
		_defeat(e)


func _swoosh() -> void:
	# A pale arc in front of the hero for the sword swing.
	var n := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.25; tm.outer_radius = 1.4; tm.rings = 10; tm.ring_segments = 3
	n.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.95, 1.0, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	n.material_override = m
	main.hero.add_child(n)
	n.position = Vector3(0, 0.2, -0.6)
	n.rotation = Vector3(0.15, 0, 0.5)
	n.scale = Vector3(1, 0.2, 1)
	var tw := create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(n.queue_free)


## Little crackle of light at the fingertips.
func _spark(at: Vector3, c: Color) -> void:
	var n := MeshInstance3D.new()
	n.mesh = _zigzag(0.5, 4)
	n.material_override = _glow_mat(c)
	add_child(n)
	n.global_position = at
	n.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_callback(n.queue_free)


static func _glow_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.lightened(0.3)
	m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 3.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## Jagged lightning streak along -Z: a chain of thin boxes, one mesh.
static func _zigzag(length: float, segs: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var p := Vector3.ZERO
	for i in segs:
		var q := Vector3(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12), -length * float(i + 1) / segs)
		if i == segs - 1:
			q = Vector3(0, 0, -length)
		var d := q - p
		var side := d.cross(Vector3.UP).normalized() * 0.025
		var up := d.cross(side).normalized() * 0.025
		for o in [side, up]:
			st.add_vertex(p - o); st.add_vertex(p + o); st.add_vertex(q + o)
			st.add_vertex(p - o); st.add_vertex(q + o); st.add_vertex(q - o)
		p = q
	return st.commit()


func cast_ward() -> String:
	var w: Dictionary = cfg.get("ward", {})
	var cost := float(w.get("mana", 25))
	if main.mana < cost:
		return "Not enough mana for a ward."
	main.mana -= cost
	ward_element = str(element()["id"])
	ward_left = float(w.get("seconds", 15))
	_make_ward()
	return "%s is up!" % str(element().get("ward", "Ward"))


func toggle_float() -> String:
	if levitating:
		stop_float()
		return "Floating down gently."
	var l: Dictionary = cfg.get("levitate", {})
	var cost := float(l.get("mana_start", 10))
	if main.mana < cost:
		return "Not enough mana to float."
	main.mana -= cost
	levitating = true
	lev_left = float(l.get("seconds", 25))
	if lev_light == null:
		lev_light = OmniLight3D.new()
		lev_light.light_color = Color(0.7, 0.9, 1.0)
		lev_light.light_energy = 0.9
		lev_light.omni_range = 4.0
		main.hero.add_child(lev_light)
		lev_disc = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.7; cm.bottom_radius = 0.5; cm.height = 0.05; cm.radial_segments = 8
		lev_disc.mesh = cm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.6, 0.9, 1.0, 0.35)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		lev_disc.material_override = m
		lev_disc.position = Vector3(0, -1.05, 0)
		main.hero.add_child(lev_disc)
	lev_light.visible = true
	lev_disc.visible = true
	return "You float! Use Up and Down."


func stop_float() -> void:
	levitating = false
	lift = 0.0
	if lev_light:
		lev_light.visible = false
		lev_disc.visible = false


## Vertical speed for the hero this frame.
func vertical_speed(hero_y: float) -> float:
	var l: Dictionary = cfg.get("levitate", {})
	var top := 1.0 + float(l.get("max_height", 9))
	if levitating:
		var v := lift * float(l.get("rise_speed", 2.6))
		if hero_y >= top and v > 0.0:
			v = 0.0
		return v
	if hero_y > 1.001:
		return -float(l.get("land_speed", 2.2))
	return 0.0


func _make_ward() -> void:
	if ward_node == null:
		ward_node = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.05; s.height = 2.3; s.radial_segments = 8; s.rings = 5
		ward_node.mesh = s
		ward_node.position = Vector3(0, -0.1, 0)
		main.hero.add_child(ward_node)
	ward_node.material_override = _ward_mat(el_color(ward_element))
	ward_node.visible = true
	ward_node.scale = Vector3.ONE


static func _ward_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.26)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = c
	return m


func _nearest_enemy(maxd: float):
	var best = null
	var bd := maxd
	for e in enemies:
		var d: float = e["node"].global_position.distance_to(main.hero.global_position)
		if d < bd:
			bd = d
			best = e
	return best


# ---------------------------------------------------------------- enemies

func spawn_enemy(near := Vector3.INF) -> Dictionary:
	var night: bool = main.is_night()
	var kinds: Array = cfg.get("enemies", [])
	var kind: Dictionary = {}
	for k in kinds:
		if (k.get("when", "day") == "night") == night:
			kind = k
	if kind.is_empty() and kinds.size() > 0:
		kind = kinds[0]
	var look: Dictionary = kind.get("look", {})
	var els: Array = kind.get("elements", ["fire"])
	var element_id := str(els[rng.randi() % els.size()])
	var pos := near
	if pos == Vector3.INF:
		pos = _spawn_spot()
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var p := {
		"skin": look.get("skin", "#a8805c"), "hair": look.get("hair", "crop"),
		"hair_color": Color(0.15, 0.12, 0.1), "build": "average",
		"gear": {"head": "pilgrim_hood", "shirt": "fisher_smock", "robe": "counting_robe",
			"pants": "dock_trousers", "boots": "low_shoes", "belt": "dyed_sash",
			"glove_l": "cloth_wraps", "glove_r": "cloth_wraps"},
		"tints": {"robe": look.get("robe", "#5a2e26"), "head": look.get("hood", "#4a2a22"), "belt": look.get("trim", "#8a6a3a")}
	}
	var body := LowPoly.build(root, p)
	var lb := Label3D.new()
	lb.text = "%s (%s)" % [kind.get("name", "Caster"), el(element_id)["name"]]
	lb.font_size = 40
	lb.pixel_size = 0.006
	lb.outline_size = 6
	lb.modulate = el_color(element_id).lightened(0.2)
	lb.outline_modulate = Color(0.1, 0.07, 0.04)
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.position = Vector3(0, 2.25, 0)
	root.add_child(lb)
	var e := {
		"node": root, "body": body, "label": lb, "name": kind.get("name", "Caster"),
		"element": element_id, "health": float(_e().get("health", 30)),
		"ward": "", "ward_node": null, "state": "walk", "t": rng.randf_range(0.5, 1.5),
		"phase": 0.0, "orb": null
	}
	if rng.randf() < float(_e().get("ward_chance", 0.5)):
		_enemy_ward(e, element_id)
	enemies.append(e)
	return e


func _enemy_ward(e: Dictionary, id: String) -> void:
	e["ward"] = id
	var wn := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.0; s.height = 2.2; s.radial_segments = 8; s.rings = 5
	wn.mesh = s
	wn.position = Vector3(0, 0.95, 0)
	wn.material_override = _ward_mat(el_color(id))
	e["node"].add_child(wn)
	e["ward_node"] = wn


func _spawn_spot() -> Vector3:
	var hp: Vector3 = main.hero.global_position
	var best: Vector3 = SPAWNS[0]
	var bs := 1e9
	for s in SPAWNS:
		var d: float = Vector2(s.x - hp.x, s.z - hp.z).length()
		var score := absf(d - 13.0) + rng.randf() * 3.0
		if d > 8.0 and score < bs:
			bs = score
			best = s
	return best


func _physics_process(delta: float) -> void:
	if main == null or not enabled:
		return
	var t := Time.get_ticks_msec() / 1000.0
	# player ward timer
	if ward_left > 0.0:
		ward_left -= delta
		if ward_node:
			ward_node.rotation.y += delta * 0.6
			var pulse := 1.0 + sin(t * 4.0) * 0.02
			ward_node.scale = Vector3.ONE * pulse
		if ward_left <= 0.0:
			ward_element = ""
			if ward_node:
				ward_node.visible = false
			main.toast("Your ward faded.")
	# levitation
	if levitating:
		lev_left -= delta
		main.mana = maxf(0.0, main.mana - float(cfg.get("levitate", {}).get("mana_per_second", 2)) * delta)
		if lev_left <= 0.0 or main.mana <= 0.5:
			stop_float()
			main.toast("Float is over. Landing gently.")
	# spawning
	if main.panel_open():
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = float(_e().get("respawn_seconds", 25))
		if enemies.size() < int(_e().get("max_active", 2)):
			spawn_enemy()
	for e in enemies.duplicate():
		_enemy_tick(e, delta, t)
	for b in bolts.duplicate():
		_bolt_tick(b, delta)


func _enemy_tick(e: Dictionary, delta: float, t: float) -> void:
	var root: Node3D = e["node"]
	var hero_p: Vector3 = main.hero.global_position
	var to: Vector3 = hero_p - root.global_position
	to.y = 0.0
	var dist := to.length()
	if to.length() > 0.01:
		root.rotation.y = lerp_angle(root.rotation.y, atan2(to.x, to.z), clampf(delta * 5.0, 0.0, 1.0))
	if e["ward_node"]:
		e["ward_node"].rotation.y += delta * 0.5
	var keep := float(_e().get("keep_distance", 9))
	var walk := 0.0
	e["t"] -= delta
	if dist > 30.0:
		e["state"] = "idle"
	match e["state"]:
		"idle":
			if dist < 24.0:
				e["state"] = "walk"
		"walk":
			if dist > keep:
				var step := float(_e().get("walk_speed", 2.0)) * delta
				root.position += to.normalized() * step
				walk = 1.0
				e["phase"] += step * 3.2
			elif e["t"] <= 0.0:
				e["state"] = "windup"
				e["t"] = float(_e().get("wind_up_seconds", 1.2))
				_make_orb(e)
		"windup":
			var total := float(_e().get("wind_up_seconds", 1.2))
			var k := 1.0 - clampf(e["t"] / total, 0.0, 1.0)
			if e["orb"]:
				e["orb"].scale = Vector3.ONE * (0.3 + k * 1.2)
			if e["t"] <= 0.0:
				_enemy_fire(e)
				e["state"] = "walk"
				e["t"] = float(_e().get("cooldown_seconds", 3.4))
	var body: Node3D = e["body"]
	LowPoly.animate(body, e["phase"], walk, t)
	if e["state"] == "windup":
		var arm := body.get_node_or_null("ArmR")
		if arm:
			arm.rotation.x = -2.3 + sin(t * 18.0) * 0.05
		var arm2 := body.get_node_or_null("ArmL")
		if arm2:
			arm2.rotation.x = -1.2


func _make_orb(e: Dictionary) -> void:
	var fore: Node3D = e["body"].get_node_or_null("ArmR/ForeR")
	if fore == null:
		return
	var orb := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12; s.height = 0.24; s.radial_segments = 6; s.rings = 3
	orb.mesh = s
	var c := el_color(e["element"])
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 2.2
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb.material_override = m
	orb.position = Vector3(0, -0.45, 0)
	fore.add_child(orb)
	var l := OmniLight3D.new()
	l.light_color = c; l.light_energy = 1.2; l.omni_range = 3.0
	orb.add_child(l)
	e["orb"] = orb


func _enemy_fire(e: Dictionary) -> void:
	var orb: Node3D = e["orb"]
	var from: Vector3 = e["node"].global_position + Vector3(0, 1.6, 0)
	if orb and is_instance_valid(orb):
		from = orb.global_position
		orb.queue_free()
	e["orb"] = null
	var aim: Vector3 = main.hero.global_position + Vector3(0, 0.1, 0)
	var dir := (aim - from).normalized()
	_spawn_bolt(from, dir * float(_e().get("bolt_speed", 8)), e["element"], true, float(_e().get("bolt_damage", 12)))


func _spawn_bolt(from: Vector3, vel: Vector3, id: String, hostile: bool, dmg: float) -> void:
	var n := MeshInstance3D.new()
	var c := el_color(id)
	if id == "lightning":
		n.mesh = _zigzag(1.6, 6)
		n.material_override = _glow_mat(c)
		n.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
		add_child(n)
		n.global_position = from
		if vel.length() > 0.01:
			n.look_at(from + vel, Vector3.UP)
		var ll := OmniLight3D.new()
		ll.light_color = c; ll.light_energy = 2.0; ll.omni_range = 4.0
		n.add_child(ll)
		bolts.append({"node": n, "vel": vel, "el": id, "hostile": hostile, "dmg": dmg, "life": 2.0, "zig": true})
		return
	var s := SphereMesh.new()
	s.radius = 0.2; s.height = 0.4; s.radial_segments = 6; s.rings = 3
	n.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 2.5
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	n.material_override = m
	n.scale = Vector3(1, 1, 1.8)
	add_child(n)
	n.global_position = from
	if vel.length() > 0.01:
		n.look_at(from + vel, Vector3.UP)
	var l := OmniLight3D.new()
	l.light_color = c; l.light_energy = 1.4; l.omni_range = 3.5
	n.add_child(l)
	bolts.append({"node": n, "vel": vel, "el": id, "hostile": hostile, "dmg": dmg, "life": 3.5})


func _bolt_tick(b: Dictionary, delta: float) -> void:
	var n: Node3D = b["node"]
	n.global_position += b["vel"] * delta
	if b.get("zig", false):
		n.scale = Vector3(1, 1, 1) if randf() < 0.5 else Vector3(-1, 1, 1)
	elif not b.get("arrow", false):
		n.rotate_object_local(Vector3.FORWARD, delta * 8.0)
	b["life"] -= delta
	if b["hostile"]:
		var hc: Vector3 = main.hero.global_position + Vector3(0, -0.05, 0)
		if n.global_position.distance_to(hc) < 0.95:
			_hit_player(b)
			_end_bolt(b)
			return
	else:
		for e in enemies:
			var ec: Vector3 = e["node"].global_position + Vector3(0, 1.0, 0)
			if n.global_position.distance_to(ec) < 1.0:
				_hit_enemy(e, b)
				_end_bolt(b)
				return
	if b["life"] <= 0.0 or n.global_position.y < -0.2:
		_end_bolt(b)


func _end_bolt(b: Dictionary) -> void:
	bolts.erase(b)
	_puff(b["node"].global_position, Color(0.92, 0.88, 0.76) if b.get("arrow", false) else el_color(b["el"]), 0.5 if b.get("arrow", false) else 1.0)
	b["node"].queue_free()


func _hit_player(b: Dictionary) -> void:
	var w: Dictionary = cfg.get("ward", {})
	var dmg: float = b["dmg"]
	var name := str(el(b["el"])["name"])
	var push: Vector3 = b["vel"].normalized()
	if ward_element != "":
		if ward_element == b["el"]:
			dmg *= 1.0 - float(w.get("block_same", 1.0))
			main.toast("Blocked! Your %s stopped the %s bolt." % [el(ward_element)["ward"], name])
		else:
			dmg *= 1.0 - float(w.get("block_other", 0.4))
			main.toast("Your ward softened the %s bolt." % name)
		if ward_node:
			ward_node.scale = Vector3.ONE * 1.18
	if dmg > 0.0:
		main.take_hit(dmg, push * float(_e().get("knockback", 3.0)), el_color(b["el"]))


func _hit_enemy(e: Dictionary, b: Dictionary) -> void:
	var bc: Dictionary = cfg.get("bolt", {})
	var dmg: float = b["dmg"]
	if b.get("arrow", false):
		# Bone arrows ignore the element wheel; a ward still halves them.
		if e["ward"] != "":
			dmg *= 0.5
			main.toast("Their ward slowed the arrow. Try steel or the element that beats it.")
		_hurt(e, dmg, b["vel"].normalized() * Vector3(1, 0, 1))
		return
	if e["ward"] != "":
		if beats(b["el"], e["ward"]):
			main.toast("%s broke their %s!" % [el(b["el"])["name"], el(e["ward"])["ward"]])
			e["ward"] = ""
			if e["ward_node"]:
				_puff(e["ward_node"].global_position, el_color(b["el"]), 2.0)
				e["ward_node"].queue_free()
				e["ward_node"] = null
			dmg *= 0.5
		else:
			dmg *= float(bc.get("soaked", 0.25))
			main.toast("Their ward soaked it. Try the element that beats %s." % el(e["ward"])["name"])
	elif beats(b["el"], e["element"]):
		dmg *= float(bc.get("beats_bonus", 2.0))
	e["health"] -= dmg
	e["node"].position += b["vel"].normalized() * 0.6 * Vector3(1, 0, 1)
	if e["health"] <= 0.0:
		_defeat(e)


func _defeat(e: Dictionary) -> void:
	enemies.erase(e)
	_puff(e["node"].global_position + Vector3(0, 1.0, 0), Color(1.0, 0.95, 0.7), 3.0)
	var coins := int(_e().get("coins_drop", 6))
	main.award_coins(coins, "%s ran home" % e["name"])
	main.toast("The %s vanished in a puff of light and ran home! +%s coins" % [e["name"], TavernSafe.number_text(coins)])
	e["node"].queue_free()
	spawn_timer = maxf(spawn_timer, 12.0)


func _puff(pos: Vector3, c: Color, size := 1.0) -> void:
	var n := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.3 * size; s.height = 0.6 * size; s.radial_segments = 6; s.rings = 3
	n.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	n.material_override = m
	add_child(n)
	n.global_position = pos
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector3.ONE * 2.2, 0.35)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(n.queue_free)


func clear_enemies() -> void:
	for e in enemies:
		e["node"].queue_free()
	enemies.clear()
	for b in bolts:
		b["node"].queue_free()
	bolts.clear()
