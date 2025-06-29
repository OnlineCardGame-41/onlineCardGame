extends Node

signal turn_started(pid:int, time_left:float)
signal card_drawn(pid:int, card:CardDeck)     # CardDeck.Color
signal card_played(pid:int, card:CardDeck)
signal board_cleared(pid:int, seq:Array[int])
signal match_ended(winner_pid:int)

@export var turn_time := 30.0            # сек на ход

var players : PackedInt32Array
var hands : Dictionary        # pid → Array[int]
var boards : Dictionary       # pid → Array[int]
var active_idx := 0           # чей ход в players
@onready var turn_timer := $TurnTimer    # Node «Timer»




@rpc("authority", "call_local")
func start_match(pids:PackedInt32Array) -> void:
	if not is_multiplayer_authority():
		return
	players = pids
	for pid in players:
		hands[pid]  = []
		boards[pid] = []
		for i in range(4):
			hands[pid].append(CardDeck.draw())
	_begin_turn(0)

func _begin_turn(idx:int) -> void:
	active_idx = idx
	var pid = players[active_idx]
	emit_signal("turn_started", pid, turn_time)
	turn_timer.start(turn_time)

@rpc("any_peer")
func request_draw() -> void:
	if multiplayer.get_remote_sender_id() != players[active_idx]:
		return
	_server_draw(players[active_idx])

func _server_draw(pid:int) -> void:
	var c := CardDeck.draw()
	hands[pid].append(c)
	emit_signal("card_drawn", pid, c)

@rpc("any_peer")
func request_play(card_idx:int, to_board:bool) -> void:
	var pid := multiplayer.get_remote_sender_id()
	if pid != players[active_idx]:
		return
	var c = hands[pid].pop_at(card_idx)
	if to_board:
		boards[pid].append(c)
		emit_signal("card_played", pid, c)
	else:
		_resolve_board(pid)
	_check_victory(pid)
	_begin_turn((active_idx + 1) % players.size())

func _resolve_board(pid:int) -> void:
	var seq = boards[pid]
	boards[pid] = []
	emit_signal("board_cleared", pid, seq)
	if seq.size() > 3:               # заглушка «> 3 карт»
		_discard_one(pid)
		_others_draw(pid)

func _discard_one(pid:int) -> void:
	if hands[pid].size() > 0:
		hands[pid].pop_back()

func _others_draw(except_pid:int) -> void:
	for p in players:
		if p != except_pid:
			_server_draw(p)

func _check_victory(pid:int) -> void:
	if hands[pid].is_empty() and boards[pid].is_empty():
		emit_signal("match_ended", pid)
		rpc("match_ended", pid)      # уведомить всех
