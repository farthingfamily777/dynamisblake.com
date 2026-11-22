extends SceneTree
## Headless checks for dice, hero classes, the roster, founding, and alliances.
## /tmp/Godot_v4.3-stable_linux.x86_64 --headless --path . --script res://scripts/fun_tests.gd

const Dice = preload("res://scripts/dice.gd")
const HeroClass = preload("res://scripts/hero_class.gd")
const Roster = preload("res://scripts/roster.gd")
const Realm = preload("res://scripts/realm.gd")
const Bank = preload("res://scripts/bank.gd")
var passed := 0
var failed := 0

func ok(c: bool, name: String) -> void:
	if c:
		passed += 1; print("  PASS  ", name)
	else:
		failed += 1; print("  FAIL  ", name)

func _init() -> void:
	var bad := "6".repeat(3)
	# --- dice
	var d := Dice.new(); d.set_seed(int(bad + "1"))
	ok(not TavernSafe.contains_forbidden(str(d.seed_value)), "seed with forbidden run is nudged")
	var lo := 99; var hi := 0
	for i in 2000:
		var r: int = d.d20(); lo = mini(lo, r); hi = maxi(hi, r)
	ok(lo == 1 and hi == 20, "d20 covers 1..20")
	var d2 := Dice.new(); d2.set_seed(4242)
	var d3 := Dice.new(); d3.set_seed(4242)
	var same := true
	for i in 50: same = same and d2.d20() == d3.d20()
	ok(same, "same seed, same rolls")
	var nat20 := false; var nat1 := false
	for i in 500:
		var c: Dictionary = d.check(-50, 10)
		if c["roll"] == 20: nat20 = nat20 or c["win"]
		if c["roll"] == 1: nat1 = nat1 or c["win"]
	ok(nat20 and not nat1, "natural 20 always wins, natural 1 always misses")
	ok(not TavernSafe.contains_forbidden(Dice.text({"roll": 6, "bonus": 660, "total": int(bad), "target": 7})), "dice text never shows the forbidden run")
	# --- classes
	for cls in ["mage", "thief", "warrior"]:
		var st: Dictionary = HeroClass.roll_stats(d, cls)
		var good := true
		for s in HeroClass.STATS:
			var base: int = HeroClass.CLASSES[cls]["base"][s]
			good = good and st["stats"][s] == st["rolls"][s] + base and st["rolls"][s] >= 1 and st["rolls"][s] <= 20
		ok(good, cls + ": stats = d20 + class base")
	ok(HeroClass.CLASSES["mage"]["weapon"] == "staff" and HeroClass.CLASSES["thief"]["weapon"] == "crossbow" and HeroClass.CLASSES["warrior"]["weapon"] == "sword", "class kits: staff, crossbow, sword")
	# --- roster
	var b := Bank.new(); b.load_config()
	var ro := Roster.new()
	var v := ro.add_hero("Vet", "warrior", {"might": 20, "sneak": 5, "magic": 3, "heart": 12})
	ro.heroes[v]["level"] = 80
	var nb := ro.add_hero("Newbie", "thief", {"might": 5, "sneak": 15, "magic": 3, "heart": 8})
	ro.active = v; ro.buddy = nb
	b.purse = 100
	ro.give_coins(b, nb, 30)
	ok(b.purse == 70 and ro.heroes[nb]["purse"] == 55, "veteran gives 30 coins to the newbie")
	var g: Dictionary = ro.heroes[v]["gear"]
	var before := g.size()
	ro.heroes[nb]["gear"].erase("head")
	var msg := ro.give_gear(nb, g)
	ok(g.size() == before - 1 and ro.heroes[nb]["gear"].has("head"), "veteran hands gear to the newbie: " + msg)
	ok(ro.add_xp(nb, 40) >= 1 and ro.heroes[nb]["level"] >= 2, "xp levels a hero up")
	ok(ro.heroes.size() == 2, "both heroes share one world roster")
	# --- realm: founding
	var re := Realm.new(); re.setup(1234)
	ok(not re.found_village(b, "Inside", 0, 0)["ok"], "cannot found inside the city")
	b.purse = 5
	ok(not re.found_village(b, "Poorbrook", 80, 60)["ok"] and re.villages.is_empty(), "founding waits for 20 coins")
	b.purse = 500
	var fv: Dictionary = re.found_village(b, "Oakford", 80, 60)
	ok(fv["ok"] and re.villages.size() == 1 and b.purse == 480, "found a village for 20 coins")
	ok(not re.found_village(b, "Twin", 85, 62)["ok"], "no village right next to another")
	var i := re.nearest_village(81, 61)
	re.build(b, i, "hall"); re.build(b, i, "market"); re.build(b, i, "shrine")
	for k in 6: re.build(b, i, "home")
	ok(re.villages[0]["hall"] and re.villages[0]["market"] and re.villages[0]["homes"] == 6, "build hall, market, shrine, homes")
	ok(re.villages[0]["tier"] == "Town", "village grows into a Town (pop %d)" % re.villages[0]["pop"])
	re.on_day(3)
	ok(re.villages[0]["gold"] > 0 and re.last_day == 3, "days fill the village chest")
	var p0 := b.purse
	re.collect(b, i)
	ok(b.purse > p0, "collect village gifts into purse")
	# --- religion
	var fr: Dictionary = re.found_religion("The Way of the Dawn", "Kindness", "luck")
	ok(fr["ok"] and re.has_blessing("luck") and re.luck() >= 1, "found a religion with a blessing")
	ok(not re.found_religion("Second", "Joy", "coin")["ok"], "one family religion")
	re.on_day(4)
	ok(re.religion["followers"] > 3, "shrines bring followers")
	# --- alliances
	ok(re.factions.size() == 5, "5 procedural factions")
	var names := {}
	for f in re.factions:
		names[f["name"]] = true
		ok(not TavernSafe.contains_forbidden(f["name"]), "faction name safe: " + f["name"])
	var re2 := Realm.new(); re2.setup(1234)
	ok(re2.factions[0]["name"] == re.factions[0]["name"], "same seed, same factions")
	var dd := Dice.new(); dd.set_seed(77)
	var c1: Dictionary = re.offer_alliance(dd, 0, 0, 4)
	var c2: Dictionary = re.offer_alliance(dd, 0, 0, 4)
	ok(not c2.get("ok", true) or c1["win"], "one offer per faction per day")
	var won := false
	for day in range(5, 60):
		var c: Dictionary = re.offer_alliance(dd, 1, 3, day)
		if c.get("win", false):
			won = true
			break
	ok(won and re.factions[1]["allied"], "an alliance forms on a dice roll + reputation")
	ok(re.has_perk(str(re.factions[1]["perk"])), "allies give a perk")
	var re3 := Realm.new(); re3.from_dict(JSON.parse_string(JSON.stringify(re.to_dict())))
	ok(re3.villages.size() == 1 and re3.religion["name"] == re.religion["name"] and re3.factions[1]["allied"], "realm saves and loads")
	# --- bank daily interest
	var bk := Bank.new(); bk.load_config(); bk.savings = 300
	bk.on_day(); ok(bk.savings == 303, "daily interest: 1 coin per 100 saved")
	print("\nRESULTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
