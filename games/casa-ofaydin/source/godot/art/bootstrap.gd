extends Object
# One entry point so main.gd only needs a small hook.

const ArtSky = preload("res://art/sky.gd")
const Town = preload("res://art/town.gd")
const Hero = preload("res://art/hero_model.gd")
const Hud = preload("res://art/hud_style.gd")
const Props = preload("res://art/props.gd")
const Fx = preload("res://art/fx.gd")

static func apply(main: Node3D) -> void:
	ArtSky.setup(main.env, main.sun)
	Hero.build(main.hero)
	Props.style_fairy(main.fairy)
	for b in main.bugs:
		Props.style_bug(b)
	var fx := {}
	Town.build(main, fx)
	Hud.apply(main)
	var runner: Node = main.get_node_or_null("ArtFx")
	if runner == null:
		runner = Fx.new()
		runner.name = "ArtFx"
		main.add_child(runner)
	runner.set_meta("fx", fx)
	if OS.get_environment("ART_SHOT") != "":
		_queue_shots(main)


static func style_new_bug(b: MeshInstance3D) -> void:
	Props.style_bug(b)


static func update_sky(main: Node3D, time_of_day: float, daylight: float) -> void:
	ArtSky.apply(main.env, main.sun, time_of_day, daylight)


static func _queue_shots(main: Node3D) -> void:
	var n := Node.new()
	n.name = "ArtShot"
	n.set_script(load("res://art/shot.gd"))
	main.add_child(n)
