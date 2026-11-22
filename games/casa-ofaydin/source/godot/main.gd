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
const Dice = preload("res://scripts/dice.gd")
const HeroClass = preload("res://scripts/hero_class.gd")
const Roster = preload("res://scripts/roster.gd")
const Realm = preload("res://scripts/realm.gd")
const RealmUI = preload("res://scripts/realm_ui.gd")
const Overworld = preload("res://art/overworld.gd")
const Quality = preload("res://scripts/quality.gd")
const Batcher = preload("res://art/batcher.gd")
const SAVE_PATH := "user://casa_save.json"
const WALK_SPEED := 6.0
const YAW_SPEED := 2.4  # radians/sec at full look stick
const PITCH_SPEED := 1.8
const PITCH_MIN := deg_to_rad(-60.0)
const PITCH_MAX := deg_to_rad(60.0)
const LOOK_DRAG := 0.0045  # radians per pixel for empty-screen / mouse look
const BOUNDS := 36.0
const WORLD := 122.0   # the open land outside the city
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
# Fun layer: dice, heroes (roster), the shared realm, the open land.
var dice := Dice.new()
var roster := Roster.new()
var realm := Realm.new()
var rui: Node
var overworld: Node3D
var buddy_node: Node3D
var buddy_body: Node3D
var buddy_phase := 0.0
var buddy_cd := 0.0
var sneak_left := 0.0
var block_left := 0.0
var charge_left := 0.0
var charge_dir := Vector3.ZERO
var power_btn: Button
var realm_btn: Button
var hero_label: Label
var _shield: MeshInstance3D
var _need_creator := false
var quality: Node

func _ready() -> void:
	randomize()
	clock.load_config()
	bank.load_config()
	wardrobe.load_config()
	if OS.get_environment("ART_SHOT") == "":
		load_game()
	if realm.factions.is_empty():
		realm.setup(dice.new_seed())
		realm.last_day = clock.day
	dice.set_seed(realm.seed_value + clock.day * 31)
	if roster.heroes.is_empty():
		if OS.get_environment("ART_SHOT") != "" or OS.get_environment("FUN_DEMO") != "":
			var st: Dictionary = HeroClass.roll_stats(dice, "mage")
			roster.add_hero("Bram the Bright", "mage", st["stats"], bank.purse)
		else:
			_need_creator = true
			roster.add_hero("Traveler", "mage", {"might": 8, "sneak": 8, "magic": 12, "heart": 10}, bank.purse)
	_load_active(false)
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
	_build_fun_hud(hp_bar.get_parent())
	overworld = Overworld.new()
	overworld.name = "Overworld"
	add_child(overworld)
	overworld.setup(self, realm.seed_value)
	overworld.draw_villages(realm.villages)
	rui = RealmUI.new()
	rui.name = "RealmUI"
	add_child(rui)
	rui.setup(self, gui)
	rebuild_buddy()
	quality = Quality.new()
	quality.name = "Quality"
	add_child(quality)
	quality.setup(self)
	if not quality.before:
		_merge_static()
	quality.apply()
	_apply_camera()
	if _need_creator:
		rui.open_creator.call_deferred()
		roster.heroes.clear()

func hero_gear() -> Dictionary:
	return wardrobe.equipped

func hero_look(h: Dictionary = {}) -> Dictionary:
	if h.is_empty():
		h = roster.cur()
	if h.is_empty():
		return {}
	var c: Dictionary = HeroClass.CLASSES.get(str(h.get("cls", "mage")), HeroClass.CLASSES["mage"])
	var look: Dictionary = (c["look"] as Dictionary).duplicate()
	look["tints"] = c["tints"]
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(h.get("name", "")))
	look["skin"] = LowPoly.SKIN[r.randi() % LowPoly.SKIN.size()]
	look["hair_color"] = LowPoly.HAIR_COLORS[r.randi() % LowPoly.HAIR_COLORS.size()]
	return look

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
	var bs := BoxShape3D.new(); bs.size = Vector3(300, 0.2, 300); cs.shape = bs
	cs.position.y = -0.1; body.add_child(cs); add_child(body)

func _build_hero() -> void:
	hero = CharacterBody3D.new(); hero.position = Vector3(0, 1, 0); add_child(hero)
	var cs := CollisionShape3D.new(); cs.shape = CapsuleShape3D.new(); hero.add_child(cs)
	cam = Camera3D.new(); hero.add_child(cam); cam.current = true
	# Real model comes from Art.apply -> art/hero_model.gd
	Hero.build(hero, wardrobe.equipped, weapon, hero_look())

func rebuild_hero() -> void:
	Hero.build(hero, wardrobe.equipped, weapon, hero_look())
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
	return (gui != null and gui.is_open()) or (rui != null and rui.is_open())

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
	var cost := 10.0 if realm.has_blessing("light") else 20.0
	if mana < cost: return
	mana -= cost
	if overworld and overworld.scare(hero.global_position, 12.0) > 0:
		toast("Your Lux glow shines bright! The night folk run off giggling.")
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
	if block_left > 0.0:
		dmg *= 0.15
		push *= 0.2
		toast("Blocked with your shield!")
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
	_stash_active()
	f.store_string(JSON.stringify({"version": 2, "bank": bank.to_dict(), "clock": clock.to_dict(), "gear": wardrobe.to_dict(), "weapon": weapon, "arrows": arrows,
		"roster": roster.to_dict(), "realm": realm.to_dict(), "pos": [hero.position.x, hero.position.z] if hero else [0, 0]}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY or not int(d.get("version", 0)) in [1, 2]:
		return
	roster.from_dict(d.get("roster", {}))
	if d.has("realm"):
		realm.from_dict(d["realm"])
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
	var spd := WALK_SPEED * (0.8 if sneak_left > 0.0 else 1.0)
	hero.velocity = move * spd + knock
	if charge_left > 0.0:
		hero.velocity = charge_dir * 18.0
	hero.velocity.y = magic.vertical_speed(hero.position.y)
	knock = knock.move_toward(Vector3.ZERO, 9.0 * delta)
	hero.move_and_slide()
	# Town bounds (also while flying): stay on the map, never sink.
	var top := 1.0 + float(magic.cfg.get("levitate", {}).get("max_height", 9))
	_clamp_world(hero)
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
	health = minf(100, health + (6 if realm.has_blessing("heal") else 3) * delta)
	_fun_tick(delta, t)
	if not magic.levitating:
		mana = minf(100, mana + 5 * delta)
	# Bugs crawl toward the hero
	for b in bugs:
		var dir: Vector3 = (hero.position - b.position); dir.y = 0
		if dir.length() > 26.0 and (absf(hero.position.x) > 44.0 or hero.position.z > 36.0): continue  # town bugs stay in town
		if dir.length() > 1.2: b.position += dir.normalized() * 2.0 * delta
		elif hero.position.y < 2.0: health = maxf(0, health - 10 * delta)
	if health <= 0: faint()
	hp_bar.value = health; mp_bar.value = mana

# Tavern tables (chess, checkers, and dominoes) live in scripts/tavern/.
# Theatron's tavern props can call TavernTable to seat characters and start a game.
# Example: var table := TavernTable.new(); table.setup_chess(seats, 0)

# ==== Fun layer: heroes, dice, the open land, villages, faith, allies ==========

func _build_fun_hud(ui: CanvasLayer) -> void:
	realm_btn = gui._btn(ui, "Realm", Vector2(14, 516), Vector2(132, 84), func(): rui.open_book(), 28)
	power_btn = gui._btn(ui, "Power", Vector2(14, 610), Vector2(132, 100), do_power, 28)
	hero_label = Label.new()
	hero_label.position = Vector2(160, 520)
	hero_label.size = Vector2(400, 40)
	hero_label.add_theme_font_size_override("font_size", 24)
	hero_label.add_theme_color_override("font_color", Color(0.94, 0.85, 0.58))
	hero_label.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04))
	hero_label.add_theme_constant_override("outline_size", 6)
	hero_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hero_label)


func _clamp_world(n: Node3D) -> void:
	var p := n.position
	p.x = clampf(p.x, -WORLD, WORLD)
	p.z = clampf(p.z, -WORLD, WORLD)
	# The harbor is water: inside the city keep the old dock limits.
	if absf(p.x) < 40.0:
		p.z = maxf(p.z, -BOUNDS)
	elif absf(p.x) < 58.0:
		p.z = maxf(p.z, -13.0)
	n.position.x = p.x
	n.position.z = p.z


func cls() -> String:
	return str(roster.cur().get("cls", "mage"))


## Quick d20 for every hit: miss (0), hit (1), or a natural 20 crit (2).
func hit_roll() -> float:
	var stat: String = str({"mage": "magic", "thief": "sneak", "warrior": "might"}.get(cls(), "might"))
	var c: Dictionary = dice.check(roster.bonus(stat) + realm.luck(), 7)
	if rui:
		rui.show_chip(c["roll"], c["win"], c["crit"])
	if not c["win"]:
		return 0.0
	return 2.0 if c["crit"] else 1.0 + float(roster.cur().get("level", 1)) * 0.02


func add_xp(n: int) -> void:
	var ups := roster.add_xp(roster.active, n)
	if ups > 0:
		toast("Level up! %s is now level %s!" % [roster.cur()["name"], TavernSafe.number_text(int(roster.cur()["level"]))])
		_update_hero_label()
	if roster.buddy >= 0:
		roster.add_xp(roster.buddy, int(n / 2))


func foe_defeated(_e: Dictionary) -> void:
	add_xp(10)
	var extra := 0
	if realm.has_perk("coins"): extra += 2
	if realm.has_blessing("coin"): extra += 2
	if extra > 0:
		bank.earn(extra, "friends' gift")


func _update_hero_label() -> void:
	var h: Dictionary = roster.cur()
	if hero_label == null or h.is_empty():
		return
	hero_label.text = GameUI.safe("%s  Lv %s %s" % [h["name"], TavernSafe.number_text(int(h["level"])), HeroClass.CLASSES[h["cls"]]["name"]])
	var c: Dictionary = HeroClass.CLASSES[h["cls"]]
	power_btn.text = c["move"]
	gui._style(power_btn, 28, c["color"])


# ---- roster: make, switch, party ----------------------------------------------

func _stash_active() -> void:
	if roster.heroes.is_empty() or hero == null:
		return
	var h: Dictionary = roster.cur()
	h["purse"] = bank.purse
	h["gear"] = wardrobe.equipped.duplicate()
	h["weapon"] = weapon
	h["arrows"] = arrows
	h["x"] = hero.position.x
	h["z"] = hero.position.z


func _load_active(rebuild := true) -> void:
	var h: Dictionary = roster.cur()
	if h.is_empty():
		return
	bank.purse = int(h["purse"])
	wardrobe.equipped = (h["gear"] as Dictionary).duplicate()
	weapon = str(h["weapon"])
	if not weapon in WEAPONS:
		weapon = "staff"
	arrows = int(h["arrows"])
	if rebuild:
		rebuild_hero()
	_update_hero_label()


func create_hero(nm: String, c: String, stats: Dictionary, at_village: int) -> void:
	var first := roster.heroes.is_empty()
	var spawn := Vector3(0, 1, 0)
	if not first:
		_stash_active()
		spawn = hero.position + Vector3(1.8, 0, 1.2)
		if at_village >= 0 and at_village < realm.villages.size():
			var v: Dictionary = realm.villages[at_village]
			spawn = Vector3(float(v["x"]) + 2.0, 1, float(v["z"]) + 3.0)
	var old := roster.active
	var i := roster.add_hero(nm, c, stats, int(bank.cfg.get("starting_purse", 50)) if first else 25)
	roster.active = i
	if not first:
		# The veteran stays in the world and joins your party to help.
		roster.buddy = old
		if at_village >= 0:
			roster.heroes[old]["x"] = spawn.x + 2.0
			roster.heroes[old]["z"] = spawn.z + 1.0
	hero.position = spawn
	_load_active()
	rebuild_buddy()
	var info: Dictionary = HeroClass.CLASSES[c]
	var msg := "Welcome, %s the %s! Tap %s to use your signature move." % [nm, info["name"], info["move"]]
	if not first:
		msg += " %s is in your party to help." % roster.heroes[old]["name"]
	toast(msg)
	save_game()


func switch_to(i: int) -> void:
	if i == roster.active or i < 0 or i >= roster.heroes.size():
		return
	_stash_active()
	var old := roster.active
	var old_pos := hero.position
	roster.active = i
	var h: Dictionary = roster.heroes[i]
	if roster.buddy == i:
		roster.buddy = old   # swap places in the party
		hero.position = buddy_node.position + Vector3(0, 1, 0) if buddy_node else old_pos
		roster.heroes[old]["x"] = old_pos.x
		roster.heroes[old]["z"] = old_pos.z
	else:
		hero.position = Vector3(float(h["x"]), 1, float(h["z"]))
	_load_active()
	rebuild_buddy()
	toast("Now playing %s." % h["name"])
	save_game()


func set_buddy(i: int) -> void:
	_stash_active()
	roster.buddy = i
	if i >= 0:
		roster.heroes[i]["x"] = hero.position.x + 1.5
		roster.heroes[i]["z"] = hero.position.z + 1.5
	rebuild_buddy()
	if i >= 0:
		toast("%s joined your party! They follow you and help in fights." % roster.heroes[i]["name"])
	save_game()


func rebuild_buddy() -> void:
	if buddy_node:
		buddy_node.queue_free()
		buddy_node = null
		buddy_body = null
	var b: Dictionary = roster.pal()
	if b.is_empty():
		return
	buddy_node = Node3D.new()
	buddy_node.name = "Buddy"
	add_child(buddy_node)
	buddy_node.position = Vector3(float(b["x"]), 0, float(b["z"]))
	var p := hero_look(b)
	p["gear"] = b["gear"]
	p["weapon"] = b["weapon"]
	p["build"] = p.get("build", "average")
	buddy_body = LowPoly.build(buddy_node, p)
	var lb := Label3D.new()
	lb.text = GameUI.safe("%s  Lv %s" % [b["name"], TavernSafe.number_text(int(b["level"]))])
	lb.font_size = 32; lb.pixel_size = 0.004; lb.outline_size = 6
	lb.modulate = Color(0.75, 1.0, 0.7)
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.position = Vector3(0, 2.3, 0)
	buddy_node.add_child(lb)


func _buddy_tick(delta: float, t: float) -> void:
	if buddy_node == null:
		return
	var b: Dictionary = roster.pal()
	var target := buddy_node.position
	var foe = magic._nearest_enemy(14.0)
	var walk := 0.0
	if foe != null:
		var fp: Vector3 = foe["node"].global_position
		var to := fp - buddy_node.position
		to.y = 0
		if to.length() > 2.6:
			target = fp
		buddy_node.rotation.y = atan2(to.x, to.z)
		buddy_cd -= delta
		if buddy_cd <= 0.0 and to.length() < 9.0:
			buddy_cd = 1.6
			var dmg := 8.0 + float(b["level"]) * 0.4
			magic._puff(fp + Vector3(0, 1.1, 0), Color(0.7, 1.0, 0.6), 1.0)
			magic.hurt_plain(foe, dmg, to.normalized())
	elif roster.follow:
		var back := hero.global_transform.basis.z * 0.4 + hero.global_transform.basis.x * 1.9
		target = Vector3(hero.position.x, 0, hero.position.z) + Vector3(back.x, 0, back.z)
	var d := target - buddy_node.position
	d.y = 0
	if d.length() > 0.6:
		var spd := minf(WALK_SPEED * (1.4 if d.length() > 8.0 else 1.0), d.length() / maxf(delta, 0.001))
		buddy_node.position += d.normalized() * spd * delta
		if foe == null:
			buddy_node.rotation.y = lerp_angle(buddy_node.rotation.y, atan2(d.x, d.z), clampf(delta * 8.0, 0, 1))
		walk = clampf(d.length() / 2.0, 0.0, 1.0)
		buddy_phase += spd * delta * 1.35
	if d.length() > 40.0:
		buddy_node.position = Vector3(hero.position.x + 1.5, 0, hero.position.z + 1.5)
	_clamp_world(buddy_node)
	LowPoly.animate(buddy_body, buddy_phase, walk, t)


# ---- signature moves ----------------------------------------------------------

func do_power() -> void:
	match cls():
		"mage":
			var cost := 30.0
			if mana < cost:
				toast("Storm needs %s mana. The fairy will refill you." % TavernSafe.number_text(int(cost)))
				return
			mana -= cost
			_start_action("cast", 0.7)
			var n := 0
			for e in magic.enemies.duplicate():
				if e["node"].global_position.distance_to(hero.global_position) < 16.0:
					n += 1
					magic._spark(e["node"].global_position + Vector3(0, 1.2, 0), Color(0.7, 0.8, 1.0))
					magic._spawn_bolt(magic.fingertips(), (e["node"].global_position + Vector3(0, 1.1, 0) - magic.fingertips()).normalized() * 30.0, "lightning", false, 0.0)
					magic.hurt_plain(e, 18.0 + roster.bonus("magic") * 2.0, Vector3.ZERO)
			if overworld:
				n += overworld.scare(hero.global_position, 16.0)
			magic._spark(magic.fingertips(), Color(0.7, 0.8, 1.0))
			toast("STORM! Lightning jumps from your fingertips%s." % (" to %s foes" % TavernSafe.number_text(n) if n > 0 else ""))
		"thief":
			var tgt = _tag_target()
			if sneak_left > 0.0 and tgt != null:
				_do_tag(tgt)
			else:
				sneak_left = 10.0
				_set_ghost(true)
				toast("Sneaking... foes lose track of you. Walk up to someone and tap Tag!")
		"warrior":
			if charge_left > 0.0:
				return
			charge_dir = -hero.global_transform.basis.z
			charge_dir.y = 0
			charge_dir = charge_dir.normalized()
			charge_left = 0.35
			block_left = 1.5
			_show_shield(true)
			_start_action("slash", 0.5)
			toast("CHARGE!")


func cast_block() -> void:
	block_left = 2.5
	_show_shield(true)
	toast("Shield up! Hits barely touch you.")


func _show_shield(on: bool) -> void:
	if on and _shield == null:
		_shield = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.34; cm.bottom_radius = 0.34; cm.height = 0.06; cm.radial_segments = 10; cm.rings = 1
		_shield.mesh = cm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.7, 0.32, 0.22)
		m.metallic = 0.4
		_shield.material_override = m
		var boss := MeshInstance3D.new()
		var bm := SphereMesh.new(); bm.radius = 0.09; bm.height = 0.12; bm.radial_segments = 6; bm.rings = 3
		boss.mesh = bm
		var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.85, 0.7, 0.35); gm.metallic = 0.6
		boss.material_override = gm
		boss.position = Vector3(0, 0.05, 0)
		_shield.add_child(boss)
	if _shield == null:
		return
	if on:
		if _shield.get_parent():
			_shield.get_parent().remove_child(_shield)
		hero.add_child(_shield)
		_shield.position = Vector3(-0.32, 0.15, -0.45)
		_shield.rotation = Vector3(PI / 2, 0, 0)
		_shield.visible = true
	else:
		_shield.visible = false


func _set_ghost(on: bool) -> void:
	# Sneak look: see-through and a little crouched (works on the web renderer).
	var body := hero.get_node_or_null("Body")
	if body == null:
		return
	body.scale = Vector3(1, 0.9, 1) if on else Vector3.ONE
	for c in body.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if on:
			var base: Material = mi.material_override if mi.material_override else (mi.mesh.surface_get_material(0) if mi.mesh and mi.mesh.get_surface_count() > 0 else null)
			if base is StandardMaterial3D:
				mi.set_meta("pre_ghost", mi.material_override)
				var g := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				g.albedo_color.a = 0.4
				mi.material_override = g
		elif mi.has_meta("pre_ghost"):
			mi.material_override = mi.get_meta("pre_ghost")
			mi.remove_meta("pre_ghost")


func _tag_target():
	var best = null
	var bd := 3.2
	for n in get_tree().get_nodes_in_group("tag_target"):
		var d: float = (n as Node3D).global_position.distance_to(hero.global_position)
		if d < bd and not n.has_meta("tagged"):
			bd = d
			best = n
	return best


func _do_tag(n: Node3D) -> void:
	var c: Dictionary = dice.check(roster.bonus("sneak") + realm.luck(), 11, "Tag! (d20 + Sneak)")
	n.set_meta("tagged", true)
	if c["win"]:
		var coins := 3 + dice.die(6)
		bank.earn(coins, "a game of tag")
		add_xp(5)
		rui.show_roll(c, "You tagged them! They laugh and toss you %s shiny coins." % TavernSafe.number_text(coins))
	else:
		rui.show_roll(c, "They spotted you first and laughed. Tag someone else!")
	sneak_left = 0.0
	_set_ghost(false)


# ---- the open land: night folk and dice events --------------------------------

func creature_scared(kind: String) -> void:
	var coins := 4
	bank.earn(coins, "scared off a %s" % kind)
	add_xp(5)
	toast("The %s ran home! +%s coins" % [kind, TavernSafe.number_text(coins)])


func creature_meet(c: Dictionary) -> void:
	var kind: String = c["kind"]
	var r: Dictionary = dice.check(roster.bonus("heart") + realm.luck(), 10, "A %s wants to play! (d20 + Heart)" % kind)
	if r["win"]:
		rui.show_roll(r, "You stood tall and laughed. The %s bowed, dropped a coin, and ran off!" % kind)
		bank.earn(2, "a bow from a %s" % kind)
		c["flee"] = 3.0
	else:
		var msg := "The vampire told a very bad joke and flew off. Lux scares them away!" if kind == "vampire" else "The werewolf licked your face and bounded off. Lux scares them away!"
		mana = maxf(0.0, mana - 15.0)
		rui.show_roll(r, msg)
		c["flee"] = 3.0


func wild_event(where: String) -> void:
	var table := [
		["chest", "You found an old chest in the %s!" % where],
		["trader", "A traveling trader waves at you."],
		["lamb", "A lost lamb bleats nearby."],
		["fairy", "A wild fairy circle glows in the grass."],
		["storm", "Thunder rumbles over the %s." % where],
	]
	var e: Array = dice.pick(table)
	match e[0]:
		"chest":
			var c: Dictionary = dice.check(roster.bonus("might") + realm.luck(), 9, e[1] + " (d20 + Might to open)")
			var coins := 6 + dice.die(10) if c["win"] else 0
			if coins > 0:
				bank.earn(coins, "an old chest")
			rui.show_roll(c, "It creaks open: %s coins!" % TavernSafe.number_text(coins) if c["win"] else "Stuck tight. Maybe next time!")
		"trader":
			var c: Dictionary = dice.check(roster.bonus("sneak") + realm.luck(), 11, e[1] + " (haggle: d20 + Sneak)")
			if c["win"]:
				arrows = mini(60, arrows + 6)
				rui.show_roll(c, "Great haggle! The trader gives you 6 bone arrows for a smile.")
			else:
				rui.show_roll(c, "The trader tips their hat and goes on their way.")
		"lamb":
			var c: Dictionary = dice.check(roster.bonus("heart") + realm.luck(), 8, e[1] + " (d20 + Heart)")
			if c["win"]:
				realm.raise_rep(5)
				add_xp(8)
			rui.show_roll(c, "You carried it home. Every faction likes you more!" if c["win"] else "It hopped away into the trees.")
		"fairy":
			var c: Dictionary = dice.check(roster.bonus("magic") + realm.luck(), 10, e[1] + " (d20 + Magic)")
			if c["win"]:
				health = 100.0
				mana = 100.0
			rui.show_roll(c, "The circle fills your health and mana!" if c["win"] else "The glow fades softly.")
		_:
			var c: Dictionary = dice.check(roster.bonus("heart") + realm.luck(), 9, e[1] + " (d20 + Heart)")
			if c["win"]:
				add_xp(10)
			rui.show_roll(c, "You found shelter under a big tree and watched the lightning. Brave!" if c["win"] else "You got a little wet. That's okay!")
	save_game()


func after_realm_change() -> void:
	if overworld:
		overworld.draw_villages(realm.villages)
	_update_hero_label()
	save_game()


func _fun_tick(delta: float, t: float) -> void:
	if sneak_left > 0.0:
		sneak_left -= delta
		if sneak_left <= 0.0:
			_set_ghost(false)
		elif power_btn:
			power_btn.text = "Tag" if _tag_target() != null else "Sneak"
	elif power_btn and cls() == "thief" and power_btn.text != "Sneak":
		power_btn.text = "Sneak"
	if charge_left > 0.0:
		charge_left -= delta
		for e in magic.enemies.duplicate():
			var to: Vector3 = e["node"].global_position - hero.global_position
			to.y = 0
			if to.length() < 2.4:
				magic.hurt_plain(e, 14.0 + roster.bonus("might") * 2.0, to.normalized() * 3.0)
				magic._puff(e["node"].global_position + Vector3(0, 1.0, 0), Color(1, 0.9, 0.6), 1.4)
	if block_left > 0.0:
		block_left -= delta
		if block_left <= 0.0:
			_show_shield(false)
	_buddy_tick(delta, t)
	if realm.last_day < clock.day:
		var news := realm.on_day(clock.day)
		var interest := bank.on_day()
		if overworld:
			overworld.draw_villages(realm.villages)
		var s := (news + " " + interest).strip_edges()
		if s != "":
			toast(s)


func travel(to: Vector3, msg: String, yaw := 0.0) -> void:
	hero.position = to
	look_yaw = yaw
	knock = Vector3.ZERO
	if buddy_node:
		buddy_node.position = Vector3(to.x + 1.5, 0, to.z + 1.5)
	magic.clear_enemies()
	magic.spawn_timer = 15.0
	toast(msg)
	save_game()


## Merge the still parts of the town into a few big meshes (far fewer draw calls).
func _merge_static() -> void:
	var skip: Array = [fairy, hero]
	skip.append_array(bugs)
	var runner := get_node_or_null("ArtFx")
	var fx: Dictionary = runner.get_meta("fx") if runner and runner.has_meta("fx") else {}
	for k in fx:
		var v = fx[k]
		if v is Node:
			skip.append(v)
		elif v is Array:
			for it in v:
				if it is Node:
					skip.append(it)
				elif it is Dictionary:
					for kk in it:
						if it[kk] is Node:
							skip.append(it[kk])
	var r: Dictionary = Batcher.merge(self, skip)
	print("Merged %d static meshes into %d" % [r["merged"], r["meshes"]])
