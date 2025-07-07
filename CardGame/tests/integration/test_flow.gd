extends GutTest


var gs
var pv

# ─────────────────────────────────────────────
#  before_each: делаем draw() детерминированным
func before_each() -> void:
	# Если CardDeck доступен как singleton-autoload:
	#   stub(CardDeck, "draw").to_return(CardDeck.CardColor.RED)
	#
	# Если это обычный скрипт, укажите путь:
	var deck = preload("res://scripts/gameplay/CardDeck.gd")     # поправьте путь при необходимости
	stub(deck, "draw").to_return(deck.CardColor.RED)
	# Instantiate GameState and PlayerView
	gs = GameState.new()
	pv = PlayerView.new()
	pv.pid = 1
	# Add to scene tree for signal propagation
	get_tree().get_root().add_child(gs)
	get_tree().get_root().add_child(pv)
	# Initialize PlayerView with GameState
	pv.init(gs)
	gs.pv = pv


# ─────────────────────────────────────────────
# 1  CONNECTED-строка порождает connected(pid)
func test_client_handle_connected() -> void:
	var peer = double(SignalWsPeer).new(0)
	stub(peer, "get_msg").to_return("1|5|")   # вместо peer.get_msg = func()...
	stub(peer, "has_msg").to_return(true)     # если нужно
	stub(peer, "is_open").to_return(true)
	var client = SignalWsClient.new()
	client.peer = peer
	
	watch_signals(client)
	assert_true(client.handle_peer_msg())
	assert_signal_emit_count(client, "connected", 1)
	assert_eq(get_signal_parameters(client, "connected"), [5])


# ─────────────────────────────────────────────
# 2  JOIN → SEAL генерирует lobby_sealed(lid)
func test_client_join_then_seal() -> void:
	var peer = double(SignalWsPeer).new(0)
	var msgs := ["3|10|false", "9|10|"]            # JOIN, затем SEAL

	stub(peer, "is_open").to_return(true)
	# has_msg должен «кончаться» после второй строки
	stub(peer, "has_msg").to_call(func() -> bool:
		return not msgs.is_empty()
	)
	# get_msg каждый раз вытаскивает очередную строку
	stub(peer, "get_msg").to_call(func() -> String:
		return msgs.pop_front()
	)

	var client = SignalWsClient.new()
	client.peer = peer
	watch_signals(client)

	client.handle_peer_msg()   # JOIN
	client.handle_peer_msg()   # SEAL

	assert_signal_emit_count(client, "lobby_sealed", 1)
	assert_eq(get_signal_parameters(client, "lobby_sealed"), [10])


# ─────────────────────────────────────────────
# 3  start_match раздаёт по 5 карт каждому
func test_gamestate_start_match_deals_five() -> void:
	var gs := preload("res://scripts/gameplay/GameState.gd").new()
	var timer := Timer.new()
	timer.name = "TurnTimer"           # ← имя, которое ждёт onready-путь
	add_child(timer)                   # сначала кладём таймер
	add_child(gs)                      # потом GameState, чтобы он нашёл таймер
	await get_tree().process_frame     # дожидаемся _ready()

	stub(CardDeck, "draw").to_return(CardDeck.CardColor.RED)

	gs.players = PackedInt32Array([1, 2])
	gs.start_match(gs.players)

	assert_eq(gs.hands[1].size(), 5)
	assert_eq(gs.hands[2].size(), 5)


func test_gamestate_resolve_board_triggers_others_draw() -> void:
	# ─ узлы в реальном дереве ─────────────────────────────────
	var timer := Timer.new()
	timer.name = "TurnTimer"
	add_child_autofree(timer)

	var GameState = preload("res://scripts/gameplay/GameState.gd")
	var gs = partial_double(GameState).new()   # записываем вызовы, но логика остаётся
	add_child_autofree(gs)

	await get_tree().process_frame   # инициализируем @onready

	# ─ исходные данные ───────────────────────────────────────
	gs.players    = PackedInt32Array([1, 2])
	gs.hands      = {1: [], 2: []}
	gs.boards     = {1: [0, 0, 0], 2: []}
	gs.active_idx = 0

	# ─ заглушаем «сетевые» методы, чтобы они не мешали ───────
	stub(gs, "_others_draw").to_do_nothing()
	#  при необходимости можно так же заглушить rpc-метод:
	# stub(gs, "_server_board_cleared").to_do_nothing()

	# ─ действие ──────────────────────────────────────────────
	gs._resolve_board(1)

	# ─ проверки ──────────────────────────────────────────────
	assert_call_count(gs, "_others_draw", 1)
	assert_true(gs.boards[1].is_empty())


# ─────────────────────────────────────────────
# 5  Пустые руки и доска ➜ match_ended(winner_pid)
func test_gamestate_victory() -> void:
	var gs = preload("res://scripts/gameplay/GameState.gd").new()
	gs.players = PackedInt32Array([7])
	gs.hands   = {7: []}
	gs.boards  = {7: []}

	watch_signals(gs)
	gs._check_victory(7)

	assert_signal_emit_count(gs, "match_ended", 1)
	assert_eq(get_signal_parameters(gs, "match_ended"), [7])


func test_integration_card_drawn_updates_playerview_hand():
	# Simulate drawing for local pid
	gs._apply_draw(1, CardDeck.CardColor.YELLOW)
	# Hand UI should update
	assert_eq(pv.Hand.item_count, 1)
	assert_eq(pv.Hand.get_item_text(0), pv.card_label(CardDeck.CardColor.YELLOW))

func test_integration_card_played_updates_ui():
	# Prepare a card in hand
	gs.hands[1] = [CardDeck.CardColor.RED]
	pv._refresh_hand()
	# Emit play signal
	gs._apply_card_played(1, CardDeck.CardColor.RED)
	# UI Hand emptied, Board updated
	assert_eq(pv.Hand.item_count, 0)
	assert_true(pv.Board.get_item_text(0).ends_with("Красная"))

func test_integration_turn_started_updates_turn_label():
	# Other player's turn
	gs.emit_signal("turn_started", 2, 15.0)
	assert_eq(pv.Turn.text, "Turn of 2")
	# Local player's turn
	gs.emit_signal("turn_started", 1, 15.0)
	assert_eq(pv.Turn.text, "Your Turn")

func test_integration_player_click_emits_signal():
	# Setup multiple players
	gs.players = [1, 2]
	gs.shields = {1:0, 2:0}
	gs.curses = {1:[], 2:[]}
	gs.hands = {1:[], 2:[]}
	pv._refresh_players()
	var picked = null
	pv.connect("player_picked", self, "_on_player_picked_int", [picked])
	# Simulate click on second item (player 2)
	pv._on_players_click(1)
	assert_eq(picked, 2)

func _on_player_picked_int(pid, picked):
	picked = pid

func test_integration_refresh_players_shows_correct_metadata():
	# Ensure display metadata matches GameState
	gs.players = [1, 3]
	gs.shields = {1:1, 3:2}
	gs.curses = {1:[1], 3:[]}
	gs.hands = {1:[0,1], 3:[2]}
	pv._refresh_players()
	# Check text and metadata
	var txt0 = pv.Players.get_item_text(0)
	var meta0 = pv.Players.get_item_metadata(0)
	assert_true(txt0.find("Рука: 2") != -1 and txt0.find("Щиты: 1") != -1)
	assert_eq(meta0, 1)
	var txt1 = pv.Players.get_item_text(1)
	var meta1 = pv.Players.get_item_metadata(1)
	assert_true(txt1.find("Рука: 1") != -1 and txt1.find("Щиты: 2") != -1)
	assert_eq(meta1, 3)
=======
	
var signal_emitted := false

func _on_card_drawn_signal(pid, card):
	signal_emitted = true
	assert_eq(pid, 1)
	assert_eq(card, CardDeck.CardColor.RED)

func test_apply_draw_adds_card_and_emits_signal() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()
	
	gs.players = PackedInt32Array([1])
	gs.hands = {1: []}
	
	signal_emitted = false
	gs.connect("card_drawn", Callable(self, "_on_card_drawn_signal"))
	
	gs._apply_draw(1, CardDeck.CardColor.RED)
	
	assert_true(signal_emitted)
	assert_eq(gs.hands[1], [CardDeck.CardColor.RED])

var shield_changed_emitted := false

func _on_shield_changed_signal(pid, count):
	shield_changed_emitted = true
	assert_eq(pid, 2)
	assert_eq(count, 3)

func test_apply_shield_adds_and_emits() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()

	gs.shields = {}

	shield_changed_emitted = false
	gs.connect("shield_changed", Callable(self, "_on_shield_changed_signal"))

	gs._apply_shield(2, 3)

	assert_true(shield_changed_emitted)
	assert_eq(gs.shields[2], 3)

var curse_added_emitted := false

func _on_curse_added_signal(pid, turns):
	curse_added_emitted = true
	assert_eq(pid, 5)
	assert_eq(turns, 4)

func test_apply_curse_adds_and_emits() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()

	gs.curses = {}

	curse_added_emitted = false
	gs.connect("curse_added", Callable(self, "_on_curse_added_signal"))

	gs._apply_curse(5, 4)

	assert_true(curse_added_emitted)
	assert_eq(gs.curses[5], [4])

var match_ended_emitted := false

func _on_match_ended_signal(winner_pid):
	match_ended_emitted = true
	assert_eq(winner_pid, 9)

func test_check_victory_emits_match_ended() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()

	gs.hands = {9: []}
	gs.boards = {9: []}

	match_ended_emitted = false
	gs.connect("match_ended", Callable(self, "_on_match_ended_signal"))

	gs._check_victory(9)

	assert_true(match_ended_emitted)

var card_played_emitted := false

func _on_card_played_signal(pid, card):
	card_played_emitted = true
	assert_eq(pid, 3)
	assert_eq(card, CardDeck.CardColor.RED)

func test_apply_card_played_removes_card_from_hand_and_emits() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()

	gs.players = PackedInt32Array([3])
	gs.hands = {3: [CardDeck.CardColor.RED, CardDeck.CardColor.BLUE]}
	gs.boards = {3: []}

	card_played_emitted = false
	gs.connect("card_played", Callable(self, "_on_card_played_signal"))

	gs._apply_card_played(3, CardDeck.CardColor.RED)

	assert_true(card_played_emitted)
	assert_eq(gs.hands[3], [CardDeck.CardColor.BLUE])
	assert_eq(gs.boards[3], [CardDeck.CardColor.RED])
