extends Node
## Big-button screens for the fun layer: Make a Hero (with animated dice),
## the d20 popup, and the Realm book (Heroes, Land, Faith, Allies, Shop).
## Reuses GameUI's parchment and bronze styling. Plain words, big targets.

const HeroClass = preload("res://scripts/hero_class.gd")
const Dice = preload("res://scripts/dice.gd")
const Realm = preload("res://scripts/realm.gd")

var main: Node3D
var g: Node   # GameUI, for styles
var layer: CanvasLayer
var creator: Panel
var book: Panel
var popup: Panel
var popup_num: Label
var popup_die: Panel
var popup_text: Label
var popup_t := 0.0
var popup_final := 0
var popup_hold := 0.0
var chip: Label
var chip_t := 0.0
var tab := "heroes"
var body: VBoxContainer
# creator state
var c_cls := "mage"
var c_name := ""
var c_roll: Dictionary = {}
var c_anim := 0.0
var c_spawn := 0   # 0 = near hero, 1.. = village index + 1
var c_die_labels: Array = []
var c_stat_labels: Array = []
var c_name_label: Label
var c_blurb: Label
var c_class_btns: Dictionary = {}
var c_spawn_btn: Button
var c_cancel: Button
# realm book state
var new_village_name := ""
var faith_name := ""
var faith_virtue := 0
var faith_blessing := "light"
var haggle_price := -1
var name_rng := RandomNumberGenerator.new()


func setup(m: Node3D, gui: Node) -> void:
	main = m
	g = gui
	name_rng.randomize()
	layer = CanvasLayer.new()
	layer.layer = 8
	main.add_child(layer)
	var top := CanvasLayer.new()
	top.layer = 9
	main.add_child(top)
	chip = Label.new()
	chip.position = Vector2(470, 600)
	chip.size = Vector2(240, 60)
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_theme_font_size_override("font_size", 30)
	chip.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.03))
	chip.add_theme_constant_override("outline_size", 8)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.visible = false
	top.add_child(chip)
	_build_popup(top)


func is_open() -> bool:
	return (creator != null and creator.visible) or (book != null and book.visible)


func _panel() -> Panel:
	var p := Panel.new()
	p.position = Vector2(12, 12)
	p.size = Vector2(696, 1256)
	p.add_theme_stylebox_override("panel", g._parch_style(6))
	layer.add_child(p)
	return p


func _b(parent: Node, text: String, pos: Vector2, sz: Vector2, cb: Callable, font := 30, border := Color(0.62, 0.48, 0.25)) -> Button:
	var b := Button.new()
	b.text = g.safe(text)
	b.position = pos
	b.size = sz
	b.custom_minimum_size = sz
	g._style(b, font, border)
	if cb.is_valid():
		b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _l(parent: Node, text: String, pos: Vector2, sz: Vector2, font := 28, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: Label = g._label(text, font)
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	parent.add_child(l)
	return l


# ================================================================ dice popup

func _build_popup(top: CanvasLayer) -> void:
	popup = Panel.new()
	popup.position = Vector2(60, 330)
	popup.size = Vector2(600, 560)
	popup.add_theme_stylebox_override("panel", g._parch_style(6))
	popup.visible = false
	top.add_child(popup)
	popup_die = Panel.new()
	popup_die.size = Vector2(150, 150)
	popup_die.position = Vector2(225, 30)
	popup_die.pivot_offset = Vector2(75, 75)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.93, 0.88)
	sb.border_color = Color(0.55, 0.12, 0.12)
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(28)
	popup_die.add_theme_stylebox_override("panel", sb)
	popup.add_child(popup_die)
	popup_num = Label.new()
	popup_num.size = Vector2(150, 150)
	popup_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_num.add_theme_font_size_override("font_size", 72)
	popup_num.add_theme_color_override("font_color", Color(0.55, 0.12, 0.12))
	popup_die.add_child(popup_num)
	var d20 := _l(popup, "d20  (tap to close)", Vector2(0, 186), Vector2(600, 30), 22, HORIZONTAL_ALIGNMENT_CENTER)
	d20.add_theme_color_override("font_color", Color(0.45, 0.3, 0.15))
	popup_text = _l(popup, "", Vector2(24, 222), Vector2(552, 320), 26, HORIZONTAL_ALIGNMENT_CENTER)
	var tap := Button.new()
	tap.flat = true
	tap.size = popup.size
	tap.pressed.connect(func(): popup_hold = minf(popup_hold, 0.01) if popup_t <= 0.0 else popup_hold)
	popup.add_child(tap)


## Big animated d20 for sneak, haggling, events, alliances.
func show_roll(c: Dictionary, msg: String) -> void:
	popup_final = int(c.get("roll", 1))
	popup_t = 0.8
	popup_hold = 4.5
	var head := str(c.get("what", ""))
	var line := Dice.text(c)
	var res := ""
	if c.has("win"):
		res = "Natural 20!  " if c.get("crit", false) else ""
		res += "Success!" if c["win"] else "Not this time."
	popup_text.text = g.safe(("%s\n%s  %s\n%s" % [head, line, res, msg]).strip_edges())
	popup.visible = true


## Small d20 chip for quick combat rolls.
func show_chip(roll: int, win: bool, crit := false) -> void:
	chip.text = g.safe("d20: %s %s" % [TavernSafe.number_text(roll), "CRIT!" if crit else ("Hit!" if win else "Miss")])
	chip.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if crit else (Color(0.7, 1.0, 0.6) if win else Color(1.0, 0.7, 0.5)))
	chip.visible = true
	chip_t = 0.9


func _process(delta: float) -> void:
	if chip_t > 0.0:
		chip_t -= delta
		chip.position.y = 600 - (0.9 - chip_t) * 40.0
		if chip_t <= 0.0:
			chip.visible = false
	if popup.visible:
		if popup_t > 0.0:
			popup_t -= delta
			popup_num.text = TavernSafe.number_text(randi_range(1, 20))
			popup_die.rotation = popup_t * 9.0
			if popup_t <= 0.0:
				popup_num.text = TavernSafe.number_text(popup_final)
				popup_die.rotation = 0.0
		else:
			popup_hold -= delta
			if popup_hold <= 0.0:
				popup.visible = false
	if creator and creator.visible and c_anim > 0.0:
		c_anim -= delta
		_creator_stats(c_anim > 0.0)


# ================================================================ creator

func open_creator() -> void:
	if creator == null:
		_build_creator()
	g._hide_hud(true)
	c_spawn = 0
	c_name = HeroClass.random_name(main.dice)
	c_cancel.visible = main.roster.heroes.size() > 0
	_pick_class(c_cls)
	creator.visible = true


func _build_creator() -> void:
	creator = _panel()
	_l(creator, "Make a New Hero", Vector2(20, 22), Vector2(560, 60), 44)
	c_cancel = _b(creator, "Back", Vector2(560, 18), Vector2(116, 70), close_creator, 26)
	c_name_label = _l(creator, "", Vector2(20, 100), Vector2(440, 60), 32)
	_b(creator, "New Name", Vector2(466, 94), Vector2(210, 74), func():
		c_name = HeroClass.random_name(main.dice)
		c_name_label.text = g.safe(c_name), 26)
	var x := 20
	for cls in ["mage", "thief", "warrior"]:
		var info: Dictionary = HeroClass.CLASSES[cls]
		var b := _b(creator, "%s\n(%s)" % [info["name"], info["move"]], Vector2(x, 186), Vector2(212, 140), _pick_class.bind(cls), 32, info["color"])
		c_class_btns[cls] = b
		x += 222
	c_blurb = _l(creator, "", Vector2(20, 336), Vector2(656, 96), 26)
	c_die_labels.clear()
	c_stat_labels.clear()
	for i in HeroClass.STATS.size():
		var y := 440 + i * 104
		var die := Panel.new()
		die.position = Vector2(30, y)
		die.size = Vector2(88, 88)
		die.pivot_offset = Vector2(44, 44)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.95, 0.93, 0.88)
		sb.border_color = Color(0.55, 0.12, 0.12)
		sb.set_border_width_all(5)
		sb.set_corner_radius_all(18)
		die.add_theme_stylebox_override("panel", sb)
		creator.add_child(die)
		var dn := Label.new()
		dn.size = Vector2(88, 88)
		dn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dn.add_theme_font_size_override("font_size", 42)
		dn.add_theme_color_override("font_color", Color(0.55, 0.12, 0.12))
		die.add_child(dn)
		c_die_labels.append(dn)
		c_stat_labels.append(_l(creator, "", Vector2(136, y + 6), Vector2(540, 80), 30))
	_b(creator, "Roll Again", Vector2(20, 868), Vector2(320, 100), _reroll, 34)
	c_spawn_btn = _b(creator, "", Vector2(356, 868), Vector2(320, 100), _cycle_spawn, 24)
	_b(creator, "Start Adventure!", Vector2(20, 1000), Vector2(656, 130), _confirm, 44, Color(0.85, 0.7, 0.3))
	_l(creator, "Every hero lives in the same world: same bank, villages, faith, and friends.", Vector2(20, 1140), Vector2(656, 90), 22, HORIZONTAL_ALIGNMENT_CENTER)


func _pick_class(cls: String) -> void:
	c_cls = cls
	for k in c_class_btns:
		var info: Dictionary = HeroClass.CLASSES[k]
		var on: bool = k == cls
		g._style(c_class_btns[k], 32, Color(1, 0.9, 0.5) if on else info["color"])
		c_class_btns[k].modulate = Color(1, 1, 1) if on else Color(0.75, 0.75, 0.75)
	var info: Dictionary = HeroClass.CLASSES[cls]
	c_blurb.text = g.safe("%s  Signature move: %s. %s" % [info["blurb"], info["move"], info["move_help"]])
	c_name_label.text = g.safe(c_name)
	_reroll()


func _reroll() -> void:
	c_roll = HeroClass.roll_stats(main.dice, c_cls)
	c_anim = 0.9
	_update_spawn_btn()


func _creator_stats(spinning: bool) -> void:
	for i in HeroClass.STATS.size():
		var s: String = HeroClass.STATS[i]
		var die: Panel = c_die_labels[i].get_parent()
		if spinning:
			c_die_labels[i].text = TavernSafe.number_text(randi_range(1, 20))
			die.rotation = c_anim * (8.0 + i)
			c_stat_labels[i].text = "%s  ..." % HeroClass.STAT_NAMES[s]
		else:
			die.rotation = 0.0
			var r: int = c_roll["rolls"][s]
			var base: int = HeroClass.CLASSES[c_cls]["base"][s]
			c_die_labels[i].text = TavernSafe.number_text(r)
			c_stat_labels[i].text = g.safe("%s  %s\n(rolled %s + %s for %s)" % [HeroClass.STAT_NAMES[s], TavernSafe.number_text(int(c_roll["stats"][s])), TavernSafe.number_text(r), TavernSafe.number_text(base), HeroClass.CLASSES[c_cls]["name"]])


func _cycle_spawn() -> void:
	c_spawn = (c_spawn + 1) % (1 + main.realm.villages.size())
	_update_spawn_btn()


func _update_spawn_btn() -> void:
	var has_hero: bool = main.roster.heroes.size() > 0
	c_spawn_btn.visible = has_hero
	if not has_hero:
		return
	if c_spawn == 0 or c_spawn > main.realm.villages.size():
		c_spawn = 0
		c_spawn_btn.text = "Start: next to\n%s" % g.safe(main.roster.cur()["name"])
	else:
		c_spawn_btn.text = g.safe("Start: in\n%s" % main.realm.villages[c_spawn - 1]["name"])


func _confirm() -> void:
	creator.visible = false
	g._hide_hud(false)
	main.create_hero(c_name, c_cls, c_roll["stats"], c_spawn - 1)


func close_creator() -> void:
	creator.visible = false
	g._hide_hud(false)


# ================================================================ realm book

func open_book(which := "") -> void:
	if which != "":
		tab = which
	if book == null:
		book = _panel()
		var x := 12
		for t in [["heroes", "Heroes"], ["land", "Land"], ["faith", "Faith"], ["allies", "Allies"], ["shop", "Shop"], ["setup", "Setup"]]:
			_b(book, t[1], Vector2(x, 16), Vector2(106, 84), _tab.bind(t[0]), 22)
			x += 112
		var sc := ScrollContainer.new()
		sc.position = Vector2(20, 112)
		sc.size = Vector2(656, 1010)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		book.add_child(sc)
		body = VBoxContainer.new()
		body.custom_minimum_size = Vector2(640, 0)
		body.add_theme_constant_override("separation", 12)
		sc.add_child(body)
		_b(book, "Close", Vector2(20, 1140), Vector2(656, 100), close_book, 36)
	g._hide_hud(true)
	book.visible = true
	refresh()


func close_book() -> void:
	book.visible = false
	g._hide_hud(false)
	main.save_game()


func _tab(t: String) -> void:
	tab = t
	refresh()


func _txt(s: String, font := 28) -> void:
	body.add_child(g._label(s, font))


func _row(s: String, cb: Callable, font := 28) -> Button:
	var b: Button = g._row_btn(s, cb, 84, font)
	body.add_child(b)
	return b


func _say(msg: String) -> void:
	main.toast(msg)
	main.after_realm_change()
	refresh()


func refresh() -> void:
	if body == null:
		return
	g._clear(body)
	match tab:
		"heroes": _heroes()
		"land": _land()
		"faith": _faith()
		"allies": _allies()
		"setup": _setup()
		_: _shop()


func _hero_line(h: Dictionary) -> String:
	var st: Dictionary = h["stats"]
	return "%s - %s, Level %s\nMight %s  Sneak %s  Magic %s  Heart %s" % [h["name"], HeroClass.CLASSES[h["cls"]]["name"],
		TavernSafe.number_text(int(h["level"])), TavernSafe.number_text(int(st["might"])), TavernSafe.number_text(int(st["sneak"])),
		TavernSafe.number_text(int(st["magic"])), TavernSafe.number_text(int(st["heart"]))]


func _heroes() -> void:
	var ro = main.roster
	var me: Dictionary = ro.cur()
	_txt("Playing now:", 24)
	_txt(_hero_line(me) + "\nXP %s of %s.  Purse %s coins." % [TavernSafe.number_text(int(me["xp"])), TavernSafe.number_text(ro.xp_needed(int(me["level"]))), TavernSafe.number_text(main.bank.purse)], 28)
	_row("+ Make a New Hero", func():
		close_book()
		open_creator(), 32)
	if ro.heroes.size() > 1:
		_txt("Your other heroes (same world):", 24)
	for i in ro.heroes.size():
		if i == ro.active:
			continue
		var h: Dictionary = ro.heroes[i]
		_txt(_hero_line(h) + ("   (in your party)" if i == ro.buddy else ""), 26)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		body.add_child(hb)
		hb.add_child(g._row_btn("Play as", func():
			main.switch_to(i)
			refresh(), 84, 26))
		hb.add_child(g._row_btn("Leave party" if i == ro.buddy else "Party up", func():
			main.set_buddy(-1 if i == ro.buddy else i)
			refresh(), 84, 26))
	var pal: Dictionary = ro.pal()
	if not pal.is_empty():
		_txt("Party: %s %s you and fights beside you." % [pal["name"], "follows" if ro.follow else "waits for"], 26)
		_row("Give 10 coins to %s" % pal["name"], func(): _say(ro.give_coins(main.bank, ro.buddy, 10)))
		_row("Give a gear piece to %s" % pal["name"], func():
			var m: String = ro.give_gear(ro.buddy, main.wardrobe.equipped)
			main.rebuild_hero()
			main.rebuild_buddy()
			_say(m))
		_row("Follow me: %s" % ("ON" if ro.follow else "OFF"), func():
			ro.follow = not ro.follow
			refresh())


func _land() -> void:
	var re = main.realm
	var hp: Vector3 = main.hero.global_position
	var vi: int = re.nearest_village(hp.x, hp.z, 18.0)
	if vi >= 0:
		var v: Dictionary = re.villages[vi]
		_txt("%s (%s)\nPeople %s   Chest %s coins\nHall %s  Homes %s  Market %s  Shrine %s" % [v["name"], v["tier"],
			TavernSafe.number_text(int(v["pop"])), TavernSafe.number_text(int(v["gold"])),
			"yes" if v["hall"] else "no", TavernSafe.number_text(int(v["homes"])), "yes" if v["market"] else "no", "yes" if v["shrine"] else "no"], 28)
		if v["tier"] == "Village":
			_txt("Becomes a Town at %s people with a hall and a market." % TavernSafe.number_text(re.TOWN_POP), 22)
		for w in [["hall", "Build Town Hall"], ["home", "Build a Home"], ["market", "Build a Market"], ["shrine", "Build a Shrine"]]:
			_row("%s (%s coins)" % [w[1], TavernSafe.number_text(int(re.COST[w[0]]))], func():
				var r: Dictionary = re.build(main.bank, vi, w[0])
				_say(r["msg"]))
		_row("Collect gifts from the chest", func(): _say(re.collect(main.bank, vi)))
	else:
		var why: String = re.can_found_at(hp.x, hp.z)
		if new_village_name == "":
			new_village_name = re.village_name(name_rng)
		if why == "":
			_txt("Found a new village right here:\n%s" % new_village_name, 30)
			_row("New Name", func():
				new_village_name = re.village_name(name_rng)
				refresh())
			_row("Found %s (%s coins)" % [new_village_name, TavernSafe.number_text(int(re.COST["village"]))], func():
				var r: Dictionary = re.found_village(main.bank, new_village_name, hp.x, hp.z)
				if r["ok"]:
					new_village_name = ""
					main.add_xp(15)
				_say(r["msg"]), 30)
		else:
			_txt(why, 28)
			_row("Take the road to the open land", func():
				close_book()
				main.travel(Vector3(0, 1, 52), "You followed the north road out of the city. Wide open land!", PI), 30)
	if main.overworld and not main.overworld.in_city(hp.x, hp.z):
		_row("Go back to Port Paradise", func():
			close_book()
			main.travel(Vector3(0, 1, 2), "Home to Port Paradise."), 26)
	if not re.villages.is_empty():
		_txt("Your villages and towns (tap to travel):", 24)
		for v in re.villages:
			_row("%s (%s): %s people" % [v["name"], v["tier"], TavernSafe.number_text(int(v["pop"]))], func():
				close_book()
				main.travel(Vector3(float(v["x"]) + 2.0, 1, float(v["z"]) + 7.0), "Welcome to %s!" % v["name"]), 24)


func _faith() -> void:
	var re = main.realm
	if not re.religion.is_empty():
		var r: Dictionary = re.religion
		var bl: Dictionary = re.BLESSINGS[r["blessing"]]
		_txt("%s\nVirtue: %s\n%s: %s\nFollowers: %s   Shrines: %s" % [r["name"], r["virtue"], bl["name"], bl["help"],
			TavernSafe.number_text(int(r["followers"])), TavernSafe.number_text(re.shrines())], 30)
		_txt("Build shrines in your villages to bring more followers each day.", 24)
		return
	if faith_name == "":
		faith_name = re.faith_name(name_rng)
	_txt("Found a Religion for your family", 30)
	_txt("Name: %s" % faith_name, 28)
	_row("New Name", func():
		faith_name = re.faith_name(name_rng)
		refresh())
	_row("Virtue: %s  (tap to change)" % re.VIRTUES[faith_virtue], func():
		faith_virtue = (faith_virtue + 1) % re.VIRTUES.size()
		refresh())
	_txt("Pick a blessing:", 24)
	for k in re.BLESSINGS.keys():
		var bl: Dictionary = re.BLESSINGS[k]
		var b := _row(("> " if k == faith_blessing else "") + "%s: %s" % [bl["name"], bl["help"]], func():
			faith_blessing = k
			refresh(), 22)
		if k == faith_blessing:
			g._style(b, 22, Color(1, 0.9, 0.5))
	_row("Found %s" % faith_name, func():
		var r: Dictionary = re.found_religion(faith_name, re.VIRTUES[faith_virtue], faith_blessing)
		if r["ok"]:
			main.add_xp(15)
		_say(r["msg"]), 30)


func _allies() -> void:
	var re = main.realm
	_txt("Make friends with the folk of the land. Roll d20 + Heart. Each try makes them like you more.", 24)
	for i in re.factions.size():
		var f: Dictionary = re.factions[i]
		var p: Dictionary = re.perk_info(str(f["perk"]))
		_txt("%s - %s, need %s, friendship %s\nGift if allied: %s (%s)" % [f["name"], f["mood"], TavernSafe.number_text(int(f["need"])),
			TavernSafe.number_text(int(f["rep"])), p["name"], p["help"]], 24)
		if f["allied"]:
			_txt("ALLIES!", 28)
		else:
			_row("Offer Alliance", func():
				var c: Dictionary = re.offer_alliance(main.dice, i, main.roster.bonus("heart"), main.clock.day)
				if c.has("roll"):
					show_roll(c, c["msg"])
					if c["win"]:
						main.add_xp(20)
					main.after_realm_change()
					refresh()
				else:
					_say(c["msg"]))


func _shop() -> void:
	var b = main.bank
	_txt("Family Bank (shared by every hero)\nPurse %s   Savings %s   Loan %s\nSavings earn 1 coin for every 100 each day, and more each season." % [
		TavernSafe.number_text(b.purse), TavernSafe.number_text(b.savings), TavernSafe.number_text(b.loan)], 26)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	body.add_child(hb)
	hb.add_child(g._row_btn("Save 10", func(): _say(b.deposit(10)), 84, 28))
	hb.add_child(g._row_btn("Take 10", func(): _say(b.withdraw(10)), 84, 28))
	var base := 8 if main.realm.has_perk("arrows") else 12
	var price := haggle_price if haggle_price >= 0 else base
	_txt("Arrow Seller: 6 bone arrows for %s coins. You have %s arrows." % [TavernSafe.number_text(price), TavernSafe.number_text(main.arrows)], 26)
	if haggle_price < 0:
		_row("Haggle (roll d20 + Sneak)", func():
			var c: Dictionary = main.dice.check(main.roster.bonus("sneak") + main.realm.luck(), 12, "Haggling for arrows")
			haggle_price = maxi(3, base / 2) if c["win"] else base
			show_roll(c, "Deal! Half price." if c["win"] else "The seller smiles and keeps the price.")
			refresh())
	_row("Buy 6 arrows", func():
		if b.purse < price:
			_say("That's %s coins. You have %s. Pop some bugs and come back!" % [TavernSafe.number_text(price), TavernSafe.number_text(b.purse)])
			return
		b.spend(price, "6 bone arrows")
		main.arrows = mini(60, main.arrows + 6)
		haggle_price = -1
		_say("Six new bone arrows in your quiver. Happy hunting!"))


func _setup() -> void:
	var q = main.quality
	_txt("Picture quality\nNow: %s%s" % [q.mode.capitalize(), "  (Auto picks for this device)" if q.choice == "auto" else ""], 30)
	for m in [["auto", "Auto (best for this device)"], ["low", "Low: smoothest on small phones"], ["med", "Medium"], ["high", "High: prettiest"]]:
		var b := _row(("> " if q.choice == m[0] else "") + m[1], func():
			q.set_choice(m[0])
			refresh(), 26)
		if q.choice == m[0]:
			g._style(b, 26, Color(1, 0.9, 0.5))
	_row("Speed readout (FPS): %s" % ("ON" if q.show_fps else "OFF"), func():
		q.toggle_fps()
		refresh(), 26)
	_txt("Low draws fewer people and a shorter view so the game stays smooth.", 22)
