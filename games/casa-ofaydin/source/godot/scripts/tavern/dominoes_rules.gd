extends RefCounted
class_name DominoesRules
## Four-player partnership Block Dominoes (double-six set) for the
## Port Paradise low-class shack. Seats 0 and 2 are partners (the Gold team).
## Seats 1 and 3 are partners (the Silver team). The first hand starts with
## the double-six. Players pass when they cannot play. A game is played to
## a target of 100 or 150 points (a setting). Draw mode is optional: each
## player is dealt 5 tiles and may draw from the boneyard until two tiles
## remain, then they must pass if they still cannot play.

const TEAM_GOLD := 0
const TEAM_SILVER := 1
const MODE_BLOCK := "block"
const MODE_DRAW := "draw"

var mode: String = MODE_BLOCK
var target_score: int = 100
var seats: int = 4
var hands: Array = []  # 4 arrays of Vector2i (a <= b)
var boneyard: Array = []
var chain: Array = []  # tiles in layout order, each {a, b, left_val, right_val}... simpler: list of Vector2i as placed, plus left_end, right_end
var left_end: int = -1
var right_end: int = -1
var current_seat: int = 0
var leader: int = 0
var team_score: Array = [0, 0]  # gold, silver
var hand_number: int = 0
var passes_in_row: int = 0
var last_player: int = -1
var hand_over: bool = false
var game_finished: bool = false
var last_hand_result: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _first_hand: bool = true

func _init() -> void:
	rng.randomize()
	hands = [[], [], [], []]


func set_seed(s: int) -> void:
	rng.seed = s


func set_target(score: int) -> void:
	# Games go to 100 or 150.
	if score >= 150:
		target_score = 150
	else:
		target_score = 100


func set_mode(m: String) -> void:
	mode = MODE_DRAW if m == MODE_DRAW else MODE_BLOCK


func team_of(seat: int) -> int:
	return TEAM_GOLD if seat % 2 == 0 else TEAM_SILVER


func team_name(team: int) -> String:
	return "Gold" if team == TEAM_GOLD else "Silver"


func reset_match() -> void:
	team_score = [0, 0]
	hand_number = 0
	game_finished = false
	last_hand_result = {}
	_first_hand = true
	new_hand()


func new_hand() -> void:
	hand_over = false
	passes_in_row = 0
	last_player = -1
	chain.clear()
	left_end = -1
	right_end = -1
	var tiles := _double_six_set()
	_shuffle(tiles)
	hands = [[], [], [], []]
	boneyard.clear()
	var deal_count := 7 if mode == MODE_BLOCK else 5
	for i in (deal_count * 4):
		hands[i % 4].append(tiles[i])
	for i in range(deal_count * 4, tiles.size()):
		boneyard.append(tiles[i])
	for s in 4:
		_sort_hand(s)
	hand_number += 1
	if _first_hand:
		var holder := _holder_of(Vector2i(6, 6))
		if holder < 0:
			# Draw mode can leave the double-six in the boneyard. The highest
			# double leads instead, so the first hand can always start.
			holder = _highest_double_holder()
		leader = holder if holder >= 0 else 0
		_first_hand = false
	else:
		# Previous hand's last player (the one who went out, or who last
		# played before a block) leads any legal tile.
		if last_hand_result.has("leader_next"):
			leader = int(last_hand_result["leader_next"])
	current_seat = leader


func _double_six_set() -> Array:
	var tiles: Array = []
	for a in 7:
		for b in range(a, 7):
			tiles.append(Vector2i(a, b))
	return tiles


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _sort_hand(seat: int) -> void:
	var h: Array = hands[seat]
	h.sort_custom(func(x: Vector2i, y: Vector2i) -> bool:
		if x.x == y.x:
			return x.y < y.y
		return x.x < y.x
	)


func _holder_of(tile: Vector2i) -> int:
	var t := _norm(tile)
	for s in 4:
		for x in hands[s]:
			if _norm(x) == t:
				return s
	return -1


func _highest_double_holder() -> int:
	for v in range(6, -1, -1):
		var h := _holder_of(Vector2i(v, v))
		if h >= 0:
			return h
	# No doubles in anyone's hand: seat 0 leads any tile.
	return 0


func _norm(t: Vector2i) -> Vector2i:
	return Vector2i(t.x, t.y) if t.x <= t.y else Vector2i(t.y, t.x)


func tile_text(t: Vector2i) -> String:
	var n := _norm(t)
	if n.x == n.y:
		return "double %s" % TavernSafe.number_text(n.x)
	return "%s-%s" % [TavernSafe.number_text(n.x), TavernSafe.number_text(n.y)]


func pip_sum(t: Vector2i) -> int:
	return t.x + t.y


func hand_pips(seat: int) -> int:
	var n := 0
	for t in hands[seat]:
		n += pip_sum(t)
	return n


func team_pips(team: int) -> int:
	var n := 0
	for s in 4:
		if team_of(s) == team:
			n += hand_pips(s)
	return n


func is_first_play() -> bool:
	return chain.is_empty()


func must_lead_double_six() -> bool:
	return is_first_play() and hand_number == 1 and _holder_of(Vector2i(6, 6)) == current_seat


func legal_plays(seat: int = -1) -> Array:
	var s := current_seat if seat < 0 else seat
	var out: Array = []
	if hand_over or game_finished:
		return out
	if is_first_play():
		if hand_number == 1 and _holder_of(Vector2i(6, 6)) == s:
			out.append({"tile": Vector2i(6, 6), "end": "first"})
			return out
		# Later hands, or first hand without the double-six: any tile may lead.
		for t in hands[s]:
			out.append({"tile": _norm(t), "end": "first"})
		return out
	for t in hands[s]:
		var n := _norm(t)
		if n.x == left_end or n.y == left_end:
			out.append({"tile": n, "end": "left"})
		if n.x == right_end or n.y == right_end:
			# A double matches both ends with the same number; one play is enough
			# unless the two ends are different (already handled). If both ends
			# equal this tile, list both so the player can choose the side.
			if left_end != right_end or n.x != left_end and n.y != left_end:
				out.append({"tile": n, "end": "right"})
			elif left_end == right_end and (n.x == left_end or n.y == left_end):
				# Already added left; also allow right as a distinct choice.
				out.append({"tile": n, "end": "right"})
	return out


func can_play(seat: int = -1) -> bool:
	return legal_plays(seat).size() > 0


func can_draw(seat: int = -1) -> bool:
	var s := current_seat if seat < 0 else seat
	return mode == MODE_DRAW and (not can_play(s)) and boneyard.size() > 2


func draw_one(seat: int = -1) -> Dictionary:
	var s := current_seat if seat < 0 else seat
	if not can_draw(s):
		return {"ok": false, "error": "No tile to draw right now.", "tile": Vector2i(-1, -1)}
	var t: Vector2i = boneyard.pop_back()
	hands[s].append(t)
	_sort_hand(s)
	return {"ok": true, "tile": _norm(t), "description": "Seat %s draws a tile." % TavernSafe.number_text(s + 1)}


func play(seat: int, tile: Vector2i, end: String) -> Dictionary:
	if hand_over or game_finished:
		return {"ok": false, "error": "This hand is already over."}
	if seat != current_seat:
		return {"ok": false, "error": "It is not this player's turn."}
	var n := _norm(tile)
	var plays := legal_plays(seat)
	var matched := false
	var use_end := end
	for p in plays:
		if _norm(p["tile"]) == n and (end == "" or str(p["end"]) == end or str(p["end"]) == "first"):
			matched = true
			use_end = str(p["end"])
			break
	# If the caller omitted the end, pick the first legal side for that tile.
	if not matched and end == "":
		for p in plays:
			if _norm(p["tile"]) == n:
				matched = true
				use_end = str(p["end"])
				break
	if not matched:
		return {"ok": false, "error": "That tile cannot be played right now."}
	if not _take_from_hand(seat, n):
		return {"ok": false, "error": "That tile is not in this hand."}
	_place(n, use_end)
	passes_in_row = 0
	last_player = seat
	var desc := "Seat %s plays %s." % [TavernSafe.number_text(seat + 1), tile_text(n)]
	if hands[seat].is_empty():
		_finish_hand("out", seat)
		return {"ok": true, "description": desc, "result": result(), "hand_result": last_hand_result}
	current_seat = (current_seat + 1) % 4
	return {"ok": true, "description": desc, "result": result(), "hand_result": {}}


func pass_turn(seat: int = -1) -> Dictionary:
	var s := current_seat if seat < 0 else seat
	if s != current_seat:
		return {"ok": false, "error": "It is not this player's turn."}
	if can_play(s):
		return {"ok": false, "error": "This player still has a tile that can be played."}
	if can_draw(s):
		return {"ok": false, "error": "This player can still draw a tile."}
	passes_in_row += 1
	var desc := "Seat %s passes." % TavernSafe.number_text(s + 1)
	if passes_in_row >= 4:
		_finish_hand("blocked", last_player)
		return {"ok": true, "description": desc, "result": result(), "hand_result": last_hand_result}
	current_seat = (current_seat + 1) % 4
	return {"ok": true, "description": desc, "result": result(), "hand_result": {}}


func _take_from_hand(seat: int, tile: Vector2i) -> bool:
	var n := _norm(tile)
	var h: Array = hands[seat]
	for i in h.size():
		if _norm(h[i]) == n:
			h.remove_at(i)
			return true
	return false


func _place(tile: Vector2i, end: String) -> void:
	var n := _norm(tile)
	if chain.is_empty() or end == "first":
		chain.append(n)
		left_end = n.x
		right_end = n.y
		# A double has the same number on both ends, which is correct.
		return
	if end == "left":
		# The exposed left end must match one side of the tile; the other side
		# becomes the new left end.
		if n.x == left_end:
			left_end = n.y
		elif n.y == left_end:
			left_end = n.x
		chain.insert(0, n)
	else:
		if n.x == right_end:
			right_end = n.y
		elif n.y == right_end:
			right_end = n.x
		chain.append(n)


func _finish_hand(reason: String, actor: int) -> void:
	hand_over = true
	var gold_p := team_pips(TEAM_GOLD)
	var silver_p := team_pips(TEAM_SILVER)
	var scored_team := -1
	var points := 0
	if reason == "out":
		scored_team = team_of(actor)
		points = team_pips(1 - scored_team)
	else:
		# Blocked: the team with fewer pips scores the difference.
		if gold_p < silver_p:
			scored_team = TEAM_GOLD
			points = silver_p - gold_p
		elif silver_p < gold_p:
			scored_team = TEAM_SILVER
			points = gold_p - silver_p
		else:
			scored_team = -1
			points = 0
	if scored_team >= 0 and points > 0:
		team_score[scored_team] += points
		# House rule: if a printed score would contain the forbidden run of
		# three 6s, bump the score by one so the digits never appear.
		if TavernSafe.contains_forbidden(str(team_score[scored_team])):
			team_score[scored_team] += 1
	if team_score[TEAM_GOLD] >= target_score or team_score[TEAM_SILVER] >= target_score:
		game_finished = true
	var leader_next := actor if actor >= 0 else (current_seat + 1) % 4
	if reason == "blocked":
		leader_next = (leader + 1) % 4
	last_hand_result = {
		"reason": reason,
		"actor": actor,
		"points": points,
		"scored_team": scored_team,
		"gold_pips": gold_p,
		"silver_pips": silver_p,
		"leader_next": leader_next,
		"text": _hand_text(reason, scored_team, points)
	}


func _hand_text(reason: String, scored_team: int, points: int) -> String:
	if reason == "out":
		if scored_team < 0:
			return "The hand is over."
		return "%s went out and scores %s points." % [team_name(scored_team), TavernSafe.number_text(points)]
	if scored_team < 0:
		return "The table is blocked. Both teams have the same pips, so nobody scores."
	return "The table is blocked. %s has fewer pips and scores %s points." % [team_name(scored_team), TavernSafe.number_text(points)]


func result() -> Dictionary:
	if game_finished:
		var w := TEAM_GOLD if team_score[TEAM_GOLD] >= target_score else TEAM_SILVER
		if team_score[TEAM_GOLD] >= target_score and team_score[TEAM_SILVER] >= target_score:
			w = TEAM_GOLD if team_score[TEAM_GOLD] >= team_score[TEAM_SILVER] else TEAM_SILVER
			if team_score[TEAM_GOLD] == team_score[TEAM_SILVER]:
				return {
					"over": true,
					"winner": "",
					"reason": "tie",
					"text": "The game is a tie. Gold %s, Silver %s." % [TavernSafe.number_text(team_score[0]), TavernSafe.number_text(team_score[1])],
					"gold": team_score[0],
					"silver": team_score[1]
				}
		return {
			"over": true,
			"winner": team_name(w),
			"reason": "target",
			"text": "%s wins the game, %s to %s." % [team_name(w), TavernSafe.number_text(team_score[w]), TavernSafe.number_text(team_score[1 - w])],
			"gold": team_score[0],
			"silver": team_score[1]
		}
	if hand_over:
		return {
			"over": false,
			"winner": "",
			"reason": "hand_over",
			"text": str(last_hand_result.get("text", "The hand is over.")),
			"gold": team_score[0],
			"silver": team_score[1]
		}
	return {
		"over": false,
		"winner": "",
		"reason": "",
		"text": "Seat %s to play." % TavernSafe.number_text(current_seat + 1),
		"gold": team_score[0],
		"silver": team_score[1]
	}


func layout_text() -> String:
	if chain.is_empty():
		return "No tiles on the table yet."
	var parts: PackedStringArray = []
	for t in chain:
		parts.append(tile_text(t))
	return "Left %s | %s | Right %s" % [TavernSafe.number_text(left_end), ", ".join(parts), TavernSafe.number_text(right_end)]


## Test helper: load a custom hand and layout, then evaluate a block.
func debug_setup(p_hands: Array, p_left: int, p_right: int, p_chain: Array, p_seat: int, p_scores: Array = [0, 0]) -> void:
	hands = [[], [], [], []]
	for s in 4:
		for t in p_hands[s]:
			hands[s].append(_norm(t))
	left_end = p_left
	right_end = p_right
	chain = p_chain.duplicate()
	current_seat = p_seat
	passes_in_row = 0
	hand_over = false
	game_finished = false
	team_score = p_scores.duplicate()
	boneyard.clear()
	mode = MODE_BLOCK
	_first_hand = false
	hand_number = 2
