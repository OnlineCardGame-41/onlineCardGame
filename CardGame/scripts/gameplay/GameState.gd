class_name GameState
extends Node

signal turn_started(pid: int, time_left: float)
signal card_drawn(pid: int, card: CardDeck.CardColor)
signal card_played(pid: int, card: CardDeck.CardColor)
signal board_cleared(pid: int, seq: Array)
signal match_ended(winner_pid: int)
signal shield_changed(pid: int, count: int)
signal curse_added(pid: int, turns: int)      

@export var turn_time := 40.0  # секунд на ход

var players: PackedInt32Array
var hands: Dictionary = {}
var boards: Dictionary = {}
var shields: Dictionary = {}        
var curses: Dictionary = {}   
var skip_turns: Dictionary = {}      
var draw_bonus: Dictionary = {}     
var active_idx = 0
@onready var turn_timer := $"../TurnTimer"
@onready var ui: CanvasLayer = $"../UI"
# ---------------------------------------------------------------------------
# Match lifecycle
# ---------------------------------------------------------------------------

@rpc("authority", "call_local")
func start_match(pids: PackedInt32Array) -> void:
	players = pids
	ui.initial()
	print("IAHTEYOU", players)
	for pid in players:
		print(pid, "KEK")
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
	
	if skip_turns.get(pid, 0) > 0:
		skip_turns[pid] -= 1
		_begin_turn.rpc((active_idx + 1) % players.size())
		return
		
	# --- process curses only on the server ----------------------------------
	if multiplayer.is_server():
		_process_curses(pid)

	turn_timer.stop()
	emit_signal("turn_started", pid, turn_time)
	turn_timer.start(turn_time)

func _process(delta: float) -> void:
	pass

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
func request_play(card_idx: int, to_board: bool, is_left: bool) -> void:
	var pid = multiplayer.get_unique_id()
	print(players)
	if pid != players[active_idx]:
		return
	if wait:
		return
	wait = true
	if to_board:
		var card = hands[pid][card_idx]
		_play_card(pid, card, is_left)
	else:
		await _resolve_board(pid)

	_check_victory(pid)
	wait = false
	print("Hands: ",hands)
	print("Boards: ", boards)
	print("Card idx: ", card_idx)
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
	var current = shields.get(pid, 0)
	if current > 0:
		shields[pid] = current - 1
		emit_signal("shield_changed", pid, shields[pid])
		print("Shield blocked draw for player", pid)
		return
		
	var extra = 0
	if draw_bonus.has(pid):
		var data = draw_bonus[pid]
		extra = data[0]
		data[1] -= 1
		if data[1] <= 0:
			draw_bonus.erase(pid)
		else:
			draw_bonus[pid] = data

	for _i in range(1 + extra):
		var card = CardDeck.draw()
		rpc("_apply_draw", pid, card)

@rpc("any_peer", "call_local")
func _apply_card_played(pid: int, card: int, is_left: bool) -> void:
	
	if not boards.has(pid):
		boards[pid] = []
	if is_left:
		boards[pid].push_front(card)
	else:
		boards[pid].push_back(card)
		
	var idx = hands[pid].find(card)
	if idx != -1:
		hands[pid].remove_at(idx)
	print("card_played")
	emit_signal("card_played", pid, card)

func _play_card(pid: int, card: int, is_left: bool) -> void:
	rpc("_apply_card_played", pid, card, is_left)

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

func _set_player_view(ui: CanvasLayer):
	self.ui = ui

func _discard_last(pid: int) -> void:
	if not hands[pid].is_empty():
		hands[pid].pop_back()

func _others_draw(except_pid: int) -> void:
	for p in players:
		if p != except_pid:
			_draw_card(p)
			
#NEW

func choose_target(pool: Array, acting_pid: int = multiplayer.get_unique_id()) -> int:
	if acting_pid == multiplayer.get_unique_id():
		var pid = await ui.player_picked
		while pid not in pool:
			pid = await ui.player_picked
		return pid
	else:
		# Заглушка
		return pool[0]

func choose_targets(pool: Array, k: int) -> Array:
	var res: Array = []
	while res.size() < k and not pool.is_empty():
		var pid = await ui.player_picked
		if pid in pool and pid not in res:
			res.append(pid)
	return res

func draw_colored_card(pid: int, color: int, n: int = 1) -> void:
	for _i in range(n):
		rpc("_apply_draw", pid, color)

func grant_draw_bonus(pid: int, bonus: int, uses: int) -> void:
	draw_bonus[pid] = [bonus, uses]

func skip_turn(pid: int, turns: int = 1) -> void:
	skip_turns[pid] = skip_turns.get(pid, 0) + turns

func discard_table(pid: int) -> void:
	boards[pid] = []
	emit_signal("board_cleared", pid, [])

func discard_table_color(pid: int, color: int) -> void:
	var keep: Array = []
	for c in boards[pid]:
		if c != color:
			keep.append(c)
	boards[pid] = keep
	emit_signal("board_cleared", pid, [])

func remove_shield(pid: int, amount: int = 1) -> void:
	shields[pid] = max(shields.get(pid, 0) - amount, 0)
	emit_signal("shield_changed", pid, shields[pid])

func reduce_shield_duration(pid: int, turns: int = 1) -> void:
	remove_shield(pid, turns)

func discard_from_spell(pid: int, selected_by_attacker := true, draw_if_empty := true) -> void:
	if boards[pid].is_empty():
		if draw_if_empty:
			_draw_card(pid)
		return
	var idx = selected_by_attacker and 0 or boards[pid].size() - 1
	boards[pid].remove_at(idx)

func steal_spell_card(victim: int, thief: int) -> void:
	if boards[victim].is_empty():
		return
	var card = boards[victim].pop_back()
	boards[thief].append(card)
	emit_signal("card_played", thief, card)

func discard_table_by_shield(pid: int) -> void:
	var cnt = shields.get(pid, 0)
	if cnt == 0:
		remove_shield(pid, 1)
		return
	for _i in range(min(cnt, boards[pid].size())):
		boards[pid].pop_back()

func discard_half_hand(pid: int) -> int:
	var to_discard := int(floor(hands[pid].size() / 2))
	for _i in range(to_discard):
		hands[pid].pop_back()
	return to_discard

func hand_size(pid: int) -> int:
	return hands[pid].size()

func transfer_curse(src: int, dst: int, charges: int = 1) -> void:
	remove_curse(src, charges)
	for _i in range(charges):
		add_curse(dst)

func remove_curse(pid: int, charges):
	if not curses.has(pid):
		return
	if charges == INF:
		curses[pid] = []
	else:
		for _i in range(min(charges, curses[pid].size())):
			curses[pid].pop_back()
	rpc("_sync_curses", pid, curses[pid])

func remove_curse_all(pid: int) -> void:
	curses[pid] = []
	rpc("_sync_curses", pid, [])
#NEW

# 0 – R, 1 – Y, 2 – B
func match_cards(seq: Array) -> void:
	var key = "".join(seq)
	var pid_self := multiplayer.get_unique_id()
	var opponents = players.duplicate()
	opponents.remove_at(opponents.find(pid_self))

	match key:
		"00":
			var tgt = await choose_target(opponents)
			_draw_card(tgt)

		"01":
			var tgt = await choose_target(opponents)
			draw_colored_card(tgt, CardDeck.CardColor.RED)

		"02":
			var tgt = await choose_target(opponents)
			grant_draw_bonus(tgt, 1, 999)   # пока простой вариант
			# Пока не сделано
		"10":
			var tgt = await choose_target(opponents)
			discard_from_spell(tgt, true, true)
			# В теории работает
		"11":
			var tgt = await choose_target(opponents)
			skip_turn(tgt, 1)

		"12":
			var tgt = await choose_target(opponents)
			steal_spell_card(tgt, pid_self)
			# В теории работает
		"20":
			var tgt = await choose_target(opponents)
			grant_draw_bonus(tgt, 1, 2)

		"21":
			var tgt = await choose_target(opponents)
			skip_turn(tgt, 1)   

		"22":
			give_shield(pid_self, 1)

		"000":
			for p in players:
				_draw_card(p)

		"001":
			var opponents_arr: Array = []          
			for p in players:
				if p != pid_self:
					opponents_arr.append(p)

			var pool: Array = opponents_arr.duplicate()
			var curr = await choose_target(pool)  

			for _i in range(players.size() + 2):
				_draw_card(curr)

				var remove_idx := pool.find(curr)
				if remove_idx != -1:
					pool.remove_at(remove_idx)

				if pool.is_empty():
					break
				curr = await choose_target(pool, curr)

		
		"002":
			var tgt = await choose_target(opponents)
			reduce_shield_duration(tgt, 1)

		"010":
			var targets: Array = []
			for p in opponents:
				if not curses[p].is_empty():
					targets.append(p)
			for t in targets:
				add_curse(t)

		"011":
			for p in players:
				discard_table_color(p, CardDeck.CardColor.YELLOW)

		"012":
			for p in players:
				discard_table(p)

		"020":
			var targets = await choose_targets(opponents, max(players.size()-1, 2))
			for t in targets:
				discard_table(t)

		"021":
			var targets = await choose_targets(opponents, players.size() - 2)
			for t in targets:
				remove_shield(t, 1)

		"022":
			var targets = await choose_targets(opponents, players.size() - 2)
			for t in targets:
				discard_table_by_shield(t)

		"100":
			# Пока не сделано
			for p in opponents:
				if not curses[p].is_empty():
					add_curse(p)

		"101":
			for p in players:
				add_curse(p)

		"102":
			# Пока не сделано
			for p in players:
				if shields.get(p, 0) > 0:
					grant_draw_bonus(p, shields[p], 1)

		"110":
			for p in players:
				discard_table_color(p, CardDeck.CardColor.RED)

		"111":
			var targets = await choose_targets(opponents, min(players.size()-1, 2))
			for t in targets:
				skip_turn(t, 2)

		"112":
			for p in players:
				discard_table_color(p, CardDeck.CardColor.BLUE)

		"120":
			var tgt = await choose_target(opponents)
			transfer_curse(pid_self, tgt, 1)

		"121":
			remove_curse(pid_self, 1)

		"122":
			var discarded = discard_half_hand(pid_self)
			if hand_size(pid_self) < discarded:
				_others_draw(-1)

		"200":
			var targets = await choose_targets(opponents, min(players.size()-1, 2))
			var grp = [pid_self] + targets
			for p in grp:
				_draw_card(p)
				give_shield(p)

		"201":
			for p in players:
				add_curse(p)
			give_shield(pid_self)

		"202":
			var tgt = await choose_target(opponents)
			remove_shield(tgt, 1)
			give_shield(pid_self)

		"210":
			#for p in players:
				#return _table_to_hand(p)
			_draw_card(pid_self)

		"211":
			var targets = await choose_targets(opponents, players.size() - 2)
			var grp = [pid_self] + targets
			for p in grp:
				_draw_card(p)
				add_curse(p)

		"212":
			# Пока не сделано
			give_shield(pid_self) 
			grant_draw_bonus(pid_self, 1, 1)

		"220":
			# Пока не сделано
			var tgt = await choose_target(opponents)
			give_shield(tgt)   

		"221":
			remove_curse_all(pid_self)

		"222":
			give_shield(pid_self, 2)

		_:
			var pid_pick = await ui.player_picked
			if pid_pick:
				_draw_card(pid_pick)
