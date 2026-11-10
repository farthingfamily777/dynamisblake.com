extends RefCounted
class_name ChessRules
## Full legal chess rules for the Port Paradise high-class tavern.
## Written fresh in GDScript for Godot 4.3 (Compatibility / web, no threads).
## Legal-move counts were checked against the same standard test positions
## used by chess.js 0.13.4 (BSD licensed, vendored in the Game Room).

const START_FEN := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

const EMPTY := 0
const W_PAWN := 1
const W_KNIGHT := 2
const W_BISHOP := 3
const W_ROOK := 4
const W_QUEEN := 5
const W_KING := 6
const B_PAWN := 9
const B_KNIGHT := 10
const B_BISHOP := 11
const B_ROOK := 12
const B_QUEEN := 13
const B_KING := 14

const FLAG_CAPTURE := 1
const FLAG_CASTLE_K := 2
const FLAG_CASTLE_Q := 4
const FLAG_EP := 8
const FLAG_DOUBLE := 16
const FLAG_PROMO := 32

const CR_WK := 1
const CR_WQ := 2
const CR_BK := 4
const CR_BQ := 8

const N_DF: Array[int] = [1, -1, 1, -1, 2, -2, 2, -2]
const N_DR: Array[int] = [2, 2, -2, -2, 1, 1, -1, -1]
const K_DF: Array[int] = [1, -1, 0, 0, 1, 1, -1, -1]
const K_DR: Array[int] = [0, 0, 1, -1, 1, -1, 1, -1]
const B_DF: Array[int] = [1, 1, -1, -1]
const B_DR: Array[int] = [1, -1, 1, -1]
const R_DF: Array[int] = [1, -1, 0, 0]
const R_DR: Array[int] = [0, 0, 1, -1]

var board: Array = []  # 64 ints
var white_to_move: bool = true
var rights: int = 15
var ep_square: int = -1
var halfmove: int = 0
var fullmove: int = 1
var _undo: Array = []
var _pos_keys: Array = []  # keys after each ply, including the start
var _start_key: String = ""

func _init() -> void:
	reset()


func reset() -> void:
	setup_fen(START_FEN)


func setup_fen(fen: String) -> void:
	board = []
	for _i in 64:
		board.append(EMPTY)
	_undo.clear()
	var parts := fen.strip_edges().split(" ")
	var rows := parts[0].split("/")
	for r in 8:
		var file := 0
		for ch in rows[r]:
			if ch >= "1" and ch <= "8":
				file += int(ch)
			else:
				var rank := 7 - r
				board[rank * 8 + file] = _char_to_piece(ch)
				file += 1
	white_to_move = true
	if parts.size() > 1:
		white_to_move = parts[1] == "w"
	rights = 0
	if parts.size() > 2 and parts[2] != "-":
		if "K" in parts[2]:
			rights |= CR_WK
		if "Q" in parts[2]:
			rights |= CR_WQ
		if "k" in parts[2]:
			rights |= CR_BK
		if "q" in parts[2]:
			rights |= CR_BQ
	ep_square = -1
	if parts.size() > 3 and parts[3] != "-":
		ep_square = alg_to_sq(parts[3])
	halfmove = 0
	if parts.size() > 4:
		halfmove = int(parts[4])
	fullmove = 1
	if parts.size() > 5:
		fullmove = int(parts[5])
	_pos_keys.clear()
	_start_key = _key()
	_pos_keys.append(_start_key)


func fen() -> String:
	var rows: PackedStringArray = []
	for r in range(7, -1, -1):
		var empty := 0
		var row := ""
		for f in 8:
			var p: int = board[r * 8 + f]
			if p == EMPTY:
				empty += 1
			else:
				if empty > 0:
					row += str(empty)
					empty = 0
				row += _piece_to_char(p)
		if empty > 0:
			row += str(empty)
		rows.append(row)
	var cr := ""
	if rights & CR_WK:
		cr += "K"
	if rights & CR_WQ:
		cr += "Q"
	if rights & CR_BK:
		cr += "k"
	if rights & CR_BQ:
		cr += "q"
	if cr == "":
		cr = "-"
	var ep := "-" if ep_square < 0 else sq_to_alg(ep_square)
	return "%s %s %s %s %d %d" % [ "/".join(rows), "w" if white_to_move else "b", cr, ep, halfmove, fullmove ]


func turn_is_white() -> bool:
	return white_to_move


func turn_name() -> String:
	return "White" if white_to_move else "Black"


static func sq_to_alg(sq: int) -> String:
	if sq < 0 or sq > 63:
		return ""
	return char(97 + (sq % 8)) + str(int(sq / 8) + 1)


static func alg_to_sq(alg: String) -> int:
	if alg.length() < 2:
		return -1
	var f := alg.unicode_at(0) - 97
	var r := int(alg.substr(1, 1)) - 1
	if f < 0 or f > 7 or r < 0 or r > 7:
		return -1
	return r * 8 + f


func piece_at(alg: String) -> String:
	var sq := alg_to_sq(alg)
	if sq < 0:
		return ""
	return _piece_to_char(board[sq])


func board_chars() -> Array:
	var out: Array = []
	for i in 64:
		out.append(_piece_to_char(board[i]))
	return out


func legal_moves() -> Array:
	var out: Array = []
	for packed in _gen_legal_ints():
		out.append(move_to_dict(packed))
	return out


func legal_moves_from(alg: String) -> Array:
	var from_sq := alg_to_sq(alg)
	var out: Array = []
	for packed in _gen_legal_ints():
		if _m_from(packed) == from_sq:
			out.append(move_to_dict(packed))
	return out


func has_legal_move() -> bool:
	return not _gen_legal_ints().is_empty()


func in_check() -> bool:
	return _king_attacked(white_to_move)


func in_checkmate() -> bool:
	return in_check() and not has_legal_move()


func in_stalemate() -> bool:
	return (not in_check()) and not has_legal_move()


func is_fifty_move_draw() -> bool:
	return halfmove >= 100


func is_threefold() -> bool:
	var k := _key()
	var n := 0
	for old in _pos_keys:
		if old == k:
			n += 1
	return n >= 3


func is_insufficient_material() -> bool:
	var white_minors: Array = []
	var black_minors: Array = []
	var white_bishop_dark := 0
	var black_bishop_dark := 0
	for sq in 64:
		var p: int = board[sq]
		if p == EMPTY or p == W_KING or p == B_KING:
			continue
		if p == W_PAWN or p == B_PAWN or p == W_ROOK or p == B_ROOK or p == W_QUEEN or p == B_QUEEN:
			return false
		var dark := ((sq % 8) + int(sq / 8)) % 2
		if p == W_BISHOP:
			white_minors.append(p)
			white_bishop_dark += dark
		elif p == B_BISHOP:
			black_minors.append(p)
			black_bishop_dark += dark
		elif p == W_KNIGHT:
			white_minors.append(p)
		elif p == B_KNIGHT:
			black_minors.append(p)
		else:
			return false
	var w := white_minors.size()
	var b := black_minors.size()
	if w == 0 and b == 0:
		return true
	if (w == 1 and b == 0) or (w == 0 and b == 1):
		return true
	if w == 1 and b == 1:
		var wb: bool = white_minors[0] == W_BISHOP
		var bb: bool = black_minors[0] == B_BISHOP
		if wb and bb:
			# Same-color bishops cannot mate.
			var wdark := white_bishop_dark > 0
			var bdark := black_bishop_dark > 0
			return wdark == bdark
	return false


func is_draw() -> bool:
	return in_stalemate() or is_fifty_move_draw() or is_threefold() or is_insufficient_material()


func game_over() -> bool:
	return in_checkmate() or is_draw()


func result() -> Dictionary:
	if in_checkmate():
		var winner := "Black" if white_to_move else "White"
		return {
			"over": true,
			"winner": winner,
			"reason": "checkmate",
			"text": "Checkmate. %s wins." % winner
		}
	if in_stalemate():
		return {"over": true, "winner": "", "reason": "stalemate", "text": "Draw. Stalemate: no legal move, and the king is safe."}
	if is_fifty_move_draw():
		return {"over": true, "winner": "", "reason": "fifty_move", "text": "Draw. Fifty moves went by with no pawn move and no capture."}
	if is_threefold():
		return {"over": true, "winner": "", "reason": "threefold", "text": "Draw. The same position came up three times."}
	if is_insufficient_material():
		return {"over": true, "winner": "", "reason": "insufficient", "text": "Draw. Neither side has enough pieces left to checkmate."}
	return {"over": false, "winner": "", "reason": "", "text": "%s to move." % turn_name()}


func make_move(move: Dictionary) -> Dictionary:
	var packed := _dict_to_packed(move)
	if packed < 0:
		return {"ok": false, "error": "That is not a legal move."}
	if not _is_legal_int(packed):
		return {"ok": false, "error": "That is not a legal move."}
	_apply(packed)
	var desc := describe_move_dict(move_to_dict(packed))
	return {"ok": true, "move": move_to_dict(packed), "description": desc, "in_check": in_check(), "result": result()}


func make_move_int(packed: int) -> bool:
	if not _is_legal_int(packed):
		return false
	_apply(packed)
	return true


func undo() -> void:
	if _undo.is_empty():
		return
	_unapply()


func perft(depth: int) -> int:
	if depth <= 0:
		return 1
	var moves: Array = _gen_legal_ints()
	if depth == 1:
		return moves.size()
	var n := 0
	for packed in moves:
		_apply(packed)
		n += perft(depth - 1)
		_unapply()
	return n


func move_to_dict(packed: int) -> Dictionary:
	var from_sq := _m_from(packed)
	var to_sq := _m_to(packed)
	var promo := _m_promo(packed)
	var flags := _m_flags(packed)
	var d := {
		"from": sq_to_alg(from_sq),
		"to": sq_to_alg(to_sq),
		"promotion": promo,
		"flags": flags,
		"uci": sq_to_alg(from_sq) + sq_to_alg(to_sq) + promo
	}
	return d


func describe_move_dict(move: Dictionary) -> String:
	var who := "Black" if white_to_move else "White"
	# After the move, the side has already flipped; describe uses the mover.
	# Callers should call this after apply, so invert.
	var piece := piece_at(str(move.get("to", "")))
	if piece == "":
		piece = "piece"
	var pname := _plain_piece_name(piece)
	var dest: String = str(move.get("to", ""))
	var start: String = str(move.get("from", ""))
	var flags: int = int(move.get("flags", 0))
	if flags & FLAG_CASTLE_K:
		return "%s castles on the king's side." % who
	if flags & FLAG_CASTLE_Q:
		return "%s castles on the queen's side." % who
	var promo: String = str(move.get("promotion", ""))
	if promo != "":
		return "%s pawn moves from %s to %s and becomes a %s." % [who, start, dest, _plain_piece_name(promo if who == "White" else promo.to_lower())]
	if flags & FLAG_EP:
		return "%s pawn captures en passant from %s to %s." % [who, start, dest]
	if flags & FLAG_CAPTURE:
		return "%s %s captures on %s." % [who, pname, dest]
	return "%s %s moves from %s to %s." % [who, pname, start, dest]


func _plain_piece_name(ch: String) -> String:
	var c := ch.to_lower()
	if c == "p":
		return "pawn"
	if c == "n":
		return "knight"
	if c == "b":
		return "bishop"
	if c == "r":
		return "rook"
	if c == "q":
		return "queen"
	if c == "k":
		return "king"
	return "piece"


func _char_to_piece(ch: String) -> int:
	match ch:
		"P":
			return W_PAWN
		"N":
			return W_KNIGHT
		"B":
			return W_BISHOP
		"R":
			return W_ROOK
		"Q":
			return W_QUEEN
		"K":
			return W_KING
		"p":
			return B_PAWN
		"n":
			return B_KNIGHT
		"b":
			return B_BISHOP
		"r":
			return B_ROOK
		"q":
			return B_QUEEN
		"k":
			return B_KING
		_:
			return EMPTY


func _piece_to_char(p: int) -> String:
	match p:
		W_PAWN:
			return "P"
		W_KNIGHT:
			return "N"
		W_BISHOP:
			return "B"
		W_ROOK:
			return "R"
		W_QUEEN:
			return "Q"
		W_KING:
			return "K"
		B_PAWN:
			return "p"
		B_KNIGHT:
			return "n"
		B_BISHOP:
			return "b"
		B_ROOK:
			return "r"
		B_QUEEN:
			return "q"
		B_KING:
			return "k"
		_:
			return ""


func _is_white_piece(p: int) -> bool:
	return p > 0 and p < 8


func _is_black_piece(p: int) -> bool:
	return p >= 9


func _same_side(a: int, b: int) -> bool:
	if a == EMPTY or b == EMPTY:
		return false
	return _is_white_piece(a) == _is_white_piece(b)


func _kind(p: int) -> int:
	if p >= 9:
		return p - 8
	return p


func _gen_legal_ints() -> Array:
	var raw: Array = []
	_gen_pseudo(raw)
	var legal: Array = []
	for packed in raw:
		if _legal_after(packed):
			legal.append(packed)
	return legal


func _is_legal_int(packed: int) -> bool:
	for m in _gen_legal_ints():
		if m == packed:
			return true
	return false


func _legal_after(packed: int) -> bool:
	var mover_white := white_to_move
	_apply(packed)
	var bad := _king_attacked(mover_white)
	_unapply()
	return not bad


func _king_attacked(white_king: bool) -> bool:
	var target := W_KING if white_king else B_KING
	var sq := -1
	for i in 64:
		if board[i] == target:
			sq = i
			break
	if sq < 0:
		return true
	return is_square_attacked(sq, not white_king)


func is_square_attacked(sq: int, by_white: bool) -> bool:
	var f := sq % 8
	var r := int(sq / 8)
	# Pawns
	if by_white:
		if r > 0:
			if f > 0 and board[(r - 1) * 8 + (f - 1)] == W_PAWN:
				return true
			if f < 7 and board[(r - 1) * 8 + (f + 1)] == W_PAWN:
				return true
	else:
		if r < 7:
			if f > 0 and board[(r + 1) * 8 + (f - 1)] == B_PAWN:
				return true
			if f < 7 and board[(r + 1) * 8 + (f + 1)] == B_PAWN:
				return true
	# Knights
	var nk := W_KNIGHT if by_white else B_KNIGHT
	for i in 8:
		var nf: int = f + N_DF[i]
		var nr: int = r + N_DR[i]
		if nf >= 0 and nf <= 7 and nr >= 0 and nr <= 7 and board[nr * 8 + nf] == nk:
			return true
	# King
	var kk := W_KING if by_white else B_KING
	for i in 8:
		var kf: int = f + K_DF[i]
		var kr: int = r + K_DR[i]
		if kf >= 0 and kf <= 7 and kr >= 0 and kr <= 7 and board[kr * 8 + kf] == kk:
			return true
	# Bishops / queens
	var bw := W_BISHOP if by_white else B_BISHOP
	var qw := W_QUEEN if by_white else B_QUEEN
	for i in 4:
		var af: int = f + B_DF[i]
		var ar: int = r + B_DR[i]
		while af >= 0 and af <= 7 and ar >= 0 and ar <= 7:
			var p: int = board[ar * 8 + af]
			if p != EMPTY:
				if p == bw or p == qw:
					return true
				break
			af += B_DF[i]
			ar += B_DR[i]
	# Rooks / queens
	var rw := W_ROOK if by_white else B_ROOK
	for i in 4:
		var rf: int = f + R_DF[i]
		var rr: int = r + R_DR[i]
		while rf >= 0 and rf <= 7 and rr >= 0 and rr <= 7:
			var q: int = board[rr * 8 + rf]
			if q != EMPTY:
				if q == rw or q == qw:
					return true
				break
			rf += R_DF[i]
			rr += R_DR[i]
	return false


func _gen_pseudo(out: Array) -> void:
	var white := white_to_move
	for sq in 64:
		var p: int = board[sq]
		if p == EMPTY:
			continue
		if white and not _is_white_piece(p):
			continue
		if (not white) and not _is_black_piece(p):
			continue
		var k := _kind(p)
		if k == W_PAWN:
			_gen_pawn(out, sq, white)
		elif k == W_KNIGHT:
			_gen_leaper(out, sq, N_DF, N_DR, white)
		elif k == W_BISHOP:
			_gen_slide(out, sq, B_DF, B_DR, white)
		elif k == W_ROOK:
			_gen_slide(out, sq, R_DF, R_DR, white)
		elif k == W_QUEEN:
			_gen_slide(out, sq, B_DF, B_DR, white)
			_gen_slide(out, sq, R_DF, R_DR, white)
		elif k == W_KING:
			_gen_leaper(out, sq, K_DF, K_DR, white)
			_gen_castles(out, sq, white)


func _push(out: Array, frm: int, to: int, promo: String, flags: int) -> void:
	out.append(_pack(frm, to, promo, flags))


func _gen_pawn(out: Array, sq: int, white: bool) -> void:
	var f := sq % 8
	var r := int(sq / 8)
	var dir := 1 if white else -1
	var start_rank := 1 if white else 6
	var last_rank := 7 if white else 0
	var n1 := r + dir
	if n1 < 0 or n1 > 7:
		return
	var one := n1 * 8 + f
	if board[one] == EMPTY:
		if n1 == last_rank:
			for pr in ["q", "r", "b", "n"]:
				_push(out, sq, one, pr, FLAG_PROMO)
		else:
			_push(out, sq, one, "", 0)
			if r == start_rank:
				var n2 := r + dir * 2
				var two := n2 * 8 + f
				if board[two] == EMPTY:
					_push(out, sq, two, "", FLAG_DOUBLE)
	for df in [-1, 1]:
		var cf: int = f + int(df)
		if cf < 0 or cf > 7:
			continue
		var cap: int = n1 * 8 + cf
		var flags := FLAG_CAPTURE
		var dest: int = board[cap]
		var can := false
		if dest != EMPTY and _is_white_piece(dest) != white:
			can = true
		elif cap == ep_square and ep_square >= 0:
			can = true
			flags |= FLAG_EP
		if not can:
			continue
		if n1 == last_rank:
			for pr in ["q", "r", "b", "n"]:
				_push(out, sq, cap, pr, flags | FLAG_PROMO)
		else:
			_push(out, sq, cap, "", flags)


func _gen_leaper(out: Array, sq: int, dfs: Array, drs: Array, white: bool) -> void:
	var f := sq % 8
	var r := int(sq / 8)
	for i in dfs.size():
		var nf := f + int(dfs[i])
		var nr := r + int(drs[i])
		if nf < 0 or nf > 7 or nr < 0 or nr > 7:
			continue
		var to := nr * 8 + nf
		var dest: int = board[to]
		if dest == EMPTY:
			_push(out, sq, to, "", 0)
		elif _is_white_piece(dest) != white:
			_push(out, sq, to, "", FLAG_CAPTURE)


func _gen_slide(out: Array, sq: int, dfs: Array, drs: Array, white: bool) -> void:
	var f := sq % 8
	var r := int(sq / 8)
	for i in dfs.size():
		var nf := f + int(dfs[i])
		var nr := r + int(drs[i])
		while nf >= 0 and nf <= 7 and nr >= 0 and nr <= 7:
			var to := nr * 8 + nf
			var dest: int = board[to]
			if dest == EMPTY:
				_push(out, sq, to, "", 0)
			else:
				if _is_white_piece(dest) != white:
					_push(out, sq, to, "", FLAG_CAPTURE)
				break
			nf += int(dfs[i])
			nr += int(drs[i])


func _gen_castles(out: Array, sq: int, white: bool) -> void:
	if white and sq != 4:
		return
	if (not white) and sq != 60:
		return
	if _king_attacked(white):
		return
	if white:
		if (rights & CR_WK) and board[5] == EMPTY and board[6] == EMPTY:
			if (not is_square_attacked(5, false)) and (not is_square_attacked(6, false)):
				_push(out, 4, 6, "", FLAG_CASTLE_K)
		if (rights & CR_WQ) and board[3] == EMPTY and board[2] == EMPTY and board[1] == EMPTY:
			if (not is_square_attacked(3, false)) and (not is_square_attacked(2, false)):
				_push(out, 4, 2, "", FLAG_CASTLE_Q)
	else:
		if (rights & CR_BK) and board[61] == EMPTY and board[62] == EMPTY:
			if (not is_square_attacked(61, true)) and (not is_square_attacked(62, true)):
				_push(out, 60, 62, "", FLAG_CASTLE_K)
		if (rights & CR_BQ) and board[59] == EMPTY and board[58] == EMPTY and board[57] == EMPTY:
			if (not is_square_attacked(59, true)) and (not is_square_attacked(58, true)):
				_push(out, 60, 58, "", FLAG_CASTLE_Q)


func _pack(frm: int, to: int, promo: String, flags: int) -> int:
	var pc := 0
	if promo == "n":
		pc = 1
	elif promo == "b":
		pc = 2
	elif promo == "r":
		pc = 3
	elif promo == "q":
		pc = 4
	return frm | (to << 6) | (pc << 12) | (flags << 16)


func _m_from(m: int) -> int:
	return m & 63


func _m_to(m: int) -> int:
	return (m >> 6) & 63


func _m_promo(m: int) -> String:
	var pc := (m >> 12) & 7
	if pc == 1:
		return "n"
	if pc == 2:
		return "b"
	if pc == 3:
		return "r"
	if pc == 4:
		return "q"
	return ""


func _m_flags(m: int) -> int:
	return m >> 16


func _dict_to_packed(move: Dictionary) -> int:
	var from_sq := alg_to_sq(str(move.get("from", "")))
	var to_sq := alg_to_sq(str(move.get("to", "")))
	if from_sq < 0 or to_sq < 0:
		# Also accept uci like "e2e4" or "e7e8q"
		var uci: String = str(move.get("uci", ""))
		if uci.length() >= 4:
			from_sq = alg_to_sq(uci.substr(0, 2))
			to_sq = alg_to_sq(uci.substr(2, 2))
			if uci.length() >= 5 and not move.has("promotion"):
				move["promotion"] = uci.substr(4, 1).to_lower()
	if from_sq < 0 or to_sq < 0:
		return -1
	var want_promo: String = str(move.get("promotion", "")).to_lower()
	for packed in _gen_legal_ints():
		if _m_from(packed) == from_sq and _m_to(packed) == to_sq:
			var pr := _m_promo(packed)
			if pr == "" and want_promo == "":
				return packed
			if pr != "" and (want_promo == pr or want_promo == ""):
				# Default promotion is a queen if the player did not pick one.
				if want_promo == "" and pr != "q":
					continue
				return packed
	return -1


func _promo_piece(white: bool, promo: String) -> int:
	if white:
		match promo:
			"n":
				return W_KNIGHT
			"b":
				return W_BISHOP
			"r":
				return W_ROOK
			_:
				return W_QUEEN
	match promo:
		"n":
			return B_KNIGHT
		"b":
			return B_BISHOP
		"r":
			return B_ROOK
		_:
			return B_QUEEN


func _apply(packed: int) -> void:
	var frm := _m_from(packed)
	var to := _m_to(packed)
	var flags := _m_flags(packed)
	var promo := _m_promo(packed)
	var piece: int = board[frm]
	var captured: int = board[to]
	var old_ep := ep_square
	var old_rights := rights
	var old_half := halfmove
	var ep_cap := EMPTY
	board[frm] = EMPTY
	if flags & FLAG_EP:
		var cap_sq := to - 8 if _is_white_piece(piece) else to + 8
		ep_cap = board[cap_sq]
		board[cap_sq] = EMPTY
		captured = ep_cap
	if flags & FLAG_PROMO:
		board[to] = _promo_piece(_is_white_piece(piece), promo)
	else:
		board[to] = piece
	if flags & FLAG_CASTLE_K:
		if _is_white_piece(piece):
			board[7] = EMPTY
			board[5] = W_ROOK
		else:
			board[63] = EMPTY
			board[61] = B_ROOK
	elif flags & FLAG_CASTLE_Q:
		if _is_white_piece(piece):
			board[0] = EMPTY
			board[3] = W_ROOK
		else:
			board[56] = EMPTY
			board[59] = B_ROOK
	# Rights
	if piece == W_KING:
		rights &= ~(CR_WK | CR_WQ)
	elif piece == B_KING:
		rights &= ~(CR_BK | CR_BQ)
	if frm == 0 or to == 0:
		rights &= ~CR_WQ
	if frm == 7 or to == 7:
		rights &= ~CR_WK
	if frm == 56 or to == 56:
		rights &= ~CR_BQ
	if frm == 63 or to == 63:
		rights &= ~CR_BK
	# En passant target
	if flags & FLAG_DOUBLE:
		ep_square = int((frm + to) / 2)
	else:
		ep_square = -1
	# Clocks
	if _kind(piece) == W_PAWN or captured != EMPTY or (flags & FLAG_EP):
		halfmove = 0
	else:
		halfmove += 1
	if not _is_white_piece(piece):
		fullmove += 1
	white_to_move = not white_to_move
	_undo.append({
		"m": packed,
		"cap": captured,
		"ep": old_ep,
		"rights": old_rights,
		"half": old_half,
		"ep_cap": ep_cap
	})
	_pos_keys.append(_key())


func _unapply() -> void:
	var u: Dictionary = _undo.pop_back()
	_pos_keys.pop_back()
	var packed: int = int(u["m"])
	var frm := _m_from(packed)
	var to := _m_to(packed)
	var flags := _m_flags(packed)
	var promo := _m_promo(packed)
	white_to_move = not white_to_move
	if not white_to_move:
		fullmove -= 1
	var piece: int = board[to]
	if flags & FLAG_PROMO:
		piece = W_PAWN if white_to_move else B_PAWN
	if flags & FLAG_CASTLE_K:
		if white_to_move:
			board[5] = EMPTY
			board[7] = W_ROOK
		else:
			board[61] = EMPTY
			board[63] = B_ROOK
	elif flags & FLAG_CASTLE_Q:
		if white_to_move:
			board[3] = EMPTY
			board[0] = W_ROOK
		else:
			board[59] = EMPTY
			board[56] = B_ROOK
	board[frm] = piece
	if flags & FLAG_EP:
		board[to] = EMPTY
		var cap_sq := to - 8 if white_to_move else to + 8
		board[cap_sq] = W_PAWN if not white_to_move else B_PAWN
	else:
		board[to] = int(u["cap"])
	ep_square = int(u["ep"])
	rights = int(u["rights"])
	halfmove = int(u["half"])


func _key() -> String:
	# Position key for threefold: board, side, rights, and ep only if a pawn can capture there.
	var parts := fen().split(" ")
	var ep := "-"
	if ep_square >= 0 and _ep_is_legal_now():
		ep = sq_to_alg(ep_square)
	return "%s %s %s %s" % [parts[0], parts[1], parts[2], ep]


func _ep_is_legal_now() -> bool:
	if ep_square < 0:
		return false
	# A pawn of the side to move must be able to capture on ep_square.
	var f := ep_square % 8
	var r := int(ep_square / 8)
	if white_to_move:
		if r != 5:
			return false
		if f > 0 and board[4 * 8 + (f - 1)] == W_PAWN:
			return true
		if f < 7 and board[4 * 8 + (f + 1)] == W_PAWN:
			return true
	else:
		if r != 2:
			return false
		if f > 0 and board[3 * 8 + (f - 1)] == B_PAWN:
			return true
		if f < 7 and board[3 * 8 + (f + 1)] == B_PAWN:
			return true
	return false
