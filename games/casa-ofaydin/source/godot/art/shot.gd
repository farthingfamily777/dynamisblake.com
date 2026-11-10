extends Node
# Dev-only: dump PNGs then quit when ART_SHOT=1.

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var main: Node = get_parent()
	var dir := OS.get_environment("ART_SHOT_DIR")
	if dir == "":
		dir = "/tmp/art-shots"
	DirAccess.make_dir_recursive_absolute(dir)
	# 1) Start view, morning (default camera, time_of_day 0.3 ~ 07:12)
	if "time_of_day" in main:
		main.time_of_day = 0.3
	await get_tree().process_frame
	await get_tree().process_frame
	_shot(dir + "/01-morning-start.png")
	if not ("cam" in main and "hero" in main):
		if OS.get_environment("ART_SHOT_QUIT") == "1":
			get_tree().quit()
		return
	var free := Camera3D.new()
	free.name = "BeautyCam"
	main.add_child(free)
	free.current = true
	# 2) Harbor wide, morning
	if "time_of_day" in main:
		main.time_of_day = 0.32
	free.position = Vector3(-6, 11.0, 2)
	free.look_at(Vector3(2, 1.2, -30))
	await get_tree().process_frame
	await get_tree().process_frame
	_shot(dir + "/02-harbor-wide.png")
	# 3) Market
	if "time_of_day" in main:
		main.time_of_day = 0.45
	free.position = Vector3(1.5, 3.2, 7.5)
	free.look_at(Vector3(0, 1.4, -6))
	await get_tree().process_frame
	await get_tree().process_frame
	_shot(dir + "/03-market.png")
	# 4) Dusk, start-ish view (see-through, not a brown wall)
	if "time_of_day" in main:
		main.time_of_day = 0.76
	free.position = Vector3(0.4, 3.4, 5.2)
	free.look_at(Vector3(0, 1.6, -16))
	await get_tree().process_frame
	await get_tree().process_frame
	_shot(dir + "/04-dusk.png")
	# 5) Hero close
	if "time_of_day" in main:
		main.time_of_day = 0.35
	free.position = Vector3(1.5, 1.65, 2.3)
	free.look_at(Vector3(0, 1.2, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	_shot(dir + "/05-hero-close.png")
	# Extra checks (not required in the v3 set)
	if "time_of_day" in main:
		main.time_of_day = 0.5
	free.position = Vector3(6, 6.0, 6)
	free.look_at(Vector3(0, 1.5, -20))
	await get_tree().process_frame
	await get_tree().process_frame
	_shot(dir + "/08-noon-check.png")
	if OS.get_environment("ART_SHOT_QUIT") == "1":
		get_tree().quit()


func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("ART_SHOT ", path)
