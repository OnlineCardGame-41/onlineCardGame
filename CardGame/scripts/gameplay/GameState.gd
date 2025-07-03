class_name GameState
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
	if multiplayer.get_unique_id() != players[active_idx]:
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
	#var pid = multiplayer.get_remote_sender_id()
	var pid = multiplayer.get_unique_id()
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
	_server_board_cleared(pid, seq)


func _server_discard_card(discard_pid: int) -> void:
	if not hands[discard_pid].is_empty():
		hands[discard_pid].pop_back()


func _others_draw(except_pid: int) -> void:
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
	match_cards(seq)
	emit_signal("board_cleared", pid, seq)
	rpc("_client_board_cleared", pid, seq)

#0-R, 1-Y, 2-B
func match_cards(seq: Array):
	match seq:
		[0, 0, 0]: print("000")
		[0, 0, 1]: print("001")
		[0, 0, 2]: print("002")
		[0, 1, 0]: print("010")
		[0, 1, 1]: print("011")
		[0, 1, 2]: print("012")
		[0, 2, 0]: print("020")
		[0, 2, 1]: print("021")
		[0, 2, 2]: print("022")
		[1, 0, 0]: print("100")
		[1, 0, 1]: print("101")
		[1, 0, 2]: print("102")
		[1, 1, 0]: print("110")
		[1, 1, 1]: print("111")
		[1, 1, 2]: print("112")
		[1, 2, 0]: print("120")
		[1, 2, 1]: print("121")
		[1, 2, 2]: print("122")
		[2, 0, 0]: print("200")
		[2, 0, 1]: print("201")
		[2, 0, 2]: print("202")
		[2, 1, 0]: print("210")
		[2, 1, 1]: print("211")
		[2, 1, 2]: print("212")
		[2, 2, 0]: print("220")
		[2, 2, 1]: print("221")
		[2, 2, 2]: print("222")
		_:
			print("no match")




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
