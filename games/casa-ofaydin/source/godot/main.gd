extends Node3D
# Casa O'Faydin: Port Paradise. Day/night on Blake's clock (1 game hour = 20 real
# minutes), hero with health + mana, twin-stick move/look, fairy refill, bugs,
# low-poly people, Morrowind-style gear, the Harbor Counting House bank,
# elemental bolts / wards / levitation, and enemy casters.
# Data: res://data/world_clock.json, bank.json, clothing.json, spells.json.
# Arrival forms (logic only; no UI yet): see res://scripts/arrival_forms.gd
const Art = preload("res://art/bootstrap.gd")
const Hero = preload("res://art/hero_model.gd")
const LowPoly = preload("res://art/lowpoly_character.gd")
const VirtualStick = preload("res://scripts/virtual_stick.gd")
const WorldClock = preload("res://scripts/world_clock.gd")
const Bank = preload("res://scripts/bank.gd")
const Wardrobe = preload("res://scripts/wardrobe.gd")
const Magic = preload("res://scripts/magic.gd")
const GameUI = preload("res://scripts/game_ui.gd")
const SAVE_PATH := "user://casa_save.json"
const WALK_SPEED := 6.0
const YAW_SPEED := 2.4  # radians/sec at full look stick
const PITCH_SPEED := 1.8
const PITCH_MIN := deg_to_rad(-60.0)
const PITCH_MAX := deg_to_rad(60.0)
const LOOK_DRAG := 0.0045  # radians per pixel for empty-screen / mouse look
const BOUNDS := 36.0
const BANKER_POS := Vector3(-3.6, 0, -7.0)
const WAKE_POS := Vector3(-6.6, 1, -6.4)
var time_of_day := 0.3     # 0..1 (0.5 = noon); mirrors clock.hour / 24
var day_count := 1
var health := 100.0
var mana := 100.0
var first_person := false
var sun: DirectionalLight3D
var env: Environment
var hero: CharacterBody3D
var cam: Camera3D
var mirror_cam: Camera3D
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
var clock := WorldClock.new()
var bank := Bank.new()
var wardrobe := Wardrobe.new()
var magic: Node3D
var gui: Node
var knock := Vector3.ZERO
var walk_phase := 0.0
var walk_amt := 0.0
var _last_tod := -1.0
var _save_t := 0.0
# Arms: "staff" (spells), "sword", or "crossbow" (bone arrows). One Attack button.
const WEAPONS := ["staff", "sword", "crossbow"]
var weapon := "staff"
var arrows := 24
var action := ""
var action_t := 0.0
var action_len := 0.5
var _reload := 0.0

func _ready() -> void:
	randomize()
	clock.load_config()
	bank.load_config()
	wardrobe.load_config()
	if OS.get_environment("ART_SHOT") == "":
		load_game()
	time_of_day = clock.time_of_day()
	day_count = clock.day
	_build_world()
	_build_hero()
	_build_fairy()
	for i in 5: _spawn_bug()
	_build_hud()
	Art.apply(self)
	magic = Magic.new()
	magic.name = "Magic"
	add_child(magic)
	magic.setup(self)
	gui = GameUI.new()
	gui.name = "GameUI"
	add_child(gui)
	gui.setup(self, hp_bar.get_parent())
	_apply_camera()

func hero_gear() -> Dictionary:
	return wardrobe.equipped

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
	var cs := CollisionShape3D.new(); cs.shape = CapsuleShape3D.new(); hero.add_child(cs)
	cam = Camera3D.new(); hero.add_child(cam); cam.current = true
	# Real model comes from Art.apply -> art/hero_model.gd
	Hero.build(hero, wardrobe.equipped, weapon)

func rebuild_hero() -> void:
	Hero.build(hero, wardrobe.equipped, weapon)
	_apply_camera()
	save_game()

func _apply_camera() -> void:
	var pitch := clampf(look_pitch, PITCH_MIN, PITCH_MAX)
	var body := hero.get_node_or_null("Body")
	if body:
		body.visible = not first_person or panel_open()
	if first_person:
		cam.position = Vector3(0, 0.66, -0.12)
		cam.rotation = Vector3(pitch, 0, 0)
	else:
		var dist := 5.0
		var pivot_h := 0.85
		cam.position = Vector3(0.0, pivot_h - sin(pitch) * dist, cos(pitch) * dist)
		cam.rotation = Vector3(pitch, 0, 0)
	_tilt_head(pitch)

func _camera_collide() -> void:
	# Pull the third-person camera in front of walls so buildings never block the view.
	if first_person:
		return
	var from := hero.global_position + Vector3(0, 0.85, 0)
	var to := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [hero.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var p: Vector3 = hit["position"]
		cam.global_position = p + (from - p).normalized() * 0.3

func toggle_camera() -> void:
	first_person = not first_person
	_apply_camera()

func _tilt_head(pitch: float) -> void:
	var head := hero.get_node_or_null("Body/Head")
	if head:
		# Body is turned to face -Z, so a look-down pitch tips the face down.
		head.rotation.x = clampf(-pitch * 0.35, deg_to_rad(-22.0), deg_to_rad(22.0))

func set_mirror(on: bool) -> void:
	if on:
		if mirror_cam == null:
			mirror_cam = Camera3D.new()
			mirror_cam.name = "MirrorCam"
			add_child(mirror_cam)
		var fwd := -hero.global_transform.basis.z
		fwd.y = 0
		fwd = fwd.normalized()
		var center := hero.global_position + Vector3(0, -0.1, 0)
		mirror_cam.global_position = center + fwd * 5.8 + Vector3(0, 0.4, 0)
		mirror_cam.look_at(center, Vector3.UP)
		# Shift the picture up so the hero sits above the gear panel.
		mirror_cam.projection = Camera3D.PROJECTION_FRUSTUM
		mirror_cam.near = 0.05
		mirror_cam.size = 2.0 * 0.05 * tan(deg_to_rad(30.0))
		mirror_cam.frustum_offset = Vector2(0, -0.33 * mirror_cam.size)
		mirror_cam.current = true
		var body := hero.get_node_or_null("Body")
		if body:
			body.visible = true
	else:
		cam.current = true
		_apply_camera()

func panel_open() -> bool:
	return gui != null and gui.is_open()

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
	# Lux (Latin: light) pops nearby bugs into light. Costs 20 mana. The town pays a few coins per bug.
	if mana < 20: return
	mana -= 20
	var popped := 0
	for b in bugs.duplicate():
		if b.position.distance_to(hero.position) < 8:
			bugs.erase(b); b.queue_free(); _spawn_bug(); popped += 1
	if popped > 0:
		var each := int(bank.cfg.get("coins_per_bug", 3))
		award_coins(popped * each, "popped %s bug%s" % [TavernSafe.number_text(popped), "" if popped == 1 else "s"])
		toast("Pop! +%s coins" % TavernSafe.number_text(popped * each))

# ---- hooks used by GameUI and Magic -------------------------------------------

func toast(text: String) -> void:
	if gui:
		gui.toast(text)

func award_coins(n: int, why: String) -> void:
	bank.earn(n, why)
	save_game()

func is_night() -> bool:
	return clock.hour < 5.5 or clock.hour >= 20.0

func near_banker() -> bool:
	var d := Vector2(hero.position.x - BANKER_POS.x, hero.position.z - BANKER_POS.z).length()
	return d < 3.2 and hero.position.y < 2.5

func open_gear() -> void:
	gui.open_gear()

func next_element() -> void:
	magic.next_element()
	var e: Dictionary = magic.element()
	toast("%s: Bolt fires %s. Ward blocks %s. %s beats %s." % [e["name"], e["name"], e["name"], e["name"], magic.el(str(e["beats"]))["name"]])

func cast_bolt() -> void:
	# The one Attack button: Bolt with the staff, Slash with the sword, Shoot with the crossbow.
	match weapon:
		"sword":
			if action == "slash":
				return
			_start_action("slash", float(magic.weapon_cfg("sword").get("seconds", 0.55)))
			magic.sword_slash()
		"crossbow":
			if _reload > 0.0:
				return
			if arrows <= 0:
				toast("Out of bone arrows. Sleep to fill your quiver, or buy more at the bank.")
				return
			arrows -= 1
			_reload = float(magic.weapon_cfg("crossbow").get("reload_seconds", 0.9))
			_start_action("shoot", 0.35)
			magic.shoot_arrow()
		_:
			var msg: String = magic.cast_bolt()
			if msg == "":
				_start_action("cast", 0.6)
			toast(msg)

func _start_action(a: String, seconds: float) -> void:
	action = a
	action_t = 0.0
	action_len = maxf(0.1, seconds)

func next_weapon() -> void:
	weapon = WEAPONS[(WEAPONS.find(weapon) + 1) % WEAPONS.size()]
	action = ""
	rebuild_hero()
	match weapon:
		"sword": toast("Sword drawn. Press Slash when a foe is close.")
		"crossbow": toast("Crossbow ready with %s bone arrows. Press Shoot." % TavernSafe.number_text(arrows))
		_: toast("Staff ready. Pick an element and press Bolt.")

func cast_ward() -> void:
	toast(magic.cast_ward())

func toggle_float() -> void:
	toast(magic.toggle_float())

func do_wait() -> void:
	var s: int = clock.wait()
	_after_skip(s, "You waited an hour.")

func do_sleep() -> void:
	var s: int = clock.sleep()
	health = 100.0
	mana = 100.0
	arrows = maxi(arrows, int(magic.weapon_cfg("crossbow").get("arrows_start", 24)))
	magic.clear_enemies()
	magic.spawn_timer = 20.0
	_after_skip(s, "You slept until morning. Day %s of %s." % [TavernSafe.number_text(clock.day), clock.season_name()])

func _after_skip(seasons: int, msg: String) -> void:
	var extra := ""
	for i in seasons:
		extra = bank.on_season(clock.season_name())
	if seasons > 0 and extra == "":
		extra = "%s is here." % clock.season_name()
	time_of_day = clock.time_of_day()
	_last_tod = time_of_day
	toast(msg + ("  " + extra if extra != "" else ""))
	save_game()

func take_hit(dmg: float, push: Vector3, c: Color) -> void:
	health = maxf(0.0, health - dmg)
	push.y = 0
	knock += push
	if gui:
		gui.hit_flash(c)
	if health <= 0.0:
		faint()

func faint() -> void:
	var lost := int(magic.cfg.get("faint", {}).get("coins_lost", 5))
	var place := str(magic.cfg.get("faint", {}).get("wake_place", "The Gilded Anchor"))
	var paid := bank.spend(lost, "bed at %s" % place)
	health = 100.0
	mana = 100.0
	knock = Vector3.ZERO
	magic.stop_float()
	magic.clear_enemies()
	magic.spawn_timer = 20.0
	hero.position = WAKE_POS
	var cost_txt := "The innkeeper kept %s coins for the bed." % TavernSafe.number_text(paid) if paid > 0 else "The innkeeper let you rest for free."
	toast("You fainted and woke up at %s. %s Rest up, hero!" % [place, cost_txt])
	save_game()

# ---- save / load ---------------------------------------------------------------

func save_game() -> void:
	if OS.get_environment("ART_SHOT") != "":
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"version": 1, "bank": bank.to_dict(), "clock": clock.to_dict(), "gear": wardrobe.to_dict(), "weapon": weapon, "arrows": arrows}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY or int(d.get("version", 0)) != 1:
		return
	bank.from_dict(d.get("bank", {}))
	clock.from_dict(d.get("clock", {}))
	wardrobe.from_dict(d.get("gear", {}))
	weapon = str(d.get("weapon", "staff"))
	if not weapon in WEAPONS:
		weapon = "staff"
	arrows = clampi(int(d.get("arrows", 24)), 0, 40)

# ---- input ---------------------------------------------------------------------

func _unhandled_input(e: InputEvent) -> void:
	if panel_open():
		return
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
	# World clock (Blake: 1 game hour = 20 real minutes). Art shots may set time_of_day directly.
	if _last_tod >= 0.0 and absf(time_of_day - _last_tod) > 0.0001:
		clock.hour = clampf(time_of_day, 0.0, 0.9999) * 24.0
	var seasons := clock.tick(delta)
	if seasons > 0:
		_after_skip(seasons, "")
	time_of_day = clock.time_of_day()
	_last_tod = time_of_day
	day_count = clock.day
	var daylight := clampf(sin(time_of_day * TAU - PI / 2) * 0.5 + 0.5, 0.0, 1.0)
	Art.update_sky(self, time_of_day, daylight)
	clock_label.text = GameUI.safe("Day %s  %s  %s" % [TavernSafe.number_text(clock.day), clock.season_name(), clock.clock_text()])
	_save_t += delta
	if _save_t > 30.0:
		_save_t = 0.0
		save_game()
	if panel_open():
		hero.velocity = Vector3.ZERO
		LowPoly.animate(hero.get_node_or_null("Body"), walk_phase, 0.0, Time.get_ticks_msec() / 1000.0)
		return
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
	if magic.levitating:
		if Input.is_physical_key_pressed(KEY_SPACE): magic.lift = 1.0
		elif Input.is_physical_key_pressed(KEY_C): magic.lift = -1.0
	hero.rotation.y = look_yaw
	_apply_camera()
	_camera_collide()
	# Camera-relative walk / strafe. Up on the stick is forward. Analog speed.
	var v: Vector2 = (left_stick.value + _keyboard_move()).limit_length(1.0)
	var facing := Basis(Vector3.UP, look_yaw)
	var forward := -facing.z
	var right := facing.x
	var move := right * v.x + forward * (-v.y)
	hero.velocity = move * WALK_SPEED + knock
	hero.velocity.y = magic.vertical_speed(hero.position.y)
	knock = knock.move_toward(Vector3.ZERO, 9.0 * delta)
	hero.move_and_slide()
	# Town bounds (also while flying): stay on the map, never sink.
	var top := 1.0 + float(magic.cfg.get("levitate", {}).get("max_height", 9))
	hero.position.x = clampf(hero.position.x, -BOUNDS, BOUNDS)
	hero.position.z = clampf(hero.position.z, -BOUNDS, BOUNDS)
	hero.position.y = clampf(hero.position.y, 1.0, top)
	# Walk animation: legs only cycle when on the ground; a gentle hover bob in the air.
	var t := Time.get_ticks_msec() / 1000.0
	var speed := Vector2(move.x, move.z).length()
	var airborne: bool = magic.levitating or hero.position.y > 1.05
	walk_amt = lerpf(walk_amt, 0.0 if airborne else speed, clampf(delta * 8.0, 0.0, 1.0))
	walk_phase += speed * WALK_SPEED * delta * 1.35
	var body := hero.get_node_or_null("Body")
	_reload = maxf(0.0, _reload - delta)
	if action != "":
		action_t += delta / action_len
		if action_t >= 1.0:
			action = ""
	if body:
		body.set_meta("action", action if action != "" else ("aim" if weapon == "crossbow" and walk_amt < 0.2 else ""))
		body.set_meta("action_t", action_t)
		LowPoly.animate(body, walk_phase, walk_amt, t)
		body.position.y = -1.0 + (sin(t * 2.4) * 0.08 if magic.levitating else 0.0)
		if airborne:
			var ll := body.get_node_or_null("LegL/ShinL")
			var lr := body.get_node_or_null("LegR/ShinR")
			if ll: ll.rotation.x = 0.35
			if lr: lr.rotation.x = 0.2
	_tilt_head(look_pitch)
	# Fairy circles the hero and refills health and mana
	fairy.position = hero.position + Vector3(cos(t) * 1.5, 0.6 + sin(t * 3) * 0.2, sin(t) * 1.5)
	health = minf(100, health + 3 * delta)
	if not magic.levitating:
		mana = minf(100, mana + 5 * delta)
	# Bugs crawl toward the hero
	for b in bugs:
		var dir: Vector3 = (hero.position - b.position); dir.y = 0
		if dir.length() > 1.2: b.position += dir.normalized() * 2.0 * delta
		elif hero.position.y < 2.0: health = maxf(0, health - 10 * delta)
	if health <= 0: faint()
	hp_bar.value = health; mp_bar.value = mana

# Tavern tables (chess, checkers, and dominoes) live in scripts/tavern/.
# Theatron's tavern props can call TavernTable to seat characters and start a game.
# Example: var table := TavernTable.new(); table.setup_chess(seats, 0)
