extends SceneTree
## Headless checks for the bank, world clock, and wardrobe.
## /tmp/Godot_v4.3-stable_linux.x86_64 --headless --path . --script res://scripts/bank_tests.gd

const Bank = preload("res://scripts/bank.gd")
const WorldClock = preload("res://scripts/world_clock.gd")
const Wardrobe = preload("res://scripts/wardrobe.gd")
var passed := 0
var failed := 0

func ok(c: bool, name: String) -> void:
	if c:
		passed += 1; print("  PASS  ", name)
	else:
		failed += 1; print("  FAIL  ", name)

func _init() -> void:
	var b := Bank.new(); b.load_config()
	ok(b.purse == 50, "starting purse 50")
	b.deposit(30); ok(b.purse == 20 and b.savings == 30, "deposit 30")
	b.withdraw(10); ok(b.purse == 30 and b.savings == 20, "withdraw 10")
	b.deposit(999); ok(b.purse == 0 and b.savings == 50, "deposit caps at purse")
	b.borrow(100); ok(b.loan == 100 and b.purse == 100, "borrow 100")
	b.borrow(500); ok(b.loan == 200, "loan capped at max_loan")
	b.on_season("Summer"); ok(b.savings == 51 and b.loan == 210, "season interest: savings +2%, loan +5%")
	b.on_season("Harvest"); ok(b.savings == 52 and b.loan == 221, "compounds on new balance")
	b.purse = 300
	b.repay(1000); ok(b.loan == 0 and b.purse == 79, "repay caps at loan")
	ok(b.ledger.size() <= 6, "ledger stays short")
	b.purse = 600 + 66
	ok(not TavernSafe.contains_forbidden(b.deposit(0) + b.earn(0, "x") + "Coins %s" % TavernSafe.number_text(b.purse)), "no forbidden run in purse text")
	var c := WorldClock.new(); c.load_config()
	ok(is_equal_approx(c.real_seconds_per_hour, 1200.0), "1 game hour = 20 real minutes")
	c.tick(1200.0); ok(absf(c.hour - 8.2) < 0.001, "20 real minutes adds one hour")
	var seasons := 0
	for i in 7: seasons += c.sleep()
	ok(seasons == 1 and c.season_name() == "Summer", "7 sleeps start Summer")
	var w := Wardrobe.new(); w.load_config()
	ok(w.slots.size() == 15, "15 gear slots")
	var types := {}
	for s in w.slots: types[s["type"]] = w.items_for(s["slot"]).size()
	var all5 := true
	for k in types: all5 = all5 and types[k] == 5
	ok(types.size() == 12 and all5, "12 clothing types x 5 items")
	w.strip_all(); ok(w.worn_count() == 0, "take all off")
	w.dress_me(); ok(w.worn_count() == 15, "dress me fills every slot")
	print("\nRESULTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
