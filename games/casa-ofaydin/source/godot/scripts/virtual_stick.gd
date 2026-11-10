extends Control
## On-screen analog stick: gold ring + knob, one tracked finger.
## mouse_filter is IGNORE so multi-touch is handled by main.gd.

const GOLD := Color(0.62, 0.48, 0.25, 0.72)
const GOLD_ACTIVE := Color(0.78, 0.62, 0.32, 0.9)
const FILL := Color(0.08, 0.06, 0.04, 0.42)
const FILL_ACTIVE := Color(0.12, 0.09, 0.05, 0.55)
const KNOB_FILL := Color(0.28, 0.2, 0.12, 0.7)
const KNOB_FILL_ACTIVE := Color(0.36, 0.26, 0.14, 0.85)

var deadzone := 0.16
var value := Vector2.ZERO
var finger := -1
var _ring: Panel
var _knob: Panel
var _caption: Label
var _travel := 0.0

func setup(caption: String, pos: Vector2, side: float) -> void:
	name = "Stick%s" % caption
	position = pos
	size = Vector2(side, side)
	mouse_filter = MOUSE_FILTER_IGNORE
	_travel = side * 0.32
	_ring = Panel.new()
	_ring.set_anchors_preset(PRESET_FULL_RECT)
	_ring.mouse_filter = MOUSE_FILTER_IGNORE
	_ring.add_theme_stylebox_override("panel", _circle(FILL, GOLD, 4, int(side / 2.0)))
	add_child(_ring)
	var knob_side := side * 0.38
	_knob = Panel.new()
	_knob.size = Vector2(knob_side, knob_side)
	_knob.mouse_filter = MOUSE_FILTER_IGNORE
	_knob.add_theme_stylebox_override("panel", _circle(KNOB_FILL, GOLD, 3, int(knob_side / 2.0)))
	add_child(_knob)
	_caption = Label.new()
	_caption.text = caption
	_caption.mouse_filter = MOUSE_FILTER_IGNORE
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.position = Vector2(0, -32)
	_caption.size = Vector2(side, 32)
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55, 0.85))
	_caption.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.7))
	_caption.add_theme_constant_override("outline_size", 3)
	add_child(_caption)
	_place_knob(Vector2.ZERO)


func _circle(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	return sb


func contains_point(screen_pos: Vector2, extra := 36.0) -> bool:
	var c := global_position + size * 0.5
	return c.distance_to(screen_pos) <= (size.x * 0.5 + extra)


func begin(index: int, screen_pos: Vector2) -> void:
	finger = index
	_set_active(true)
	update_touch(screen_pos)


func update_touch(screen_pos: Vector2) -> void:
	var c := global_position + size * 0.5
	var d := screen_pos - c
	if d.length() > _travel:
		d = d.normalized() * _travel
	var raw := d / _travel
	var length := raw.length()
	if length < deadzone:
		value = Vector2.ZERO
	else:
		value = raw.normalized() * clampf((length - deadzone) / (1.0 - deadzone), 0.0, 1.0)
	_place_knob(d)


func end_if(index: int) -> bool:
	if finger != index:
		return false
	finger = -1
	value = Vector2.ZERO
	_set_active(false)
	_place_knob(Vector2.ZERO)
	return true


func reset() -> void:
	finger = -1
	value = Vector2.ZERO
	_set_active(false)
	_place_knob(Vector2.ZERO)


func _place_knob(d: Vector2) -> void:
	if _knob == null:
		return
	var c := size * 0.5 - _knob.size * 0.5
	_knob.position = c + d


func _set_active(on: bool) -> void:
	if _ring == null:
		return
	var side := int(size.x / 2.0)
	var ks := int(_knob.size.x / 2.0)
	if on:
		_ring.add_theme_stylebox_override("panel", _circle(FILL_ACTIVE, GOLD_ACTIVE, 4, side))
		_knob.add_theme_stylebox_override("panel", _circle(KNOB_FILL_ACTIVE, GOLD_ACTIVE, 3, ks))
	else:
		_ring.add_theme_stylebox_override("panel", _circle(FILL, GOLD, 4, side))
		_knob.add_theme_stylebox_override("panel", _circle(KNOB_FILL, GOLD, 3, ks))
