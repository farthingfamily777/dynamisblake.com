extends Node
## Low / Med / High quality for cheap phones. Auto mode samples the frame rate
## for the first few seconds and steps down if it is under ~20 (Blake: steady 20 in Low). Manual choice is
## saved. Low: 0.65 render scale, no shadows, short fog and draw distance, fewer
## lights, LOD1 (<=450 tris) close, LOD2 (<=190) far, sprites beyond 30 m, and
## at most 10 townsfolk drawn at once.
## URL test switches (web): ?q=low|med|high|auto  ?fps=1  ?perf=before

const LowPoly = preload("res://art/lowpoly_character.gd")
const SETTINGS := "user://casa_settings.json"
const MODES := {
	"low": {"scale": 0.65, "shadows": false, "far": 70.0, "fog": true, "lights": false, "npcs": 10, "chunk": 80.0},
	"med": {"scale": 0.75, "shadows": false, "far": 110.0, "fog": true, "lights": true, "npcs": 12, "chunk": 120.0},
	"high": {"scale": 1.0, "shadows": true, "far": 400.0, "fog": false, "lights": true, "npcs": 99, "chunk": 0.0}
}

var main: Node3D
var choice := "auto"     # what the player picked
var mode := "high"       # what is applied now
var show_fps := false
var before := false      # ?perf=before: skip the optimizations to measure the old way
var readout: Label
var _sample_t := 0.0
var _sample_frames := 0
var _sampling := false
var _print_t := 0.0


func setup(m: Node3D) -> void:
	main = m
	_load()
	var q := _url_param("q")
	if q in ["low", "med", "high", "auto"]:
		choice = q
	if _url_param("fps") == "1":
		show_fps = true
	before = _url_param("perf") == "before"
	if choice == "auto":
		mode = _guess()
		_sampling = true
	else:
		mode = choice
	if before:
		mode = "high"
		_sampling = false
	LowPoly.quality = mode
	var ui := CanvasLayer.new()
	ui.layer = 10
	main.add_child(ui)
	readout = Label.new()
	readout.position = Vector2(170, 1240)
	readout.size = Vector2(540, 36)
	readout.add_theme_font_size_override("font_size", 22)
	readout.add_theme_color_override("font_color", Color(1, 1, 0.6))
	readout.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	readout.add_theme_constant_override("outline_size", 6)
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(readout)


func _url_param(k: String) -> String:
	if not OS.has_feature("web"):
		return OS.get_environment("CASA_" + k.to_upper())
	var v = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('%s') || ''" % k, true)
	return str(v) if v != null else ""


## First guess before any frames: phones and small-memory devices start on Low.
func _guess() -> String:
	if OS.has_feature("web"):
		var weak = JavaScriptBridge.eval("(function(){var m=navigator.deviceMemory||4;var c=navigator.hardwareConcurrency||4;var mob=/Android|iPhone|iPad|Mobile/i.test(navigator.userAgent);return (mob&&(m<=4||c<=6))||m<=2||c<=2;})()", true)
		if weak == true:
			return "low"
		var mob = JavaScriptBridge.eval("/Android|iPhone|iPad|Mobile/i.test(navigator.userAgent)", true)
		return "med" if mob == true else "high"
	if OS.has_feature("mobile"):
		return "low"
	return "high"


func set_choice(c: String) -> void:
	choice = c
	if c == "auto":
		_sampling = true
		_sample_t = 0.0
		_sample_frames = 0
	else:
		mode = c
		_sampling = false
	apply()
	_save()


func toggle_fps() -> void:
	show_fps = not show_fps
	_save()


func apply() -> void:
	if main == null:
		return
	var q: Dictionary = MODES[mode]
	LowPoly.quality = mode
	var vp := main.get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = float(q["scale"])
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	if main.sun:
		main.sun.shadow_enabled = bool(q["shadows"])
	if main.cam:
		main.cam.far = float(q["far"])
	var env: Environment = main.env
	if env:
		env.fog_enabled = bool(q["fog"])
		if env.fog_enabled:
			env.fog_mode = Environment.FOG_MODE_DEPTH
			env.fog_depth_begin = float(q["far"]) * 0.55
			env.fog_depth_end = float(q["far"]) * 0.98
			env.fog_light_color = Color(0.72, 0.8, 0.88)
			env.fog_density = 1.0
	# Lights: keep the sun; little omni / spot lights only when the mode allows.
	for l in main.find_children("*", "Light3D", true, false):
		if l is DirectionalLight3D:
			continue
		if not l.has_meta("q_was"):
			l.set_meta("q_was", l.visible)
		l.visible = bool(l.get_meta("q_was")) and bool(q["lights"])
		(l as Light3D).shadow_enabled = false
	for b in main.get_tree().get_nodes_in_group("lp_body"):
		LowPoly.apply_quality(b)
	for c in main.get_tree().get_nodes_in_group("ow_chunk"):
		(c as GeometryInstance3D).visibility_range_end = float(q["chunk"])
	var fx = main.get_node_or_null("ArtFx")
	if fx:
		fx.set_meta("npc_cap", int(q["npcs"]))


func _process(delta: float) -> void:
	if main == null:
		return
	if _sampling:
		_sample_t += delta
		_sample_frames += 1
		if _sample_t > 6.0:
			var fps := _sample_frames / _sample_t
			_sample_t = 0.0
			_sample_frames = 0
			var step := {"high": "med", "med": "low"}
			if fps < 19.0 and step.has(mode):
				mode = step[mode]
				apply()
				main.toast("Switched to %s quality so the game runs smoothly." % mode.capitalize())
			else:
				_sampling = false
	readout.visible = show_fps
	if show_fps:
		var t := "FPS %d  draws %d  tris %d  %s%s" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), mode.to_upper(), " (before)" if before else ""]
		readout.text = t.replace("6".repeat(3), "6 6 6")
		_print_t += delta
		if _print_t > 2.0:
			_print_t = 0.0
			print("PERF ", readout.text)


func _load() -> void:
	if not FileAccess.file_exists(SETTINGS):
		return
	var f := FileAccess.open(SETTINGS, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text()) if f else null
	if typeof(d) == TYPE_DICTIONARY:
		choice = str(d.get("choice", "auto"))
		show_fps = bool(d.get("fps", false))


func _save() -> void:
	var f := FileAccess.open(SETTINGS, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"choice": choice, "fps": show_fps}))
