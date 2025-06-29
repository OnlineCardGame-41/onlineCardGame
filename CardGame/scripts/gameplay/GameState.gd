extends Node

signal turn_started(pid: int, time_left: float)
signal card_drawn(pid: int, card: CardDeck.CardColor)  # CardDeck.CardColor
signal card_played(pid: int, card: CardDeck.CardColor)
signal board_cleared(pid: int, seq: Array[int])
signal match_ended(winner_pid: int)

@export var turn_time := 30.0  # сек на ход

var players: PackedInt32Array
var hands: Dictionary  # pid → Array[int]
var boards: Dictionary  # pid → Array[int]
var active_idx := 0  # чей ход в players
@onready var turn_timer := $"../TurnTimer"  # Node «Timer»

@rpc("authority", "call_local")
func start_match(pids: PackedInt32Array):
	print(pids, multiplayer.get_unique_id())
	players = pids
	rpc("_begin_turn", 0)
	for pid in players:
		hands[pid] = []
		boards[pid] = []
		if multiplayer.is_server():
			for i in range(5):
				_server_draw(pid)
	print(hands, multiplayer.get_unique_id())


@rpc("any_peer", "call_local")
func _begin_turn(idx: int) -> void:
	active_idx = idx
	var pid = players[active_idx]
	emit_signal("turn_started", pid, turn_time)
	turn_timer.start(turn_time)


@rpc("any_peer")
func request_draw() -> void:
	if multiplayer.get_remote_sender_id() != players[active_idx]:
		return
	_server_draw(players[active_idx])


func _server_draw(pid: int) -> void:
	var c = CardDeck.draw()
	hands[pid].append(c)
	emit_signal("card_drawn", pid, c)
	rpc("_client_draw", pid, c)


@rpc("any_peer")
func _client_draw(pid: int, color: CardDeck.CardColor):
	if not hands.has(pid):
		hands[pid] = []
	hands[pid].append(color)
	emit_signal("card_drawn", pid, color)


@rpc("any_peer")
func request_play(card_idx: int, to_board: bool) -> void:
	var pid = multiplayer.get_remote_sender_id()
	if pid != players[active_idx]:
		return
	if to_board:
		var c = hands[pid].pop_at(card_idx)
		_server_card_played(pid, c)
	else:
		_resolve_board(pid)

	_check_victory(pid)
	_begin_turn.rpc((active_idx + 1) % players.size())


@rpc("any_peer")
func finish():
	var pid = multiplayer.get_remote_sender_id()
	if pid != players[active_idx]:
		return
	_begin_turn.rpc((active_idx + 1) % players.size())


@rpc("any_peer", "call_local")
func _resolve_board(pid: int) -> void:
	var seq = boards[pid]
	boards[pid] = []
	_server_board_cleared(pid, seq)

	if seq.size() >= 3:
		_discard_one(pid)
		_others_draw(pid)


func _discard_one(pid: int) -> void:
	if not multiplayer.is_server():
		return
	if hands[pid].size() > 0:
		hands[pid].pop_back()


func _others_draw(except_pid: int) -> void:
	if not multiplayer.is_server():
		return
	for p in players:
		if p != except_pid:
			_server_draw(p)


func _check_victory(pid: int) -> void:
	if hands[pid].is_empty() and boards[pid].is_empty():
		_server_match_ended(pid)


func _server_card_played(pid: int, card: int) -> void:
	boards[pid].append(card)
	emit_signal("card_played", pid, card)
	rpc("_client_card_played", pid, card)


@rpc("any_peer")
func _client_card_played(pid: int, card: int) -> void:
	if not boards.has(pid):
		boards[pid] = []

	var idx = hands[pid].find(card)
	if idx != -1:
		boards[pid].append(card)
		hands[pid].remove_at(idx)

	emit_signal("card_played", pid, card)


func _server_board_cleared(pid: int, seq: Array) -> void:
	boards[pid] = []
	emit_signal("board_cleared", pid, seq)
	rpc("_client_board_cleared", pid, seq)


@rpc("any_peer")
func _client_board_cleared(pid: int, seq: Array) -> void:
	boards[pid] = []
	emit_signal("board_cleared", pid, seq)


func _server_match_ended(winner_pid: int) -> void:
	emit_signal("match_ended", winner_pid)
	rpc("_client_match_ended", winner_pid)


@rpc("any_peer")
func _client_match_ended(winner_pid: int) -> void:
	emit_signal("match_ended", winner_pid)
