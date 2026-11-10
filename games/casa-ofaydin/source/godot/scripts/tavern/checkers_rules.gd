extends RefCounted
class_name CheckersRules
## American / English draughts (8x8) for the Port Paradise low-class shack.
## Ported from the Game Room engine at games/shared/checkers-engine.js:
## forced captures, multi-jumps, and kings. A jump that crowns a piece ends
## that turn (no further jumps after the crown).

const RED := 1
const BLACK := -1
const RED_KING := 2
const BLACK_KING := -2

var board: Array = []  # 8 arrays of 8 ints
var turn: int = RED  # RED moves first, like the bottom side
var _undo: Array = []
var quiet_plies: int = 0
var _pos_keys: Array = []

func _init() -> void:
	reset()


func reset() -> void:
	board = start_board()
	turn = RED
	_undo.clear()
	quiet_plies = 0
	_pos_keys.clear()
	_pos_keys.append(_key())


func start_board() -> Array:
	var b: Array = []
	for r in 8:
		var row: Array = []
		for c in 8:
			row.append(0)
		b.append(row)
	for r in 3:
		for c in 8:
			if (r + c) % 2 == 1:
				b[r][c] = BLACK
	for r in range(5, 8):
		for c in 8:
			if (r + c) % 2 == 1:
				b[r][c] = RED
	return b


func set_board(b: Array, whose_turn: int) -> void:
	board = _clone_board(b)
	turn = whose_turn
	_undo.clear()
	quiet_plies = 0
	_pos_keys.clear()
	_pos_keys.append(_key())


func clone_board(b: Array = []) -> Array:
	if b.is_empty():
		return _clone_board(board)
	return _clone_board(b)


func _clone_board(b: Array) -> Array:
	var n: Array = []
	for r in 8:
		n.append((b[r] as Array).duplicate())
	return n


func turn_is_red() -> bool:
	return turn == RED


func turn_name() -> String:
	return "Red" if turn == RED else "Black"


static func on_board(r: int, c: int) -> bool:
	return r >= 0 and r < 8 and c >= 0 and c < 8


static func is_dark(r: int, c: int) -> bool:
	return (r + c) % 2 == 1


static func dirs_for(piece: int) -> Array:
	if absi(piece) == 2:
		return [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]
	if piece > 0:
		return [Vector2i(-1, -1), Vector2i(-1, 1)]
	return [Vector2i(1, -1), Vector2i(1, 1)]


static func would_crown(piece: int, r: int) -> bool:
	return absi(piece) == 1 and ((piece > 0 and r == 0) or (piece < 0 and r == 7))


static func crowning(piece: int, r: int) -> int:
	if would_crown(piece, r):
		return RED_KING if piece > 0 else BLACK_KING
	return piece


func _captures_from(b: Array, r: int, c: int, piece: int, path: Array, used: Dictionary) -> Array:
	var found: Array = []
	for d in dirs_for(piece):
		var mr: int = r + d.x
		var mc: int = c + d.y
		var lr: int = r + 2 * d.x
		var lc: int = c + 2 * d.y
		if not on_board(lr, lc) or not on_board(mr, mc):
			continue
		var mid: int = b[mr][mc]
		if mid == 0 or mid * piece > 0:
			continue
		if b[lr][lc] != 0:
			continue
		var key := "%d,%d" % [mr, mc]
		if used.has(key):
			continue
		var next := _clone_board(b)
		next[r][c] = 0
		next[mr][mc] = 0
		var crowned := would_crown(piece, lr)
		var landed := crowning(piece, lr)
		next[lr][lc] = landed
		var next_used := used.duplicate()
		next_used[key] = true
		var next_path: Array = path.duplicate()
		next_path.append({"r": lr, "c": lc})
		if crowned:
			found.append({"steps": next_path, "land": {"r": lr, "c": lc}})
		else:
			var further := _captures_from(next, lr, lc, landed, next_path, next_used)
			if further.size() > 0:
				found.append_array(further)
			else:
				found.append({"steps": next_path, "land": {"r": lr, "c": lc}})
	return found


func all_moves(for_color: int = 0) -> Array:
	var color := for_color if for_color != 0 else turn
	var captures: Array = []
	var quiets: Array = []
	for r in 8:
		for c in 8:
			var piece: int = board[r][c]
			if piece * color <= 0:
				continue
			var caps := _captures_from(board, r, c, piece, [], {})
			for cap in caps:
				captures.append({"from": {"r": r, "c": c}, "steps": cap["steps"]})
	if captures.size() > 0:
		return captures
	for r in 8:
		for c in 8:
			var piece2: int = board[r][c]
			if piece2 * color <= 0:
				continue
			for d in dirs_for(piece2):
				var nr: int = r + d.x
				var nc: int = c + d.y
				if on_board(nr, nc) and board[nr][nc] == 0 and is_dark(nr, nc):
					quiets.append({"from": {"r": r, "c": c}, "steps": [{"r": nr, "c": nc}]})
	return quiets


func legal_moves() -> Array:
	return all_moves(turn)


func apply_move_board(b: Array, move: Dictionary) -> Array:
	var next := _clone_board(b)
	var fr: int = int(move["from"]["r"])
	var fc: int = int(move["from"]["c"])
	var piece: int = next[fr][fc]
	var r := fr
	var c := fc
	next[r][c] = 0
	for s in move["steps"]:
		var sr: int = int(s["r"])
		var sc: int = int(s["c"])
		if absi(sr - r) == 2:
			var midr := int((sr + r) / 2)
			var midc := int((sc + c) / 2)
			next[midr][midc] = 0
		r = sr
		c = sc
	next[r][c] = crowning(piece, r)
	return next


func make_move(move: Dictionary) -> Dictionary:
	if not _move_is_legal(move):
		return {"ok": false, "error": "That is not a legal move. If a jump is open, you must take it."}
	var before := _clone_board(board)
	var whose := turn
	var old_quiet := quiet_plies
	var jumped := _is_jump(move)
	board = apply_move_board(board, move)
	turn = -turn
	quiet_plies = 0 if jumped else quiet_plies + 1
	_pos_keys.append(_key())
	_undo.append({"board": before, "turn": whose, "quiet": old_quiet})
	return {"ok": true, "move": normalize_move(move), "description": describe_move(move, whose), "result": result()}


func undo() -> void:
	if _undo.is_empty():
		return
	var u: Dictionary = _undo.pop_back()
	board = u["board"]
	turn = int(u["turn"])
	quiet_plies = int(u.get("quiet", 0))
	if _pos_keys.size() > 1:
		_pos_keys.pop_back()


func _move_is_legal(move: Dictionary) -> bool:
	var want := _move_key(normalize_move(move))
	for m in legal_moves():
		if _move_key(m) == want:
			return true
	return false


func normalize_move(move: Dictionary) -> Dictionary:
	var steps: Array = []
	for s in move.get("steps", []):
		steps.append({"r": int(s["r"]), "c": int(s["c"])})
	return {"from": {"r": int(move["from"]["r"]), "c": int(move["from"]["c"])}, "steps": steps}


func _move_key(move: Dictionary) -> String:
	var parts: PackedStringArray = ["%d,%d" % [int(move["from"]["r"]), int(move["from"]["c"])]]
	for s in move["steps"]:
		parts.append("%d,%d" % [int(s["r"]), int(s["c"])])
	return ">".join(parts)


func count_pieces(color: int) -> int:
	var n := 0
	for r in 8:
		for c in 8:
			if board[r][c] * color > 0:
				n += 1
	return n


func count_kings(color: int) -> int:
	var n := 0
	for r in 8:
		for c in 8:
			if board[r][c] == color * 2:
				n += 1
	return n


func has_legal_move(color: int = 0) -> bool:
	var col := color if color != 0 else turn
	return all_moves(col).size() > 0


func game_over() -> bool:
	return is_draw() or count_pieces(turn) == 0 or not has_legal_move(turn)


func is_draw() -> bool:
	# Quiet-play cap keeps two-king chases from running forever in a browser.
	if quiet_plies >= 80:
		return true
	return _is_threefold()


func _is_threefold() -> bool:
	var k := _key()
	var n := 0
	for old in _pos_keys:
		if old == k:
			n += 1
	return n >= 3


func _key() -> String:
	var parts: PackedStringArray = [str(turn)]
	for r in 8:
		var row := ""
		for c in 8:
			row += str(int(board[r][c]))
			row += ","
		parts.append(row)
	return "|".join(parts)


func _is_jump(move: Dictionary) -> bool:
	var r: int = int(move["from"]["r"])
	for s in move.get("steps", []):
		if absi(int(s["r"]) - r) == 2:
			return true
		r = int(s["r"])
	return false


func result() -> Dictionary:
	if is_draw():
		var reason := "quiet" if quiet_plies >= 80 else "threefold"
		return {"over": true, "winner": "", "reason": reason, "text": "Draw. The checkers game is even."}
	if not game_over():
		return {"over": false, "winner": "", "reason": "", "text": "%s to move." % turn_name()}
	var winner := "Red" if turn == BLACK else "Black"
	var reason2 := "no_pieces" if count_pieces(turn) == 0 else "no_moves"
	return {
		"over": true,
		"winner": winner,
		"reason": reason2,
		"text": "%s wins. The other side has no moves left." % winner
	}


func describe_move(move: Dictionary, whose: int) -> String:
	var who := "Red" if whose == RED else "Black"
	var m := normalize_move(move)
	var start := _sq_name(int(m["from"]["r"]), int(m["from"]["c"]))
	var steps: Array = m["steps"]
	var end := _sq_name(int(steps[steps.size() - 1]["r"]), int(steps[steps.size() - 1]["c"]))
	var jumped := false
	var r: int = int(m["from"]["r"])
	for s in steps:
		if absi(int(s["r"]) - r) == 2:
			jumped = true
			break
		r = int(s["r"])
	if steps.size() > 1 and jumped:
		return "%s jumps from %s to %s." % [who, start, end]
	if jumped:
		return "%s jumps from %s to %s." % [who, start, end]
	return "%s moves from %s to %s." % [who, start, end]


func _sq_name(r: int, c: int) -> String:
	# Files A-H, ranks 1-8 from Red's side (row 7 is rank 1).
	return char(65 + c) + str(8 - r)


func square_to_alg(r: int, c: int) -> String:
	return _sq_name(r, c)
