extends RefCounted
## Casa O'Faydin dice: a seeded d20 (and friends) for every check in the game.
## House rule: the forbidden triple-six run never shows. Seeds that contain it
## are nudged, and every number shown goes through TavernSafe.

var rng := RandomNumberGenerator.new()
var seed_value := 1
var last: Dictionary = {}


static func safe_seed(s: int) -> int:
	s = absi(s)
	if s == 0:
		s = 1
	while TavernSafe.contains_forbidden(str(s)):
		s += 1
	return s


func set_seed(s: int) -> void:
	seed_value = safe_seed(s)
	rng.seed = seed_value


func new_seed() -> int:
	var r := RandomNumberGenerator.new()
	r.randomize()
	set_seed(int(r.randi() % 900000) + 100000)
	return seed_value


func die(sides: int) -> int:
	return rng.randi_range(1, maxi(2, sides))


func d20() -> int:
	return die(20)


## A check: d20 + bonus vs a target. A natural 20 always wins, a natural 1 always misses.
func check(bonus: int, target: int, what := "") -> Dictionary:
	var r := d20()
	var total := r + bonus
	var win := total >= target
	if r == 20:
		win = true
	elif r == 1:
		win = false
	last = {"roll": r, "bonus": bonus, "total": total, "target": target, "win": win,
		"crit": r == 20, "oops": r == 1, "what": what}
	return last


static func text(c: Dictionary) -> String:
	var n := func(v: int) -> String: return TavernSafe.number_text(v)
	var b: int = int(c.get("bonus", 0))
	var s := "Rolled %s" % n.call(int(c.get("roll", 0)))
	if b != 0:
		s += " %s %s = %s" % ["+" if b > 0 else "-", n.call(absi(b)), n.call(int(c.get("total", 0)))]
	if c.has("target"):
		s += "  (need %s)" % n.call(int(c["target"]))
	return s


## Pick from an array with this dice's RNG.
func pick(a: Array):
	if a.is_empty():
		return null
	return a[rng.randi() % a.size()]
