extends RefCounted
class_name TavernAI
## Easy, medium, and hard computer opponents for the tavern games.
## Level can be set on the character as ai_level or skill, or inferred
## from the character's class. Hard chess uses a shallow alpha-beta search
## (default depth 2, optional 3) and is synchronous so it stays safe in a
## web / Compatibility export with threads off.

const EASY := 0
const MEDIUM := 1
const HARD := 2

var chess_hard_depth: int = 2
var checkers_hard_depth: int = 4
var rng := RandomNumberGenerator.new()

# Material values used by the chess search, in centipawns.
const VAL := {
	1: 100, 2: 320, 3: 330, 4: 500, 5: 900, 6: 0,
	9: 100, 10: 320, 11: 330, 12: 500, 13: 900, 14: 0
}

func _init() -> void:
	rng.randomize()


func set_seed(s: int) -> void:
	rng.seed = s


## Resolve easy / medium / hard from a character record.
## Reads the arrival-forms record (class_id, plus optional ai_level or skill).
## A minimal {id, name, class, race} record still works.
static func level_for(character: Dictionary) -> int:
	if character.has("ai_level"):
		return parse_level(character["ai_level"])
	if character.has("skill"):
		var s := int(character["skill"])
		if s <= 4:
			return EASY
		if s <= 7:
			return MEDIUM
		return HARD
	# Arrival-forms store the class as class_id (class is reserved in GDScript).
	# A bare "class" key is still accepted if an older record has one.
	var job := str(character.get("class_id", character.get("class", ""))).to_lower()
	# Thinkers and traders play a sharper table game.
	if job in ["sage", "mage", "wizard", "merchant", "governor", "scholar"]:
		return HARD
	# Wanderers, fighters, and the other starting classes play a fair mid-strength game.
	if job in ["pilgrim", "fighter", "soldier", "ork", "starship trooper", "trooper", "thief", "assassin", "rogue", "vampire"]:
		return MEDIUM
	# Brand-new or simple roles stay easy so kids can win often.
	if job in ["child", "beginner", "farmer", "bandit"]:
		return EASY
	return MEDIUM


static func parse_level(v) -> int:
	if v is int or v is float:
		var n := int(v)
		if n <= 0:
			return EASY
		if n == 1:
			return MEDIUM
		return HARD
	var s := str(v).to_lower()
	if s in ["easy", "e", "low", "soft"]:
		return EASY
	if s in ["hard", "h", "high", "expert"]:
		return HARD
	return MEDIUM


static func level_name(level: int) -> String:
	if level <= EASY:
		return "easy"
	if level == MEDIUM:
		return "medium"
	return "hard"


func choose_chess(rules: ChessRules, level: int) -> Dictionary:
	var moves: Array = rules.legal_moves()
	if moves.is_empty():
		return {}
	if level <= EASY:
		return moves[rng.randi_range(0, moves.size() - 1)]
	if level == MEDIUM:
		return _pick_best(moves, func(m): return _chess_one_ply(rules, m), 15)
	# Hard: alpha-beta
	var depth := chess_hard_depth
	if depth < 1:
		depth = 1
	if depth > 3:
		depth = 3
	var best_moves: Array = []
	var best_sc := -999999
	var color_sign := 1 if rules.white_to_move else -1
	for m in moves:
		var packed: int = rules._dict_to_packed(m)
		rules._apply(packed)
		var sc: int = -_chess_search(rules, depth - 1, -999999, 999999)
		rules._unapply()
		# Score is from the mover's point of view after the sign flip inside search
		# _chess_search returns a score for the side about to move, in White-positive
		# wait: we need consistency. See _chess_search.
		# After apply, we search for the opponent; we negate. So sc is mover-centric
		# if _chess_search returns side-to-move centric. Good.
		if sc > best_sc:
			best_sc = sc
			best_moves = [m]
		elif sc == best_sc:
			best_moves.append(m)
	if best_moves.is_empty():
		return moves[0]
	return best_moves[rng.randi_range(0, best_moves.size() - 1)]


func _chess_one_ply(rules: ChessRules, move: Dictionary) -> int:
	var packed: int = rules._dict_to_packed(move)
	if packed < 0:
		return -999999
	rules._apply(packed)
	var sc := _chess_eval(rules)
	if not rules.white_to_move:
		# After White moves, black to move: eval is white-positive, White wants high.
		pass
	else:
		# After Black moves, invert so the mover's score is high-is-good.
		sc = -sc
	# Prefer checking the opponent a little.
	if rules.in_checkmate():
		sc += 50000
	elif rules.in_check():
		sc += 30
	rules._unapply()
	return sc


func _chess_search(rules: ChessRules, depth: int, alpha: int, beta: int) -> int:
	# Returns a score from the side-to-move's point of view (high is good for them).
	if rules.in_checkmate():
		return -100000 - depth
	if rules.is_draw():
		return 0
	if depth <= 0:
		var ev := _chess_eval(rules)
		return ev if rules.white_to_move else -ev
	var moves: Array = rules._gen_legal_ints()
	if moves.is_empty():
		if rules.in_check():
			return -100000 - depth
		return 0
	_order_chess_moves(rules, moves)
	var best := -999999
	for packed in moves:
		rules._apply(packed)
		var sc: int = -_chess_search(rules, depth - 1, -beta, -alpha)
		rules._unapply()
		if sc > best:
			best = sc
		if sc > alpha:
			alpha = sc
		if alpha >= beta:
			break
	return best


func _order_chess_moves(rules: ChessRules, moves: Array) -> void:
	# Captures and promotions first, which makes alpha-beta cut more often.
	moves.sort_custom(func(a: int, b: int) -> bool:
		var fa: int = a >> 16
		var fb: int = b >> 16
		var sa := (2 if (fa & ChessRules.FLAG_PROMO) else 0) + (1 if (fa & ChessRules.FLAG_CAPTURE) else 0)
		var sb := (2 if (fb & ChessRules.FLAG_PROMO) else 0) + (1 if (fb & ChessRules.FLAG_CAPTURE) else 0)
		return sa > sb
	)


func _chess_eval(rules: ChessRules) -> int:
	# White-positive material plus a light placement bonus.
	var score := 0
	for sq in 64:
		var p: int = rules.board[sq]
		if p == 0:
			continue
		var v: int = int(VAL.get(p, 0))
		var r := int(sq / 8)
		var f := sq % 8
		if p == ChessRules.W_PAWN:
			v += r * 4
		elif p == ChessRules.B_PAWN:
			v += (7 - r) * 4
		elif p == ChessRules.W_KNIGHT or p == ChessRules.W_BISHOP:
			if r >= 2 and r <= 5 and f >= 2 and f <= 5:
				v += 8
		elif p == ChessRules.B_KNIGHT or p == ChessRules.B_BISHOP:
			if r >= 2 and r <= 5 and f >= 2 and f <= 5:
				v += 8
		if rules._is_white_piece(p):
			score += v
		else:
			score -= v
	return score


func choose_checkers(rules: CheckersRules, level: int) -> Dictionary:
	var moves: Array = rules.legal_moves()
	if moves.is_empty():
		return {}
	if level <= EASY:
		return moves[rng.randi_range(0, moves.size() - 1)]
	if level == MEDIUM:
		return _pick_best(moves, func(m): return _checkers_one_ply(rules, m), 8)
	var depth := checkers_hard_depth
	if depth < 1:
		depth = 1
	if depth > 5:
		depth = 5
	var best_moves: Array = []
	var best_sc := -999999
	for m in moves:
		rules.make_move(m)
		var sc: int = -_checkers_search(rules, depth - 1, -999999, 999999)
		rules.undo()
		if sc > best_sc:
			best_sc = sc
			best_moves = [m]
		elif sc == best_sc:
			best_moves.append(m)
	if best_moves.is_empty():
		return moves[0]
	return best_moves[rng.randi_range(0, best_moves.size() - 1)]


func _checkers_one_ply(rules: CheckersRules, move: Dictionary) -> int:
	var whose: int = rules.turn
	rules.make_move(move)
	var sc := _checkers_eval(rules, whose)
	rules.undo()
	return sc


func _checkers_search(rules: CheckersRules, depth: int, alpha: int, beta: int) -> int:
	if rules.game_over():
		# Side to move lost, so this is bad for them.
		return -10000 - depth
	if depth <= 0:
		return _checkers_eval(rules, rules.turn)
	var moves: Array = rules.legal_moves()
	# Captures are already forced, so the list is uniform in type.
	var best := -999999
	for m in moves:
		rules.make_move(m)
		var sc: int = -_checkers_search(rules, depth - 1, -beta, -alpha)
		rules.undo()
		if sc > best:
			best = sc
		if sc > alpha:
			alpha = sc
		if alpha >= beta:
			break
	return best


func _checkers_eval(rules: CheckersRules, for_color: int) -> int:
	var score := 0
	for r in 8:
		for c in 8:
			var p: int = rules.board[r][c]
			if p == 0:
				continue
			var side := 1 if p > 0 else -1
			var val := 150 if absi(p) == 2 else 100
			# Advancement for men.
			if p == CheckersRules.RED:
				val += (7 - r) * 6
			elif p == CheckersRules.BLACK:
				val += r * 6
			# Center control
			if r >= 2 and r <= 5 and c >= 2 and c <= 5:
				val += 4
			score += val if side == for_color else -val
	return score


func choose_dominoes(rules: DominoesRules, level: int) -> Dictionary:
	# Returns {action: "play"|"pass"|"draw", tile, end}
	if rules.can_draw():
		if level <= EASY:
			# Easy draws when required, otherwise would have been able to play.
			return {"action": "draw"}
		return {"action": "draw"}
	var plays: Array = rules.legal_plays()
	if plays.is_empty():
		return {"action": "pass"}
	if level <= EASY:
		var p: Dictionary = plays[rng.randi_range(0, plays.size() - 1)]
		return {"action": "play", "tile": p["tile"], "end": p["end"]}
	if level == MEDIUM:
		# Play the highest-pip legal tile (get heavy tiles off the hand).
		var best: Dictionary = plays[0]
		var best_v := -1
		for p2 in plays:
			var t: Vector2i = p2["tile"]
			var v: int = t.x + t.y
			if t.x == t.y:
				v += 1  # slight preference to spend a double
			if v > best_v:
				best_v = v
				best = p2
		return {"action": "play", "tile": best["tile"], "end": best["end"]}
	# Hard: score each play by leftover pips, how well it blocks the next
	# opponent, and whether it keeps a second tile for the same numbers.
	var best_plays: Array = []
	var best_sc := -999999
	for p3 in plays:
		var sc := _dominoes_score_play(rules, p3)
		if sc > best_sc:
			best_sc = sc
			best_plays = [p3]
		elif sc == best_sc:
			best_plays.append(p3)
	var pick: Dictionary = best_plays[rng.randi_range(0, best_plays.size() - 1)]
	return {"action": "play", "tile": pick["tile"], "end": pick["end"]}


func _dominoes_score_play(rules: DominoesRules, play: Dictionary) -> int:
	var seat: int = rules.current_seat
	var tile: Vector2i = play["tile"]
	var end: String = str(play["end"])
	# Simulate
	var saved_hands: Array = []
	for h in rules.hands:
		saved_hands.append((h as Array).duplicate())
	var saved_chain: Array = rules.chain.duplicate()
	var saved_left: int = rules.left_end
	var saved_right: int = rules.right_end
	var saved_seat: int = rules.current_seat
	var saved_passes: int = rules.passes_in_row
	var saved_last: int = rules.last_player
	var saved_over: bool = rules.hand_over
	var r: Dictionary = rules.play(seat, tile, end)
	var sc := 0
	if r.get("ok", false):
		if rules.hand_over:
			var hr: Dictionary = rules.last_hand_result
			var team: int = rules.team_of(seat)
			if int(hr.get("scored_team", -1)) == team:
				sc = 1000 + int(hr.get("points", 0))
			else:
				sc = -1000 - int(hr.get("points", 0))
		else:
			# Fewer pips left is good. Prefer leaving ends our partner might like
			# and that the next opponent (seat+1) may not have.
			sc = -rules.hand_pips(seat) * 3
			var next_seat := (seat + 1) % 4
			if not rules.can_play(next_seat):
				sc += 40
			var partner := (seat + 2) % 4
			if rules.can_play(partner):
				sc += 8
			# Prefer not to open a number we no longer hold.
			for endv in [rules.left_end, rules.right_end]:
				if _hand_holds_number(rules.hands[seat], endv):
					sc += 6
				else:
					sc -= 4
	# Restore (play() mutates; we did not go through tavern undo, so rewind fields).
	# If the hand ended it also changed scores — revert those too if needed.
	if rules.hand_over:
		var pts: int = int(rules.last_hand_result.get("points", 0))
		var st: int = int(rules.last_hand_result.get("scored_team", -1))
		if st >= 0:
			rules.team_score[st] -= pts
		rules.game_finished = false
		rules.hand_over = false
		rules.last_hand_result = {}
	rules.hands = saved_hands
	rules.chain = saved_chain
	rules.left_end = saved_left
	rules.right_end = saved_right
	rules.current_seat = saved_seat
	rules.passes_in_row = saved_passes
	rules.last_player = saved_last
	rules.hand_over = saved_over
	return sc


func _hand_holds_number(hand: Array, n: int) -> bool:
	for t in hand:
		if t.x == n or t.y == n:
			return true
	return false


func _pick_best(moves: Array, score_fn: Callable, jitter: int) -> Dictionary:
	var best: Array = []
	var best_sc := -999999
	for m in moves:
		var sc: int = int(score_fn.call(m)) + rng.randi_range(0, jitter)
		if sc > best_sc:
			best_sc = sc
			best = [m]
		elif sc == best_sc:
			best.append(m)
	return best[rng.randi_range(0, best.size() - 1)]
