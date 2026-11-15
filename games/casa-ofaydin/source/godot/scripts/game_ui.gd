extends Node
## Phone HUD additions: coins, Gear (paper doll), Bank, Wait / Sleep,
## element chip + Bolt / Ward / Float, Up / Down while floating, toasts.
## Bronze / parchment look to match art/hud_style.gd. Big touch targets.

const LowPoly = preload("res://art/lowpoly_character.gd")

const INK := Color(0.22, 0.15, 0.08)
const PARCH := Color(0.84, 0.75, 0.55)
const BRONZE := Color(0.62, 0.48, 0.25)
const GOLD_TXT := Color(0.94, 0.85, 0.58)

var main: Node3D
var ui: CanvasLayer
var top: CanvasLayer
var coin_label: Label
var toast_box: PanelContainer
var toast_label: Label
var toast_t := 0.0
var flash: ColorRect
var bank_btn: Button
var el_btn: Button
var bolt_btn: Button
var ward_btn: Button
var float_btn: Button
var arms_btn: Button
var up_btn: Button
var down_btn: Button
var bank_panel: Panel
var gear_panel: Panel
var gear_choose := ""   # slot being chosen, "" = slot grid
var bank_amount := 10
var bank_msg := ""
var banker_line := ""
var _hidden: Array = []


func setup(m: Node3D, hud: CanvasLayer) -> void:
	main = m
	ui = hud
	top = CanvasLayer.new()
	top.layer = 5
	main.add_child(top)
	# coins under the clock
	coin_label = Label.new()
	coin_label.position = Vector2(250, 56)
	coin_label.size = Vector2(220, 34)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_label.add_theme_font_size_override("font_size", 24)
	coin_label.add_theme_color_override("font_color", GOLD_TXT)
	coin_label.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04))
	coin_label.add_theme_constant_override("outline_size", 6)
	ui.add_child(coin_label)
	# left column
	_btn(ui, "Gear", Vector2(14, 140), Vector2(132, 84), main.open_gear)
	_btn(ui, "Wait", Vector2(14, 234), Vector2(132, 84), main.do_wait)
	_btn(ui, "Sleep", Vector2(14, 328), Vector2(132, 84), main.do_sleep)
	arms_btn = _btn(ui, "Staff", Vector2(14, 422), Vector2(132, 84), main.next_weapon, 26)
	# right column (above the compass at y 528)
	el_btn = _btn(ui, "Fire", Vector2(574, 140), Vector2(132, 84), main.next_element)
	bolt_btn = _btn(ui, "Bolt", Vector2(574, 234), Vector2(132, 84), main.cast_bolt)
	ward_btn = _btn(ui, "Ward", Vector2(574, 328), Vector2(132, 84), main.cast_ward)
	float_btn = _btn(ui, "Float", Vector2(574, 422), Vector2(132, 84), main.toggle_float)
	# Up / Down only while floating, left of Lux / View
	up_btn = _btn(ui, "Up", Vector2(392, 656), Vector2(132, 132), Callable())
	down_btn = _btn(ui, "Down", Vector2(392, 832), Vector2(132, 132), Callable())
	up_btn.button_down.connect(func(): main.magic.lift = 1.0)
	up_btn.button_up.connect(func(): main.magic.lift = 0.0)
	down_btn.button_down.connect(func(): main.magic.lift = -1.0)
	down_btn.button_up.connect(func(): main.magic.lift = 0.0)
	up_btn.visible = false
	down_btn.visible = false
	# contextual Bank button
	bank_btn = _btn(ui, "Bank", Vector2(230, 150), Vector2(260, 110), open_bank, 40)
	bank_btn.visible = false
	# hit flash
	flash = ColorRect.new()
	flash.color = Color(1, 0.3, 0.2, 0.0)
	flash.position = Vector2.ZERO
	flash.size = Vector2(720, 1280)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(flash)
	# toast
	toast_box = PanelContainer.new()
	toast_box.position = Vector2(40, 96)
	toast_box.custom_minimum_size = Vector2(640, 0)
	toast_box.size = Vector2(640, 0)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tsb := _parch_style(4)
	tsb.bg_color = Color(0.84, 0.75, 0.55, 0.94)
	toast_box.add_theme_stylebox_override("panel", tsb)
	toast_label = Label.new()
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.custom_minimum_size = Vector2(610, 0)
	toast_label.add_theme_font_size_override("font_size", 26)
	toast_label.add_theme_color_override("font_color", INK)
	toast_box.add_child(toast_label)
	toast_box.visible = false
	top.add_child(toast_box)


# ---------------------------------------------------------------- styling

static func safe(s: String) -> String:
	if TavernSafe.contains_forbidden(s):
		return s.replace("6".repeat(3), "6 6 6")
	return s


func _btn_style(bg: Color, border: Color = BRONZE, radius := 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	return sb


func _style(b: Button, font := 30, border: Color = BRONZE) -> void:
	b.add_theme_font_size_override("font_size", font)
	b.add_theme_color_override("font_color", GOLD_TXT)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.65))
	b.add_theme_color_override("font_pressed_color", Color(0.75, 0.6, 0.35))
	b.add_theme_color_override("font_focus_color", GOLD_TXT)
	b.add_theme_stylebox_override("normal", _btn_style(Color(0.28, 0.2, 0.12, 0.92), border))
	b.add_theme_stylebox_override("hover", _btn_style(Color(0.36, 0.26, 0.14, 0.95), border))
	b.add_theme_stylebox_override("pressed", _btn_style(Color(0.18, 0.12, 0.07, 0.95), border))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.focus_mode = Control.FOCUS_NONE


func _btn(parent: Node, text: String, pos: Vector2, sz: Vector2, cb: Callable, font := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.custom_minimum_size = sz
	_style(b, font)
	if cb.is_valid():
		b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _parch_style(border := 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PARCH
	sb.border_color = Color(0.45, 0.32, 0.16)
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


func _label(text: String, font := 26, color: Color = INK, wrap := true) -> Label:
	var l := Label.new()
	l.text = safe(text)
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _row_btn(text: String, cb: Callable, h := 76, font := 26) -> Button:
	var b := Button.new()
	b.text = safe(text)
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	_style(b, font)
	b.pressed.connect(cb)
	return b


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func _hide_hud(on: bool) -> void:
	if on:
		_hidden.clear()
		for c in ui.get_children():
			if c is CanvasItem and c.visible:
				c.visible = false
				_hidden.append(c)
	else:
		for c in _hidden:
			if is_instance_valid(c):
				c.visible = true
		_hidden.clear()


func is_open() -> bool:
	return (bank_panel != null and bank_panel.visible) or (gear_panel != null and gear_panel.visible)


# ---------------------------------------------------------------- per-frame

func _process(delta: float) -> void:
	if main == null:
		return
	coin_label.text = safe("Coins %s" % TavernSafe.number_text(main.bank.purse))
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast_box.visible = false
	if flash.color.a > 0.0:
		flash.color.a = maxf(0.0, flash.color.a - delta * 1.6)
	if is_open():
		return
	bank_btn.visible = main.near_banker()
	var mg = main.magic
	var e: Dictionary = mg.element()
	var ec := Color.html(str(e.get("color", "#ffffff")))
	if el_btn.text != str(e["name"]):
		el_btn.text = str(e["name"])
		_style(el_btn, 30 if el_btn.text.length() <= 6 else 23, ec)
		el_btn.add_theme_color_override("font_color", ec.lightened(0.25))
	ward_btn.text = "Ward" if mg.ward_left <= 0.0 else safe("Ward %s" % TavernSafe.number_text(int(ceil(mg.ward_left))))
	float_btn.text = "Land" if mg.levitating else "Float"
	var wname := {"staff": "Staff", "sword": "Sword", "crossbow": "Crossbow"}
	var wn := str(wname.get(main.weapon, "Staff"))
	if arms_btn.text != wn:
		arms_btn.text = wn
		_style(arms_btn, 26 if wn.length() <= 6 else 21)
	match main.weapon:
		"sword":
			bolt_btn.text = "Slash"
		"crossbow":
			bolt_btn.text = safe("Shoot %s" % TavernSafe.number_text(main.arrows))
		_:
			bolt_btn.text = "Bolt"
	up_btn.visible = mg.levitating
	down_btn.visible = mg.levitating


func toast(text: String, seconds := 3.5) -> void:
	if text == "":
		return
	toast_label.text = safe(text)
	toast_box.size = Vector2(640, 0)
	toast_box.visible = true
	toast_t = seconds


func hit_flash(c: Color) -> void:
	flash.color = Color(c.r, c.g, c.b, 0.38)


# ---------------------------------------------------------------- bank

func open_bank() -> void:
	var lines: Array = main.bank.cfg.get("banker_lines", ["Welcome."])
	banker_line = str(lines[randi() % lines.size()])
	bank_msg = ""
	if bank_panel == null:
		bank_panel = Panel.new()
		bank_panel.position = Vector2(24, 120)
		bank_panel.size = Vector2(672, 1040)
		bank_panel.add_theme_stylebox_override("panel", _parch_style(8))
		top.add_child(bank_panel)
	_hide_hud(true)
	bank_panel.visible = true
	_refresh_bank()


func close_bank() -> void:
	if bank_panel:
		bank_panel.visible = false
	_hide_hud(false)
	main.save_game()


func _bank_do(kind: String) -> void:
	var b = main.bank
	var amt := bank_amount
	if amt <= 0:
		match kind:
			"save": amt = b.purse
			"take": amt = b.savings
			"borrow": amt = b.can_borrow()
			"pay": amt = mini(b.purse, b.loan)
	match kind:
		"save": bank_msg = b.deposit(amt)
		"take": bank_msg = b.withdraw(amt)
		"borrow": bank_msg = b.borrow(amt)
		"pay": bank_msg = b.repay(amt)
	main.save_game()
	_refresh_bank()


func _refresh_bank() -> void:
	_clear(bank_panel)
	var b = main.bank
	var N := func(v: int) -> String: return TavernSafe.number_text(v)
	var v := VBoxContainer.new()
	v.position = Vector2(26, 20)
	v.size = Vector2(620, 1000)
	v.add_theme_constant_override("separation", 10)
	bank_panel.add_child(v)
	v.add_child(_label(str(b.cfg.get("bank_name", "Harbor Counting House")), 38, Color(0.35, 0.2, 0.08)))
	var who := _label("%s: \"%s\"" % [b.cfg.get("banker_name", "The clerk"), banker_line], 24, Color(0.3, 0.22, 0.12))
	v.add_child(who)
	# balances
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	for pair in [["In your purse", b.purse], ["Saved in bank", b.savings], ["You owe", b.loan]]:
		var box := PanelContainer.new()
		var sb := _parch_style(3)
		sb.bg_color = Color(0.92, 0.85, 0.66)
		sb.shadow_size = 0
		box.add_theme_stylebox_override("panel", sb)
		box.custom_minimum_size = Vector2(196, 110)
		var bv := VBoxContainer.new()
		bv.add_child(_label(pair[0], 22, Color(0.35, 0.25, 0.12), false))
		bv.add_child(_label(N.call(int(pair[1])), 40, INK, false))
		box.add_child(bv)
		grid.add_child(box)
	v.add_child(grid)
	var clock = main.clock
	var nxt: String = clock.seasons[(clock.season_ordinal() + 1) % clock.seasons.size()]
	v.add_child(_label("Savings grow %s for every 100 coins each season. Borrowed coins grow %s for every 100. %s starts in %s days." % [
		N.call(b.savings_rate()), N.call(b.loan_rate()), nxt, N.call(clock.days_to_next_season())], 22, Color(0.3, 0.22, 0.12)))
	# amount chips
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	chips.add_child(_label("Amount:", 26, INK, false))
	var opts: Array = b.cfg.get("amount_choices", [5, 10, 25]).duplicate()
	opts.append(0)
	for a in opts:
		var label: String = "All" if int(a) == 0 else N.call(int(a))
		var cb := func(): bank_amount = int(a); _refresh_bank()
		var chip := _row_btn(label, cb, 72, 28)
		if int(a) == bank_amount:
			_style(chip, 28, Color(0.95, 0.8, 0.35))
			chip.add_theme_stylebox_override("normal", _btn_style(Color(0.45, 0.3, 0.12), Color(0.95, 0.8, 0.35)))
		chips.add_child(chip)
	v.add_child(chips)
	# actions
	var acts := GridContainer.new()
	acts.columns = 2
	acts.add_theme_constant_override("h_separation", 12)
	acts.add_theme_constant_override("v_separation", 10)
	for pair2 in [["Save coins", "save"], ["Take out", "take"], ["Borrow", "borrow"], ["Pay back", "pay"]]:
		var k: String = pair2[1]
		var ab := _row_btn(pair2[0], func(): _bank_do(k), 86, 32)
		ab.custom_minimum_size = Vector2(304, 86)
		acts.add_child(ab)
	v.add_child(acts)
	if bank_msg != "":
		v.add_child(_label(bank_msg, 26, Color(0.18, 0.32, 0.12)))
	v.add_child(_label("Recent", 26, Color(0.35, 0.2, 0.08)))
	if b.ledger.is_empty():
		v.add_child(_label("Nothing yet.", 22, Color(0.35, 0.28, 0.18)))
	for line in b.ledger:
		v.add_child(_label("• " + str(line), 22, Color(0.25, 0.18, 0.1)))
	var close := _row_btn("Close", close_bank, 80, 32)
	v.add_child(close)


# ---------------------------------------------------------------- gear (paper doll)

func open_gear() -> void:
	gear_choose = ""
	if gear_panel == null:
		gear_panel = Panel.new()
		gear_panel.position = Vector2(10, 440)
		gear_panel.size = Vector2(700, 832)
		gear_panel.add_theme_stylebox_override("panel", _parch_style(8))
		top.add_child(gear_panel)
	_hide_hud(true)
	gear_panel.visible = true
	main.set_mirror(true)
	_refresh_gear()


func close_gear() -> void:
	if gear_panel:
		gear_panel.visible = false
	_hide_hud(false)
	main.set_mirror(false)
	main.save_game()


func _gear_set(slot: String, id: String) -> void:
	main.wardrobe.equip(slot, id)
	main.rebuild_hero()
	gear_choose = ""
	_refresh_gear()


func _refresh_gear() -> void:
	_clear(gear_panel)
	var w = main.wardrobe
	var v := VBoxContainer.new()
	v.position = Vector2(18, 14)
	v.size = Vector2(664, 806)
	v.add_theme_constant_override("separation", 6)
	gear_panel.add_child(v)
	var tt: Dictionary = w.totals()
	var N := func(x: int) -> String: return TavernSafe.number_text(x)
	var head := HBoxContainer.new()
	head.add_child(_label("Gear", 36, Color(0.35, 0.2, 0.08), false))
	var stats := _label("Armor %s  Warmth %s  Charm %s  Stealth %s" % [N.call(tt["armor"]), N.call(tt["warmth"]), N.call(tt["charm"]), N.call(tt["stealth"])], 22, Color(0.3, 0.22, 0.12), false)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(stats)
	v.add_child(head)
	if gear_choose == "":
		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 10)
		top_row.add_child(_row_btn("Dress Me", func(): w.dress_me(); main.rebuild_hero(); _refresh_gear(), 72, 26))
		top_row.add_child(_row_btn("Take All Off", func(): w.strip_all(); main.rebuild_hero(); _refresh_gear(), 72, 26))
		top_row.add_child(_row_btn("Close", close_gear, 72, 26))
		v.add_child(top_row)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 6)
		for s in w.slots:
			var slot: String = s["slot"]
			var id := str(w.equipped.get(slot, ""))
			var nm: String = w.item_name(id) if id != "" else "(nothing)"
			var b := _row_btn("%s\n%s" % [s["label"], nm], func(): gear_choose = slot; _refresh_gear(), 74, 23)
			b.custom_minimum_size = Vector2(327, 74)
			if id == "":
				b.add_theme_color_override("font_color", Color(0.75, 0.66, 0.5))
			grid.add_child(b)
		v.add_child(grid)
	else:
		var info: Dictionary = w.slot_info(gear_choose)
		v.add_child(_label("Choose: %s" % info.get("label", gear_choose), 28, INK, false))
		var cur := str(w.equipped.get(gear_choose, ""))
		for it in w.items_for(gear_choose):
			var id2 := str(it["id"])
			var st: Dictionary = it.get("stats", {})
			var mark := "✓ " if id2 == cur else ""
			var txt := "%s%s\narmor %s · warmth %s · charm %s" % [mark, it["name"], N.call(int(st.get("armor", 0))), N.call(int(st.get("warmth", 0))), N.call(int(st.get("charm", 0)))]
			var b2 := _row_btn(txt, func(): _gear_set(gear_choose, id2), 84, 24)
			if id2 == cur:
				b2.add_theme_stylebox_override("normal", _btn_style(Color(0.4, 0.28, 0.12, 0.95), Color(0.95, 0.8, 0.35)))
			v.add_child(b2)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(_row_btn("Take Off", func(): _gear_set(gear_choose, ""), 78, 26))
		row.add_child(_row_btn("Back", func(): gear_choose = ""; _refresh_gear(), 78, 26))
		v.add_child(row)
		v.add_child(_label("Your plain shirt and shorts always stay on.", 22, Color(0.35, 0.28, 0.18)))
