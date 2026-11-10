extends Object
# Morrowind-like HUD: thin gold-framed red/blue/green bars bottom-left,
# spell/weapon box, compass/minimap bottom-right.
# Lux and View stay large for phone, restyled bronze/stone.

const Tex = preload("res://art/tex.gd")

static func apply(main: Node) -> void:
	var ui: CanvasLayer = null
	for c in main.get_children():
		if c is CanvasLayer:
			ui = c
			break
	if ui == null:
		return

	var parchment := Color(0.82, 0.72, 0.5)
	var ink := Color(0.22, 0.16, 0.1)
	_style_bars(main, ui)
	_style_clock(main, ink, parchment)
	_style_buttons(ui)
	_add_icon_box(ui)
	_add_compass(ui, main)
	# Move / Look sticks are built in main.gd; bars sit above the left stick.


static func _gold_frame(border := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.04, 0.82)
	sb.border_color = Color(0.55, 0.42, 0.22)
	sb.set_border_width_all(border)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb


static func _style_bars(main: Node, ui: CanvasLayer) -> void:
	# Morrowind mid-left cluster, above the Move stick (20, 1008).
	var specs := [
		[main.hp_bar, Color(0.72, 0.12, 0.1), Vector2(24, 848)],
		[main.mp_bar, Color(0.18, 0.32, 0.7), Vector2(24, 874)]
	]
	for s in specs:
		var p: ProgressBar = s[0]
		p.position = s[2]
		p.size = Vector2(200, 18)
		p.show_percentage = false
		p.max_value = 100
		var fill := StyleBoxFlat.new()
		fill.bg_color = s[1]
		p.add_theme_stylebox_override("fill", fill)
		p.add_theme_stylebox_override("background", _gold_frame(2))
	# stamina (visual only — gameplay unchanged)
	if main.get_node_or_null("HudStam") == null:
		var stam := ProgressBar.new()
		stam.name = "HudStam"
		stam.position = Vector2(24, 900)
		stam.size = Vector2(200, 18)
		stam.show_percentage = false
		stam.max_value = 100
		stam.value = 100
		var fillg := StyleBoxFlat.new()
		fillg.bg_color = Color(0.22, 0.55, 0.22)
		stam.add_theme_stylebox_override("fill", fillg)
		stam.add_theme_stylebox_override("background", _gold_frame(2))
		ui.add_child(stam)
		main.set_meta("stam_bar", stam)


static func _style_clock(main: Node, ink: Color, parchment: Color) -> void:
	var clock: Label = main.clock_label
	clock.position = Vector2(230, 18)
	clock.size = Vector2(260, 40)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock.add_theme_font_size_override("font_size", 22)
	clock.add_theme_color_override("font_color", ink)
	clock.add_theme_color_override("font_outline_color", parchment)
	clock.add_theme_constant_override("outline_size", 3)
	# backing
	if main.get_node_or_null("ClockBack") == null:
		# parent is ui; add behind via ui
		pass
	var ui := clock.get_parent()
	if ui and ui.get_node_or_null("ClockBack") == null:
		var back := ColorRect.new()
		back.name = "ClockBack"
		back.color = Color(0.18, 0.14, 0.08, 0.7)
		back.position = Vector2(250, 16)
		back.size = Vector2(220, 36)
		ui.add_child(back)
		ui.move_child(back, 0)


static func _style_buttons(ui: CanvasLayer) -> void:
	for c in ui.get_children():
		if not (c is Button):
			continue
		var b: Button = c
		b.add_theme_font_size_override("font_size", 36)
		b.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55))
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.65))
		b.add_theme_color_override("font_pressed_color", Color(0.7, 0.55, 0.3))
		b.add_theme_stylebox_override("normal", _btn_style(Color(0.28, 0.2, 0.12)))
		b.add_theme_stylebox_override("hover", _btn_style(Color(0.36, 0.26, 0.14)))
		b.add_theme_stylebox_override("pressed", _btn_style(Color(0.2, 0.14, 0.08)))
		# keep the 160x160 size; positions come from main.gd (above the look stick)


static func _btn_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(0.62, 0.48, 0.25)
	sb.set_border_width_all(4)
	sb.corner_radius_top_left = 80
	sb.corner_radius_top_right = 80
	sb.corner_radius_bottom_left = 80
	sb.corner_radius_bottom_right = 80
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	return sb


static func _add_icon_box(ui: CanvasLayer) -> void:
	if ui.get_node_or_null("SpellBox"):
		return
	var box := ColorRect.new()
	box.name = "SpellBox"
	box.position = Vector2(232, 848)
	box.size = Vector2(70, 70)
	box.color = Color(0.08, 0.06, 0.04, 0.85)
	ui.add_child(box)
	var frame := ReferenceRect.new()
	# simple gold border via four rects is heavy; use a StyleBox panel
	var panel := Panel.new()
	panel.position = Vector2(232, 848)
	panel.size = Vector2(70, 70)
	panel.add_theme_stylebox_override("panel", _gold_frame(3))
	ui.add_child(panel)
	var icon := TextureRect.new()
	icon.position = Vector2(240, 856)
	icon.size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _lux_icon()
	ui.add_child(icon)


static func _lux_icon() -> ImageTexture:
	# Sun/light burst — not an eye.
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold := Color(0.85, 0.7, 0.3, 1)
	var pale := Color(1.0, 0.92, 0.65, 1)
	for y in 64:
		for x in 64:
			var dx := float(x) - 32.0
			var dy := float(y) - 32.0
			var r := sqrt(dx * dx + dy * dy)
			var ang := atan2(dy, dx)
			var ray := absf(sin(ang * 8.0))
			if r < 10.0:
				img.set_pixel(x, y, pale)
			elif r < 14.0:
				img.set_pixel(x, y, gold)
			elif r < 26.0 and ray > 0.62:
				var a := 1.0 - (r - 14.0) / 12.0
				img.set_pixel(x, y, Color(gold.r, gold.g, gold.b, a))
	return ImageTexture.create_from_image(img)


static func _add_compass(ui: CanvasLayer, main: Node) -> void:
	if ui.get_node_or_null("Compass"):
		return
	# Bottom-right, above the Lux button (536, 656).
	var panel := Panel.new()
	panel.name = "Compass"
	panel.position = Vector2(592, 528)
	panel.size = Vector2(108, 108)
	panel.add_theme_stylebox_override("panel", _gold_frame(3))
	ui.add_child(panel)
	var face := ColorRect.new()
	face.color = Color(0.22, 0.2, 0.14, 1)
	face.position = Vector2(6, 6)
	face.size = Vector2(96, 96)
	panel.add_child(face)
	# simple map stains
	var n := Label.new()
	n.text = "N"
	n.position = Vector2(46, 4)
	n.add_theme_font_size_override("font_size", 14)
	n.add_theme_color_override("font_color", Color(0.85, 0.7, 0.35))
	panel.add_child(n)
	var s := Label.new()
	s.text = "S"
	s.position = Vector2(47, 84)
	s.add_theme_font_size_override("font_size", 12)
	s.add_theme_color_override("font_color", Color(0.7, 0.58, 0.35))
	panel.add_child(s)
	# harbor mark (north / -Z)
	var water := ColorRect.new()
	water.color = Color(0.18, 0.22, 0.18, 0.9)
	water.position = Vector2(18, 14)
	water.size = Vector2(72, 22)
	panel.add_child(water)
	# town pip
	var town := ColorRect.new()
	town.color = Color(0.4, 0.3, 0.18)
	town.position = Vector2(40, 42)
	town.size = Vector2(28, 28)
	panel.add_child(town)
	# player pip
	var pip := ColorRect.new()
	pip.name = "HeroPip"
	pip.color = Color(0.9, 0.85, 0.45)
	pip.position = Vector2(50, 52)
	pip.size = Vector2(8, 8)
	panel.add_child(pip)
	main.set_meta("compass_pip", pip)
