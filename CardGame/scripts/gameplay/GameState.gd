class_name GameState
extends Node

signal turn_started(pid: int, time_left: float)
signal card_drawn(pid: int, card: CardDeck.CardColor)
signal card_played(pid: int, card: CardDeck.CardColor)
signal board_cleared(pid: int, seq: Array)
signal match_ended(winner_pid: int)

signal shield_changed(pid: int, count: int)
signal curse_added(pid: int, turns: int)      # новое проклятье

@export var turn_time := 40.0  # секунд на ход

var players: PackedInt32Array
var hands: Dictionary = {}
var boards: Dictionary = {}
var shields: Dictionary = {}         # pid -> shield count
var curses: Dictionary = {}   # pid -> [turns]
var active_idx = 0
@onready var turn_timer := $"../TurnTimer"
var pv: Control
# ---------------------------------------------------------------------------
# Match lifecycle
# ---------------------------------------------------------------------------

@rpc("authority", "call_local")
func start_match(pids: PackedInt32Array) -> void:
	players = pids
	for pid in players:
		hands[pid] = []
		boards[pid] = []
		shields[pid] = 0
		curses[pid] = []
		if multiplayer.is_server():
			for _i in range(5):
				_draw_card(pid)
	if multiplayer.is_server():
		_begin_turn.rpc(0)

@rpc("any_peer", "call_local")
func _begin_turn(idx: int) -> void:
	active_idx = idx
	var pid = players[active_idx]

	# --- process curses only on the server ----------------------------------
	if multiplayer.is_server():
		_process_curses(pid)

	turn_timer.stop()
	emit_signal("turn_started", pid, turn_time)
	turn_timer.start(turn_time)

# ---------------------------------------------------------------------------
# Curses helper
# ---------------------------------------------------------------------------

func _process_curses(pid: int) -> void:
	var list = curses.get(pid, [])
	var extra = list.size()
	if extra > 0:
		for _i in range(extra):
			_draw_card(pid)

	var updated = []
	for turns in list:
		var t = turns - 1
		if t > 0:
			updated.append(t)
	curses[pid] = updated
	rpc("_sync_curses", pid, updated)

@rpc("any_peer")
func _sync_curses(pid: int, list: Array) -> void:
	curses[pid] = list.duplicate()

# ---------------------------------------------------------------------------
# Input requests (only allowed from active player)
# ---------------------------------------------------------------------------


func request_draw() -> void:
	if multiplayer.get_unique_id() != players[active_idx]:
		return
	_draw_card(players[active_idx])

var wait = false
func request_play(card_idx: int, to_board: bool) -> void:
	var pid = multiplayer.get_unique_id()
	if pid != players[active_idx]:
		return
	if wait:
		return
	wait = true
	if to_board:
		var card = hands[pid][card_idx]
		_play_card(pid, card)
	else:
		await _resolve_board(pid)

	_check_victory(pid)
	wait = false
	_begin_turn.rpc((active_idx + 1) % players.size())
	


func finish() -> void:
	var pid := multiplayer.get_remote_sender_id()
	if pid != players[active_idx]:
		return
	_begin_turn.rpc((active_idx + 1) % players.size())

# ---------------------------------------------------------------------------
# Shared (server + client) state mutators
# ---------------------------------------------------------------------------

@rpc("any_peer", "call_local")
func _apply_draw(pid: int, card: CardDeck.CardColor) -> void:
	if not hands.has(pid):
		hands[pid] = []
	hands[pid].append(card)
	emit_signal("card_drawn", pid, card)

func _draw_card(pid: int) -> void:
	var card = CardDeck.draw()
	rpc("_apply_draw", pid, card)

@rpc("any_peer", "call_local")
func _apply_card_played(pid: int, card: int) -> void:
	if not boards.has(pid):
		boards[pid] = []
	boards[pid].append(card)

	var idx = hands[pid].find(card)
	if idx != -1:
		hands[pid].remove_at(idx)

	emit_signal("card_played", pid, card)

func _play_card(pid: int, card: int) -> void:
	rpc("_apply_card_played", pid, card)

@rpc("any_peer", "call_local")
func _apply_board_cleared(pid: int, seq: Array) -> void:
	boards[pid] = []
	emit_signal("board_cleared", pid, seq)

func _resolve_board(pid: int) -> bool:
	var seq = boards[pid].duplicate()
	await match_cards(seq)
	rpc("_apply_board_cleared", pid, seq)
	return true

@rpc("any_peer", "call_local")
func _apply_match_ended(winner_pid: int) -> void:
	emit_signal("match_ended", winner_pid)

func _check_victory(pid: int) -> void:
	if hands[pid].is_empty() and boards[pid].is_empty():
		_apply_match_ended(pid)
		rpc("_apply_match_ended", pid)

# ---------------------------------------------------------------------------
# Shields & Curses
# ---------------------------------------------------------------------------

@rpc("any_peer", "call_local")
func _apply_shield(pid: int, amount: int = 1) -> void:
	var count = shields.get(pid, 0) + amount
	shields[pid] = count
	emit_signal("shield_changed", pid, count)

func give_shield(pid: int, amount: int = 1) -> void:
	rpc("_apply_shield", pid, amount)

@rpc("any_peer", "call_local")
func _apply_curse(pid: int, turns: int) -> void:
	if not curses.has(pid):
		curses[pid] = []
	curses[pid].append(turns)
	emit_signal("curse_added", pid, turns)

func add_curse(pid: int, turns: int = 3) -> void:
	rpc("_apply_curse", pid, turns)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _set_player_view(pv: Control):
	self.pv = pv

func _discard_last(pid: int) -> void:
	if not hands[pid].is_empty():
		hands[pid].pop_back()

func _others_draw(except_pid: int) -> void:
	for p in players:
		if p != except_pid:
			_draw_card(p)

# 0 – R, 1 – Y, 2 – B
func match_cards(seq: Array) -> void:
	var key = "".join(seq)
	match key:
		#"00": print("00")
		#"01": print("01")
		#"02": print("02")
		#"10": print("10")
		#"11": print("11")
		#"12": print("12")
		#"20": print("20")
		#"21": print("21")
		"22":
			give_shield(multiplayer.get_unique_id()) 
			print("22")
		"000": 
			_others_draw(-1)
			print("000")
		#"001": print("001")
		#"002": print("002")
		#"010": print("010")
		#"011": print("011")
		#"012": print("012")
		#"020": print("020")
		#"021": print("021")
		#"022": print("022")
		#"100": print("100")
		#"101": print("101")
		#"102": print("102")
		#"110": print("110")
		#"111": print("111")
		#"112": print("112")
		#"120": print("120")
		#"121": print("121")
		#"122": print("122")
		#"200": print("200")
		"201": 
			for p in players:
				add_curse(p)
			give_shield(multiplayer.get_unique_id())
			print("201")
		#"202": print("202")
		#"210": print("210")
		#"211": print("211")
		#"212": print("212")
		#"220": print("220")
		#"221": print("221")
		#"222": print("222")
		_:
			var pid = await pv.player_picked
			if not pid:
				return
			print("Player Picked", pid)
			_draw_card(pid)
			print("no match")
