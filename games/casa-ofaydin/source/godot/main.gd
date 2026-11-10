extends Node3D
# Milestone 1 prototype: day/night, hero with health + mana, twin-stick move/look, fairy refill, bugs.
# Arrival forms (logic only; no UI in this prototype):
#   var forms := ArrivalForms.new()
#   forms.randomize()
#   # or walk forms.next() / forms.back() / forms.sign_forms()
# See res://scripts/arrival_forms.gd and /workspace/casa-game/character-creation-v0.1.md
const Art = preload("res://art/bootstrap.gd")
const VirtualStick = preload("res://scripts/virtual_stick.gd")
const DAY_LENGTH := 120.0  # seconds for a full day
const WALK_SPEED := 6.0
const YAW_SPEED := 2.4  # radians/sec at full look stick
const PITCH_SPEED := 1.8
const PITCH_MIN := deg_to_rad(-60.0)
const PITCH_MAX := deg_to_rad(60.0)
const LOOK_DRAG := 0.0045  # radians per pixel for empty-screen / mouse look
var time_of_day := 0.3     # 0..1 (0.5 = noon)
var day_count := 1
var health := 100.0
var mana := 100.0
var first_person := false
var sun: DirectionalLight3D
var env: Environment
var hero: CharacterBody3D
var cam: Camera3D
var fairy: MeshInstance3D
var bugs: Array = []
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var clock_label: Label
var left_stick: Control
var right_stick: Control
var look_yaw := 0.0
var look_pitch := deg_to_rad(-18.0)
var look_finger := -1

func _ready() -> void:
	randomize()
	_build_world()
	_build_hero()
	_build_fairy()
	for i in 5: _spawn_bug()
	_build_hud()
	Art.apply(self)
	_apply_camera()

func _mat(c: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if glow:
		m.emission_enabled = true
		m.emission = c
	return m

func _build_world() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new(); sun.shadow_enabled = true; add_child(sun)
	# Collision only — visual ground and town come from art/*.gd
	var body := StaticBody3D.new(); var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(80, 0.2, 80); cs.shape = bs
	cs.position.y = -0.1; body.add_child(cs); add_child(body)

func _build_hero() -> void:
	hero = CharacterBody3D.new(); hero.position = Vector3(0, 1, 0); add_child(hero)
	var mesh := MeshInstance3D.new(); var cap := CapsuleMesh.new(); cap.radial_segments = 8
	mesh.mesh = cap; mesh.material_override = _mat(Color(0.35, 0.2, 0.55)); mesh.name = "Body"; hero.add_child(mesh)
	var cs := CollisionShape3D.new(); cs.shape = CapsuleShape3D.new(); hero.add_child(cs)
	cam = Camera3D.new(); hero.add_child(cam); _apply_camera()

func _apply_camera() -> void:
	var pitch := clampf(look_pitch, PITCH_MIN, PITCH_MAX)
	var body := hero.get_node_or_null("Body")
	if body:
		body.visible = not first_person
	if first_person:
		cam.position = Vector3(0, 1.55, 0.18)
		cam.rotation = Vector3(pitch, 0, 0)
	else:
		var dist := 5.2
		var pivot_h := 1.45
		cam.position = Vector3(0.0, pivot_h - sin(pitch) * dist, cos(pitch) * dist)
		cam.rotation = Vector3(pitch, 0, 0)
	_tilt_head(pitch)

func toggle_camera() -> void:
	first_person = not first_person
	_apply_camera()

func _tilt_head(pitch: float) -> void:
	var head := hero.get_node_or_null("Body/Head")
	if head:
		head.rotation.x = clampf(pitch * 0.35, deg_to_rad(-22.0), deg_to_rad(22.0))

func _build_fairy() -> void:
	fairy = MeshInstance3D.new(); var s := SphereMesh.new(); s.radius = 0.25; s.height = 0.5
	fairy.mesh = s; fairy.material_override = _mat(Color(1, 0.8, 1), true); add_child(fairy)
	var l := OmniLight3D.new(); l.light_color = Color(1, 0.7, 1); l.omni_range = 4; fairy.add_child(l)

func _spawn_bug() -> void:
	var b := MeshInstance3D.new(); var s := SphereMesh.new(); s.radial_segments = 6; s.rings = 3
	b.mesh = s; b.scale = Vector3(1, 0.6, 1.4); b.material_override = _mat(Color(0.15, 0.12, 0.1))
	var a := randf() * TAU
	b.position = Vector3(cos(a) * 30, 0.6, sin(a) * 30); add_child(b); bugs.append(b)
	Art.style_new_bug(b)

func _build_hud() -> void:
	var ui := CanvasLayer.new(); add_child(ui)
	hp_bar = _bar(Color(0.85, 0.15, 0.15), 30); ui.add_child(hp_bar)
	mp_bar = _bar(Color(0.2, 0.4, 0.95), 75); ui.add_child(mp_bar)
	clock_label = Label.new(); clock_label.position = Vector2(30, 120)
	clock_label.add_theme_font_size_override("font_size", 36); ui.add_child(clock_label)
	# Lux and View sit above the right look stick.
	var btn := Button.new(); btn.text = "View"; btn.custom_minimum_size = Vector2(160, 160)
	btn.add_theme_font_size_override("font_size", 40)
	btn.position = Vector2(536, 832); btn.pressed.connect(toggle_camera); ui.add_child(btn)
	var cast := Button.new(); cast.text = "Lux"; cast.custom_minimum_size = Vector2(160, 160)
	cast.add_theme_font_size_override("font_size", 40)
	cast.position = Vector2(536, 656); cast.pressed.connect(cast_lux); ui.add_child(cast)
	left_stick = VirtualStick.new()
	left_stick.setup("Move", Vector2(20, 1008), 248)
	ui.add_child(left_stick)
	right_stick = VirtualStick.new()
	right_stick.setup("Look", Vector2(452, 1008), 248)
	ui.add_child(right_stick)

func _bar(c: Color, y: float) -> ProgressBar:
	var p := ProgressBar.new(); p.position = Vector2(30, y); p.size = Vector2(420, 34); p.show_percentage = false
	var sb := StyleBoxFlat.new(); sb.bg_color = c; p.add_theme_stylebox_override("fill", sb); return p

func cast_lux() -> void:
	# Lux (Latin: light) pops nearby bugs into light. Costs 20 mana.
	if mana < 20: return
	mana -= 20
	for b in bugs.duplicate():
		if b.position.distance_to(hero.position) < 8:
			bugs.erase(b); b.queue_free(); _spawn_bug()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touch_down(e.index, e.position)
		else:
			_touch_up(e.index)
		return
	if e is InputEventScreenDrag:
		_touch_move(e.index, e.position, e.relative)
		return
	if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		_look_delta(e.relative)

func _touch_down(index: int, pos: Vector2) -> void:
	if left_stick.finger < 0 and left_stick.contains_point(pos):
		left_stick.begin(index, pos)
	elif right_stick.finger < 0 and right_stick.contains_point(pos):
		right_stick.begin(index, pos)
	elif look_finger < 0:
		look_finger = index

func _touch_move(index: int, pos: Vector2, relative: Vector2) -> void:
	if index == left_stick.finger:
		left_stick.update_touch(pos)
	elif index == right_stick.finger:
		right_stick.update_touch(pos)
	elif index == look_finger:
		_look_delta(relative)

func _touch_up(index: int) -> void:
	left_stick.end_if(index)
	right_stick.end_if(index)
	if look_finger == index:
		look_finger = -1

func _look_delta(pixels: Vector2) -> void:
	look_yaw -= pixels.x * LOOK_DRAG
	look_pitch -= pixels.y * LOOK_DRAG
	look_pitch = clampf(look_pitch, PITCH_MIN, PITCH_MAX)

func _keyboard_move() -> Vector2:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	return v.limit_length(1.0)

func _physics_process(delta: float) -> void:
	# Day / night
	time_of_day += delta / DAY_LENGTH
	if time_of_day >= 1.0: time_of_day -= 1.0; day_count += 1
	var daylight := clampf(sin(time_of_day * TAU - PI / 2) * 0.5 + 0.5, 0.0, 1.0)
	Art.update_sky(self, time_of_day, daylight)
	var mins := int(time_of_day * 24 * 60)
	clock_label.text = "Day %d  %02d:%02d" % [day_count, mins / 60, mins % 60]
	# Look stick: X turns body + camera yaw, Y tilts pitch.
	var look: Vector2 = right_stick.value
	look_yaw -= look.x * YAW_SPEED * delta
	look_pitch -= look.y * PITCH_SPEED * delta
	look_pitch = clampf(look_pitch, PITCH_MIN, PITCH_MAX)
	# Q/E turn in place (desktop)
	if Input.is_physical_key_pressed(KEY_Q):
		look_yaw += YAW_SPEED * delta
	if Input.is_physical_key_pressed(KEY_E):
		look_yaw -= YAW_SPEED * delta
	hero.rotation.y = look_yaw
	_apply_camera()
	# Camera-relative walk / strafe. Up on the stick is forward. Analog speed.
	var v: Vector2 = (left_stick.value + _keyboard_move()).limit_length(1.0)
	var facing := Basis(Vector3.UP, look_yaw)
	var forward := -facing.z
	var right := facing.x
	var move := right * v.x + forward * (-v.y)
	hero.velocity = move * WALK_SPEED
	hero.move_and_slide()
	# Fairy circles the hero and refills health and mana
	var t := Time.get_ticks_msec() / 1000.0
	fairy.position = hero.position + Vector3(cos(t) * 1.5, 1.6 + sin(t * 3) * 0.2, sin(t) * 1.5)
	health = minf(100, health + 3 * delta); mana = minf(100, mana + 5 * delta)
	# Bugs crawl toward the hero
	for b in bugs:
		var dir: Vector3 = (hero.position - b.position); dir.y = 0
		if dir.length() > 1.2: b.position += dir.normalized() * 2.0 * delta
		else: health = maxf(0, health - 10 * delta)
	if health <= 0: health = 100; hero.position = Vector3(0, 1, 0)  # gentle respawn
	hp_bar.value = health; mp_bar.value = mana

# Tavern tables (chess, checkers, and dominoes) live in scripts/tavern/.
# Theatron's tavern props can call TavernTable to seat characters and start a game.
# Example: var table := TavernTable.new(); table.setup_chess(seats, 0)
