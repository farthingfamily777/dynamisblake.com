extends RefCounted
class_name TavernTable
## Seat manager for a tavern table. Each seat holds a character record and
## is either human or AI. The player may switch into any seat mid-game;
## the seat they left becomes AI and keeps its cards or pieces.
##
## Each seat holds a full arrival-forms character record (see
## ArrivalForms.new_record()). A minimal {id, name, class_id, race}
## dictionary also works. Optional ai_level or skill can override the
## class-based AI strength.

signal move_made(move, seat_index, description)
signal turn_changed(seat_index, character, is_human)
signal game_over(result)

const GAME_CHESS := "chess"
const GAME_CHECKERS := "checkers"
const GAME_DOMINOES := "dominoes"

var game: String = ""
var seats: Array = []  # {character, is_human, ai_level}
var human_seat: int = 0
var chess: ChessRules
var checkers: CheckersRules
var dominoes: DominoesRules
var ai: TavernAI
var last_result: Dictionary = {}
var _started: bool = false

func _init() -> void:
	ai = TavernAI.new()
	chess = ChessRules.new()
	checkers = CheckersRules.new()
	dominoes = DominoesRules.new()


func set_seed(s: int) -> void:
	ai.set_seed(s)
	dominoes.set_seed(s)


func _empty_character(index: int) -> Dictionary:
	return {
		"id": "seat-%s" % TavernSafe.number_text(index + 1),
		"name": "Guest %s" % TavernSafe.number_text(index + 1),
		"class_id": "",
		"race": ""
	}


func _pack_seat(character: Dictionary, is_human: bool) -> Dictionary:
	var rec := character.duplicate(true)
	if not rec.has("id"):
		rec["id"] = str(rec.get("name", "guest"))
	if not rec.has("name"):
		rec["name"] = "Guest"
	if not rec.has("class_id"):
		rec["class_id"] = str(rec.get("class", ""))
	if not rec.has("race"):
		rec["race"] = ""
	return {
		"character": rec,
		"is_human": is_human,
		"ai_level": TavernAI.level_for(rec)
	}


func _seat_count_for(game_name: String) -> int:
	return 4 if game_name == GAME_DOMINOES else 2


func setup_chess(characters: Array, p_human_seat: int = 0) -> void:
	_setup(GAME_CHESS, characters, p_human_seat)
	chess.reset()
	_started = true
	_emit_turn()


func setup_checkers(characters: Array, p_human_seat: int = 0) -> void:
	_setup(GAME_CHECKERS, characters, p_human_seat)
	checkers.reset()
	_started = true
	_emit_turn()


func setup_dominoes(characters: Array, p_human_seat: int = 0, target: int = 100, mode: String = "block") -> void:
	_setup(GAME_DOMINOES, characters, p_human_seat)
	dominoes.set_target(target)
	dominoes.set_mode(mode)
	dominoes.reset_match()
	_started = true
	_emit_turn()


func _setup(game_name: String, characters: Array, p_human_seat: int) -> void:
	game = game_name
	var n := _seat_count_for(game_name)
	seats.clear()
	for i in n:
		var ch: Dictionary = _empty_character(i)
		if i < characters.size() and characters[i] is Dictionary:
			ch = characters[i]
		seats.append(_pack_seat(ch, false))
	human_seat = clampi(p_human_seat, 0, n - 1)
	seats[human_seat]["is_human"] = true
	last_result = {}


func assign_character(seat_index: int, character: Dictionary) -> void:
	if seat_index < 0 or seat_index >= seats.size():
		return
	var was_human: bool = seats[seat_index]["is_human"]
	seats[seat_index] = _pack_seat(character, was_human)


func switch_human(seat_index: int) -> void:
	if seat_index < 0 or seat_index >= seats.size():
		return
	for i in seats.size():
		seats[i]["is_human"] = (i == seat_index)
	human_seat = seat_index
	# Let the UI know whose hands the player now holds. If it is already
	# that seat's turn, the player may move; otherwise AI will keep playing
	# until this seat's turn comes around.
	_emit_turn()


func current_seat() -> int:
	if game == GAME_CHESS:
		return 0 if chess.white_to_move else 1
	if game == GAME_CHECKERS:
		return 0 if checkers.turn_is_red() else 1
	if game == GAME_DOMINOES:
		return dominoes.current_seat
	return 0


func is_current_human() -> bool:
	var s := current_seat()
	if s < 0 or s >= seats.size():
		return false
	return bool(seats[s]["is_human"])


func current_character() -> Dictionary:
	var s := current_seat()
	if s < 0 or s >= seats.size():
		return {}
	return seats[s]["character"]


func seat_label(seat_index: int) -> String:
	if seat_index < 0 or seat_index >= seats.size():
		return ""
	var name: String = str(seats[seat_index]["character"].get("name", "Guest"))
	if game == GAME_CHESS:
		var side := "White" if seat_index == 0 else "Black"
		return "%s (%s)" % [name, side]
	if game == GAME_CHECKERS:
		var side2 := "Red" if seat_index == 0 else "Black"
		return "%s (%s)" % [name, side2]
	var team := "Gold" if seat_index % 2 == 0 else "Silver"
	return "%s (%s team)" % [name, team]


func legal_moves() -> Array:
	if not _started or _is_over():
		return []
	if game == GAME_CHESS:
		return chess.legal_moves()
	if game == GAME_CHECKERS:
		return checkers.legal_moves()
	if game == GAME_DOMINOES:
		return dominoes.legal_plays()
	return []


func try_move(move: Dictionary) -> Dictionary:
	if not _started:
		return {"ok": false, "error": "No game is sitting at this table yet."}
	if _is_over():
		return {"ok": false, "error": "This game is already over."}
	if not is_current_human():
		return {"ok": false, "error": "It is not your turn. Switch into this seat to play it."}
	return _apply_player_move(move)


func _apply_player_move(move: Dictionary) -> Dictionary:
	var seat := current_seat()
	var r: Dictionary = {}
	if game == GAME_CHESS:
		r = chess.make_move(move)
	elif game == GAME_CHECKERS:
		r = checkers.make_move(move)
	elif game == GAME_DOMINOES:
		var action := str(move.get("action", "play"))
		if action == "pass":
			r = dominoes.pass_turn(seat)
		elif action == "draw":
			r = dominoes.draw_one(seat)
		else:
			var tile: Vector2i = _tile_from(move)
			r = dominoes.play(seat, tile, str(move.get("end", "")))
	else:
		return {"ok": false, "error": "Unknown game."}
	if not r.get("ok", false):
		return r
	var desc: String = str(r.get("description", "A move was made."))
	move_made.emit(r.get("move", move), seat, desc)
	_after_move(r)
	return r


func _tile_from(move: Dictionary) -> Vector2i:
	if move.has("tile") and move["tile"] is Vector2i:
		return move["tile"]
	if move.has("tile") and move["tile"] is Array:
		var a: Array = move["tile"]
		return Vector2i(int(a[0]), int(a[1]))
	if move.has("a") and move.has("b"):
		return Vector2i(int(move["a"]), int(move["b"]))
	return Vector2i(-1, -1)


func play_ai_if_needed() -> Dictionary:
	## If the current seat is AI and the game is not over, pick and play one move.
	## The UI should call this after a human move (or on a timer) so the board
	## can animate between signals. Returns {} if nothing was played.
	if not _started or _is_over():
		return {}
	if is_current_human():
		return {}
	return _play_one_ai()


func play_until_human_or_over(max_steps: int = 64) -> void:
	## Keep playing AI seats until the human must move, or the game ends.
	var steps := 0
	while _started and (not _is_over()) and (not is_current_human()) and steps < max_steps:
		var r := _play_one_ai()
		if r.is_empty() or not r.get("ok", false):
			break
		steps += 1
		# Dominoes draw does not always advance the seat; allow more steps.
		if game == GAME_DOMINOES:
			max_steps = maxi(max_steps, 128)


func _play_one_ai() -> Dictionary:
	var seat := current_seat()
	var level: int = int(seats[seat]["ai_level"])
	var r: Dictionary = {}
	var recorded: Dictionary = {}
	if game == GAME_CHESS:
		var mv: Dictionary = ai.choose_chess(chess, level)
		if mv.is_empty():
			return {}
		r = chess.make_move(mv)
		recorded = r.get("move", mv)
	elif game == GAME_CHECKERS:
		var mv2: Dictionary = ai.choose_checkers(checkers, level)
		if mv2.is_empty():
			return {}
		r = checkers.make_move(mv2)
		recorded = r.get("move", mv2)
	elif game == GAME_DOMINOES:
		var choice: Dictionary = ai.choose_dominoes(dominoes, level)
		var action := str(choice.get("action", "pass"))
		if action == "draw":
			r = dominoes.draw_one(seat)
			recorded = choice
		elif action == "play":
			r = dominoes.play(seat, choice["tile"], str(choice.get("end", "")))
			recorded = choice
		else:
			r = dominoes.pass_turn(seat)
			recorded = choice
	if not r.get("ok", false):
		return r
	var desc: String = str(r.get("description", "The computer made a move."))
	move_made.emit(recorded, seat, desc)
	_after_move(r)
	return r


func _after_move(_r: Dictionary) -> void:
	# Dominoes may end a hand but not the match. Start the next hand automatically
	# so the table keeps going until a team reaches the target.
	if game == GAME_DOMINOES and dominoes.hand_over and not dominoes.game_finished:
		dominoes.new_hand()
	if _is_over():
		last_result = _current_result()
		game_over.emit(last_result)
	else:
		_emit_turn()


func _is_over() -> bool:
	if not _started:
		return false
	if game == GAME_CHESS:
		return chess.game_over()
	if game == GAME_CHECKERS:
		return checkers.game_over()
	if game == GAME_DOMINOES:
		return dominoes.game_finished
	return false


func _current_result() -> Dictionary:
	if game == GAME_CHESS:
		return chess.result()
	if game == GAME_CHECKERS:
		return checkers.result()
	return dominoes.result()


func _emit_turn() -> void:
	var s := current_seat()
	var ch: Dictionary = current_character()
	turn_changed.emit(s, ch, is_current_human())


func status_text() -> String:
	if not _started:
		return "This table is empty."
	if _is_over():
		return str(_current_result().get("text", "The game is over."))
	var name: String = str(current_character().get("name", "Guest"))
	if game == GAME_CHESS:
		var extra := " Check!" if chess.in_check() else ""
		return "%s to move (%s).%s" % [name, chess.turn_name(), extra]
	if game == GAME_CHECKERS:
		return "%s to move (%s)." % [name, checkers.turn_name()]
	var scores := "Gold %s, Silver %s" % [
		TavernSafe.number_text(int(dominoes.team_score[0])),
		TavernSafe.number_text(int(dominoes.team_score[1]))
	]
	return "%s to play. %s." % [name, scores]
