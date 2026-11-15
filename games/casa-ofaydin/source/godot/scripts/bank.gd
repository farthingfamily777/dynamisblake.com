extends RefCounted
## Harbor Counting House: coin purse, savings, one simple loan, seasonal interest.
## Settings in res://data/bank.json. Engine rules stay here (see modding-tools-v0.1.md).
## Every number shown goes through TavernSafe so the house-forbidden run never appears.

var cfg: Dictionary = {}
var purse := 0
var savings := 0
var loan := 0
var ledger: Array = []   # newest first, plain words


func load_config(path := "res://data/bank.json") -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			cfg = d
	purse = int(cfg.get("starting_purse", 50))


func n(v: int) -> String:
	return TavernSafe.number_text(v)


func savings_rate() -> int:
	return int(cfg.get("savings_rate_percent", 2))


func loan_rate() -> int:
	return int(cfg.get("loan_rate_percent", 5))


func max_loan() -> int:
	return int(cfg.get("max_loan", 200))


func can_borrow() -> int:
	return maxi(0, max_loan() - loan)


func _log(s: String) -> void:
	ledger.push_front(s)
	var keep := int(cfg.get("ledger_size", 6))
	while ledger.size() > keep:
		ledger.pop_back()


func earn(amount: int, why: String) -> String:
	if amount <= 0:
		return ""
	purse += amount
	_log("+%s coins: %s" % [n(amount), why])
	return "+%s coins" % n(amount)


func spend(amount: int, why: String) -> int:
	var paid := mini(amount, purse)
	if paid > 0:
		purse -= paid
		_log("-%s coins: %s" % [n(paid), why])
	return paid


func deposit(amount: int) -> String:
	amount = mini(amount, purse)
	if amount <= 0:
		return "Your purse is empty right now. Pop some bugs with Lux to earn coins."
	purse -= amount
	savings += amount
	_log("Saved %s coins" % n(amount))
	return "Saved %s coins. They will grow a little each season." % n(amount)


func withdraw(amount: int) -> String:
	amount = mini(amount, savings)
	if amount <= 0:
		return "Nothing saved yet. Your savings are at 0."
	savings -= amount
	purse += amount
	_log("Took out %s coins" % n(amount))
	return "Here are %s coins for your purse." % n(amount)


func borrow(amount: int) -> String:
	amount = mini(amount, can_borrow())
	if amount <= 0:
		return "The house can lend up to %s coins at a time. Pay some back first." % n(max_loan())
	loan += amount
	purse += amount
	_log("Borrowed %s coins" % n(amount))
	return "You borrowed %s coins. It grows %s for every 100 each season until paid back." % [n(amount), n(loan_rate())]


func repay(amount: int) -> String:
	amount = mini(amount, mini(purse, loan))
	if loan <= 0:
		return "You don't owe the house anything."
	if amount <= 0:
		return "Your purse is empty right now."
	purse -= amount
	loan -= amount
	_log("Paid back %s coins" % n(amount))
	if loan == 0:
		return "All paid back. Nice work!"
	return "Paid back %s coins. Still owed: %s." % [n(amount), n(loan)]


func _interest(balance: int, rate: int) -> int:
	if balance <= 0:
		return 0
	# Round half up, at least 1 coin so growth is visible on small balances.
	return maxi(1, int(floor(float(balance) * float(rate) / 100.0 + 0.5)))


## Called once each time a new season begins. Compound: interest joins the balance.
func on_season(season_name: String) -> String:
	var parts: Array = []
	var gain := _interest(savings, savings_rate())
	if gain > 0:
		savings += gain
		_log("%s interest: savings +%s" % [season_name, n(gain)])
		parts.append("your savings grew by %s coins" % n(gain))
	var cost := _interest(loan, loan_rate())
	if cost > 0:
		loan += cost
		_log("%s interest: loan +%s" % [season_name, n(cost)])
		parts.append("your loan grew by %s coins" % n(cost))
	if parts.is_empty():
		return ""
	return "%s is here: %s." % [season_name, " and ".join(parts)]


func to_dict() -> Dictionary:
	return {"purse": purse, "savings": savings, "loan": loan, "ledger": ledger}


func from_dict(d: Dictionary) -> void:
	purse = maxi(0, int(d.get("purse", purse)))
	savings = maxi(0, int(d.get("savings", savings)))
	loan = maxi(0, int(d.get("loan", loan)))
	ledger = d.get("ledger", ledger)
