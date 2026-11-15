extends Node
# Dev-only: dump PNGs then quit when ART_SHOT=1.
# ART_SHOT=1 -> baseline town views. ART_SHOT=2 -> people / gear / bank / magic set.

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var main: Node = get_parent()
	var dir := OS.get_environment("ART_SHOT_DIR")
	if dir == "":
		dir = "/tmp/art-shots"
	DirAccess.make_dir_recursive_absolute(dir)
	if OS.get_environment("ART_SHOT") == "3":
		await _set3(main, dir)
		if OS.get_environment("ART_SHOT_QUIT") == "1":
			get_tree().quit()
		return
	if OS.get_environment("ART_SHOT") == "2":
		await _set2(main, dir)
		if OS.get_environment("ART_SHOT_QUIT") == "1":
			get_tree().quit()
		return
	if "time_of_day" in main:
		main.time_of_day = 0.3
	await _frames(2)
	_shot(dir + "/01-morning-start.png")
	var free := Camera3D.new()
	free.name = "BeautyCam"
	main.add_child(free)
	free.current = true
	main.time_of_day = 0.32
	free.position = Vector3(-6, 11.0, 2)
	free.look_at(Vector3(2, 1.2, -30))
	await _frames(2)
	_shot(dir + "/02-harbor-wide.png")
	main.time_of_day = 0.45
	free.position = Vector3(1.5, 3.2, 7.5)
	free.look_at(Vector3(0, 1.4, -6))
	await _frames(2)
	_shot(dir + "/03-market.png")
	main.time_of_day = 0.76
	free.position = Vector3(0.4, 3.4, 5.2)
	free.look_at(Vector3(0, 1.6, -16))
	await _frames(2)
	_shot(dir + "/04-dusk.png")
	main.time_of_day = 0.35
	free.position = Vector3(0.0, 1.5, -2.6)
	free.look_at(Vector3(0, 0.9, 0))
	await _frames(2)
	_shot(dir + "/05-hero-close.png")
	main.time_of_day = 0.5
	free.position = Vector3(6, 6.0, 6)
	free.look_at(Vector3(0, 1.5, -20))
	await _frames(2)
	_shot(dir + "/08-noon-check.png")
	if OS.get_environment("ART_SHOT_QUIT") == "1":
		get_tree().quit()


func _set2(main: Node, dir: String) -> void:
	main.magic.enabled = false
	main.time_of_day = 0.36
	await _frames(3)
	_shot(dir + "/10-start.png")
	var free := Camera3D.new()
	main.add_child(free)
	free.current = true
	# crowd close in the market
	free.position = Vector3(-0.6, 1.6, -4.2)
	free.look_at(Vector3(-3.2, 1.0, 1.0))
	await _frames(3)
	_shot(dir + "/11-crowd.png")
	# hero front close
	free.position = Vector3(0.6, 1.45, -2.4)
	free.look_at(Vector3(0, 0.85, 0))
	await _frames(3)
	_shot(dir + "/12-hero-front.png")
	# gear: fully geared (Dress Me) vs stripped
	main.cam.current = true
	main.wardrobe.dress_me()
	main.rebuild_hero()
	main.gui.open_gear()
	await _frames(3)
	_shot(dir + "/13-gear-full.png")
	main.wardrobe.strip_all()
	main.rebuild_hero()
	main.gui._refresh_gear()
	await _frames(3)
	_shot(dir + "/14-gear-stripped.png")
	main.gui.gear_choose = "pauldron_l"
	main.gui._refresh_gear()
	await _frames(2)
	_shot(dir + "/15-gear-choose.png")
	main.gui.close_gear()
	main.wardrobe.equipped = main.wardrobe.start.duplicate()
	main.rebuild_hero()
	# bank: walk up to the banker
	main.hero.position = Vector3(-2.2, 1, -6.4)
	main.look_yaw = deg_to_rad(80)
	main.hero.rotation.y = main.look_yaw
	await _frames(3)
	_shot(dir + "/16-bank-walkup.png")
	main.gui.open_bank()
	await _frames(2)
	_shot(dir + "/17-bank-open.png")
	main.gui.bank_amount = 25
	main.gui._bank_do("save")
	await _frames(2)
	_shot(dir + "/18-bank-after-deposit.png")
	main.gui.close_bank()
	# magic: enemy winding up, ward blocking, levitating
	main.hero.position = Vector3(0, 1, 14.0)
	main.look_yaw = 0.0
	main.hero.rotation.y = 0.0
	main.magic.enabled = true
	main.magic.spawn_timer = 999.0
	var e: Dictionary = main.magic.spawn_enemy(Vector3(1.2, 0, 7.6))
	main.magic.element_index = 0
	for i in 30:
		await get_tree().physics_frame
	e["state"] = "windup"
	e["t"] = 0.5
	main.magic._make_orb(e)
	for i in 12:
		await get_tree().physics_frame
	main.magic.enabled = false
	_shot(dir + "/19-enemy-casting.png")
	free.current = true
	free.position = Vector3(3.6, 1.5, 11.2)
	free.look_at(Vector3(1.0, 1.2, 7.6))
	await _frames(2)
	_shot(dir + "/19b-enemy-casting-close.png")
	main.cam.current = true
	main.magic.enabled = true
	# ward matching the enemy element, then a bolt arrives
	var idx := 0
	for k in main.magic.elements.size():
		if main.magic.elements[k]["id"] == e["element"]:
			idx = k
	main.magic.element_index = idx
	main.mana = 100.0
	main.magic.cast_ward()
	for i in 40:
		await get_tree().physics_frame
		if main.magic.bolts.size() > 0:
			var b: Dictionary = main.magic.bolts[0]
			if b["node"].global_position.distance_to(main.hero.global_position) < 2.2:
				break
	main.magic.enabled = false
	_shot(dir + "/20-ward-block.png")
	free.current = true
	free.position = Vector3(2.4, 3.2, 18.2)
	free.look_at(Vector3(0.4, 0.9, 12.5))
	await _frames(2)
	_shot(dir + "/20b-ward-block-close.png")
	main.cam.current = true
	main.magic.enabled = true
	main.magic.clear_enemies()
	main.magic.ward_left = 0.01
	# levitate above the market
	main.hero.position = Vector3(0, 1, 2)
	main.look_yaw = 0.0
	main.hero.rotation.y = 0.0
	main.mana = 100.0
	main.magic.toggle_float()
	main.magic.lift = 1.0
	for i in 120:
		await get_tree().physics_frame
	main.magic.lift = 0.0
	main.look_pitch = deg_to_rad(-32)
	await _frames(3)
	_shot(dir + "/21-levitate.png")
	free.current = true
	free.position = main.hero.position + Vector3(3.5, 0.5, 4.5)
	free.look_at(main.hero.position + Vector3(0, -1.5, 0))
	await _frames(3)
	_shot(dir + "/22-levitate-side.png")


## Slice 1 set: walk cycle, weapons, lightning, LOD swap, Wait / Sleep.
func _set3(main: Node, dir: String) -> void:
	main.magic.enabled = false
	main.time_of_day = 0.4
	main.hero.position = Vector3(0, 1, 14.0)
	main.look_yaw = 0.0
	main.hero.rotation.y = 0.0
	await _frames(3)
	var free := Camera3D.new()
	main.add_child(free)
	var body: Node3D = main.hero.get_node("Body")
	# Walk cycle, side view, 4 key poses (contact, passing, contact, passing).
	free.current = true
	free.position = main.hero.position + Vector3(3.2, 0.1, 0)
	free.look_at(main.hero.position + Vector3(0, -0.15, 0))
	var names := ["a-contact", "b-passing", "c-contact", "d-passing"]
	for i in 4:
		var ph := PI / 2 + i * PI / 2
		main.set_physics_process(false)
		body.set_meta("action", "")
		preload("res://art/lowpoly_character.gd").animate(body, ph, 1.0, 0.0)
		await _frames(2)
		_shot(dir + "/30-walk-%s.png" % names[i])
	main.set_physics_process(true)
	# Hero front at 3/4 view with each weapon.
	free.position = main.hero.position + Vector3(1.6, 0.4, -2.6)
	free.look_at(main.hero.position + Vector3(0, -0.2, 0))
	for w in ["staff", "sword", "crossbow"]:
		main.weapon = w
		main.rebuild_hero()
		await _frames(3)
		_shot(dir + "/31-hero-%s.png" % w)
	# Enemy to fight.
	main.magic.enabled = true
	main.magic.spawn_timer = 999.0
	var e: Dictionary = main.magic.spawn_enemy(Vector3(0.6, 0, 11.4))
	main.magic.enabled = false
	free.position = main.hero.position + Vector3(3.0, 0.9, 3.0)
	free.look_at(main.hero.position + Vector3(-0.3, -0.1, -1.4))
	# Sword slash mid-swing.
	main.weapon = "sword"
	main.rebuild_hero()
	main.cast_bolt()
	for i in 8:
		await get_tree().physics_frame
	await _frames(1)
	_shot(dir + "/32a-sword-windup.png")
	for i in 6:
		await get_tree().physics_frame
	await _frames(1)
	_shot(dir + "/32-sword-slash.png")
	# Crossbow shot: arrow in flight.
	main.weapon = "crossbow"
	main.rebuild_hero()
	main.action = ""
	await _frames(2)
	main.magic.enabled = true
	main.cast_bolt()
	for i in 4:
		await get_tree().physics_frame
	main.magic.enabled = false
	await _frames(1)
	_shot(dir + "/33-crossbow-bone-arrow.png")
	# Lightning from the fingertips.
	main.weapon = "staff"
	main.rebuild_hero()
	for k in main.magic.elements.size():
		if main.magic.elements[k]["id"] == "lightning":
			main.magic.element_index = k
	main.mana = 100.0
	main.magic.enabled = true
	main.cast_bolt()
	for i in 5:
		await get_tree().physics_frame
	main.magic.enabled = false
	await _frames(1)
	_shot(dir + "/34-lightning-fingertips.png")
	main.magic.enabled = true
	main.magic.clear_enemies()
	main.magic.enabled = false
	# LOD swap: same crowd near and far (far ones use the ~440-tri mesh).
	main.cam.current = true
	main.hero.position = Vector3(0, 1, 2)
	main.look_yaw = 0.0
	main.hero.rotation.y = 0.0
	free.current = true
	free.position = Vector3(-0.6, 1.6, -4.2)
	free.look_at(Vector3(-3.2, 1.0, 1.0))
	await _frames(3)
	_shot(dir + "/35-crowd-near-lod0.png")
	free.position = Vector3(6, 6, 18)
	free.look_at(Vector3(-2, 1.0, -4))
	await _frames(3)
	_shot(dir + "/36-crowd-far-lod1.png")
	# Wait and Sleep on the 20-minute game hour.
	main.cam.current = true
	main.do_wait()
	await _frames(3)
	_shot(dir + "/37-wait.png")
	main.do_sleep()
	await _frames(3)
	_shot(dir + "/38-sleep.png")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("ART_SHOT ", path)
