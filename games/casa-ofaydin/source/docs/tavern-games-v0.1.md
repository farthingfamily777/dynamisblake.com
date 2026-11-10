# Tavern games v0.1

Logic and AI for games played inside Casa O'Faydin, at the Port Paradise taverns. Written 2026-11-10, about 1:08 AM CT, from Blake's request: chess and checkers must be playable inside the RPG against characters you created, and you can play dominoes with four of those characters. The player can switch into any character at any time.

Theatron owns the visuals and table props (planned: chess in the high-class tavern, dominoes and checkers in the low-class shack, in `/workspace/casa-game/godot-art`). This folder is logic only. `export_presets.cfg` and the site repo were not changed. `main.gd` has one commented hook and no new code.

Seats take the arrival-forms character record from `ArrivalForms.new_record()` (`godot/scripts/arrival_forms.gd`, spec in `character-creation-v0.1.md`). The class key is `class_id`. Optional `ai_level` or `skill` (0-10) can override the class-based AI strength. A smaller `{id, name, class_id, race}` dictionary also works.

## Files

All scripts are Godot 4.3 GDScript, Compatibility / web-safe, no threads.

- `godot/scripts/tavern/chess_rules.gd` — full legal chess (castling, en passant, promotion, check, checkmate, stalemate, 50-move, threefold, insufficient material). Written fresh. Legal-move counts were checked against the standard start-position numbers also used by the Game Room's chess.js 0.13.4 (BSD).
- `godot/scripts/tavern/checkers_rules.gd` — forced captures, multi-jumps, and kings, ported from `games/shared/checkers-engine.js`. A jump that crowns a piece ends that turn. Quiet games draw after 80 plies with no jump, or if the same position comes up three times, so two-king chases cannot run forever in a browser.
- `godot/scripts/tavern/dominoes_rules.gd` — four-player partnership Block Dominoes, double-six set, 7 tiles each. Seats 0 and 2 are the Gold team; seats 1 and 3 are the Silver team. The double-six leads the first hand. Pass when you cannot play. Going out scores the other team's remaining pips (not your partner's). A blocked table: the team with fewer pips scores the difference; a pip tie scores nothing. Games go to 100 or 150 (`set_target`). Draw mode is optional: deal 5 tiles each, draw from the boneyard until two tiles remain, then pass. Layout has two ends only (no spinners). If Draw mode hides the double-six in the boneyard on the first hand, the highest double leads instead.
- `godot/scripts/tavern/tavern_ai.gd` — easy, medium, and hard for each game.
- `godot/scripts/tavern/tavern_table.gd` — seats, human/AI flags, mid-game switching, turn loop, and signals.
- `godot/scripts/tavern/tavern_safe.gd` — display helper so a forbidden digit run never prints.
- `godot/scripts/tavern/tavern_tests.gd` — headless rules tests plus 20 AI-vs-AI games of each kind.

Run the tests with:

```
/tmp/Godot_v4.3-stable_linux.x86_64 --headless --path /workspace/casa-game/godot --script res://scripts/tavern/tavern_tests.gd
```

## Character record

```
{
  "id": "ada-01",
  "name": "Ada",
  "class_id": "merchant",
  "race": "human",
  "ai_level": "medium",   # optional: "easy" | "medium" | "hard" (or 0, 1, 2)
  "skill": 7              # optional: 0-4 easy, 5-7 medium, 8-10 hard
}
```

If neither `ai_level` nor `skill` is set, `class_id` is used: sage / mage / wizard / merchant / governor / scholar → hard; pilgrim / fighter / soldier / ork / trooper / thief / assassin / rogue / vampire → medium; child / beginner / farmer / bandit → easy; anyone else → medium.

## AI strength

- **Chess easy:** a random legal move.
- **Chess medium:** one-ply look at material (and a small placement bonus), with a little jitter so games vary.
- **Chess hard:** alpha-beta search, default depth 2 (set `ai.chess_hard_depth` to 3 if you want a stronger but slower move). No threads. Captures and promotions are tried first. Fast enough for a phone browser at depth 2.
- **Checkers easy:** a random legal move (jumps are already forced by the rules).
- **Checkers medium:** one-ply piece and king evaluation.
- **Checkers hard:** alpha-beta, default depth 4 (`ai.checkers_hard_depth`).
- **Dominoes easy:** a random legal tile, or draw / pass when required.
- **Dominoes medium:** play the highest-pip legal tile, with a slight preference for spending a double.
- **Dominoes hard:** tries each legal tile, prefers going out, emptying pips, and leaving an end the next opponent cannot play on.

## TavernTable API (for Theatron's UI)

Create one table per felt:

```
var table := TavernTable.new()
table.setup_chess(characters, human_seat)
# or table.setup_checkers(characters, human_seat)
# or table.setup_dominoes(characters, human_seat, 100, "block")  # target 100 or 150; "block" or "draw"
```

`characters` is an array of character records, one per seat (2 for chess and checkers, 4 for dominoes). Seat 0 is White / Red / the first Gold partner.

Useful methods:

- `assign_character(seat_index, character)` — drop a new person into a seat without resetting the board.
- `switch_human(seat_index)` — the player becomes that character mid-game. The seat they left becomes AI and keeps its pieces or tiles. Emits `turn_changed`.
- `try_move(move)` — only if the current seat is human. Chess: `{from, to, promotion?}` or `{uci}`. Checkers: `{from: {r,c}, steps: [{r,c}, ...]}`. Dominoes: `{action: "play"|"pass"|"draw", tile: Vector2i or [a,b], end: "left"|"right"|"first"}`.
- `legal_moves()` — legal options for the current seat, in the same shape as the move you pass back.
- `play_ai_if_needed()` — play one AI move if it is an AI seat's turn. Call this from the UI after a human move, or on a short timer, so you can animate between signals. Returns `{}` if nothing was played.
- `play_until_human_or_over()` — keeps going through AI seats until the human must move, or the game ends.
- `current_seat()`, `current_character()`, `is_current_human()`, `seat_label(i)`, `status_text()`.
- `chess`, `checkers`, `dominoes` — the live rules objects, if you need the board, hands, or layout.

Chess squares are algebraic (`e2`, `e4`), with `a1` at index 0. Checkers rows run 0-7 with row 0 at the far side (Black's back rank) and dark squares on `(r+c) odd`, same as the Game Room engine. Dominoes tiles are `Vector2i` with the smaller pip first; `tile_text` and `layout_text` are ready for on-screen labels.

When a dominoes hand ends and the match is not over, the table starts the next hand on its own.

## Signals the UI should connect

```
table.move_made.connect(_on_move_made)       # (move, seat_index, description)
table.turn_changed.connect(_on_turn_changed) # (seat_index, character, is_human)
table.game_over.connect(_on_game_over)       # (result)
```

- `move_made` — a legal move just landed, from a human or the AI. `description` is plain English, written so ages 7, 9, 87, and 90 can follow it ("Ada's pawn moves from e2 to e4.").
- `turn_changed` — it is now this seat's turn. `is_human` is true if the player is currently in that seat. If false, call `play_ai_if_needed()` when you are ready for the next computer move.
- `game_over` — `result` is `{over, winner, reason, text}` and, for dominoes, `gold` and `silver` scores. Show `text` as-is.

Suggested flow: connect the three signals, call `setup_*`, show the board, and if `is_current_human()` wait for a tap; otherwise call `play_ai_if_needed()` after your animation.

## House rule: forbidden digit run

The consecutive digits six-six-six must never appear in a label, score, tile display, or file. `TavernSafe.number_text(n)` prints ordinary numbers as digits, but if that run would appear it inserts spaces (`6 6 6`) so the characters never sit together. Team scores that would store that run are also bumped by one point in `DominoesRules._finish_hand`. The source files themselves never include that digit run; the helper builds the pattern at runtime with `"6".repeat(3)`. Use `TavernSafe.number_text` for every on-screen score, seat number, and pip total.

## What this does not do

It does not draw the tables, pieces, or paper UI. It does not push anything to dynamisblake.com. It does not change export settings. Hooking the tables into the 3D tavern rooms is Theatron's pass, using the API above.
