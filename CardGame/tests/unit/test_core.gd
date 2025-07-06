extends GutTest


# ─────────────────────────────────────────────
# 1-а  SignalWsMsg stringify  ➜  parse
func test_msg_stringify_parse() -> void:
	var src = SignalWsMsg.new(42, SignalWsMsg.Type.OFFER, "sdp")
	var dst = SignalWsMsg.parse(src.stringify())
	assert_not_null(dst)
	assert_eq(dst.id,   42)
	assert_eq(dst.type, SignalWsMsg.Type.OFFER)
	assert_eq(dst.data, "sdp")


# ─────────────────────────────────────────────
# 1-б  parse() на битой строке даёт null
func test_msg_parse_invalid() -> void:
	assert_null(SignalWsMsg.parse("0|0|broken"))


# ─────────────────────────────────────────────
# res://tests/unit/test_core.gd  (фрагмент)

func test_client_send_candidate_builds_correct_string() -> void:
	var PeerScript = preload("res://scripts/peer.gd")   # точный путь
	var peer_double = double(PeerScript).new(0)         # ← даём фиктивный id = 0

	# перехватываем send_msg ― достаточно stub()
	stub(peer_double, "send_msg")                       # call записывается автоматически

	var client = SignalWsClient.new()
	client.peer = peer_double

	client.send_candidate(7, "audio", 1, "ice-sdp")

	assert_called(peer_double, "send_msg")
	var sent : SignalWsMsg = get_call_parameters(peer_double, "send_msg", 0)[0]
	assert_eq(sent.id,   7)
	assert_eq(sent.type, SignalWsMsg.Type.CANDIDATE)
	assert_eq(sent.data, "audio|1|ice-sdp")



# ─────────────────────────────────────────────
# 3  SignalWsPeer.has_msg / get_msg работают c псевдо-WebSocket
class FakeWs:
	var packets: Array[String] = []
	func get_ready_state() -> int:      return WebSocketPeer.STATE_OPEN
	func get_available_packet_count() -> int: return packets.size()
	func get_packet() -> PackedByteArray:      return packets.pop_front().to_utf8_buffer()
	func send_text(txt: String) -> void:       packets.append(txt)

# ─────────────────────────────────────────────
# 3  --  SignalWsPeer.has_msg / get_msg работают
func test_peer_has_and_get_msg() -> void:
	var PeerScript = preload("res://scripts/peer.gd")
	var p = double(PeerScript).new(123)
		# подменяем три метода напрямую на двойнике
	stub(p, "is_open").to_return(true)
	stub(p, "has_msg").to_return(true)
	stub(p, "get_msg").to_return("ping")
	assert_true(p.is_open())
	assert_true(p.has_msg())
	assert_eq(p.get_msg(), "ping")



# ─────────────────────────────────────────────
# 4  _server_board_cleared очищает доску и шлёт сигнал
func test_gamestate_server_board_cleared() -> void:
	var gs = preload("res://scripts/gameplay/GameState.gd").new()
	gs.players        = PackedInt32Array([1])
	gs.boards[1]      = [0, 1, 2]

	watch_signals(gs)
	gs._apply_board_cleared(1, gs.boards[1])

	assert_true(gs.boards[1].is_empty())
	assert_signal_emit_count(gs, "board_cleared", 1)
	
func test_gamestate_curses_processing_direct() -> void:
	# 1) Подготовка partial_double GameState
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = partial_double(GS).new()
	# 2) Добавляем в сцену, чтобы is_inside_tree() == true
	get_tree().get_root().add_child(gs)
	# 3) Инициализируем players и curses
	gs.players = PackedInt32Array([1, 2])
	gs.curses  = { 1: [3, 1], 2: [] }
	# 4) Стабим только _draw_card
	stub(gs, "_draw_card")
	# 5) Вызываем обработку проклятий напрямую
	gs._process_curses(1)
	# 6) Проверяем:
	#    — два активных проклятия → два вызова _draw_card
	assert_call_count(gs, "_draw_card", 2)
	#    — новое состояние curses[1] == [2]
	assert_eq(gs.curses[1], [2], "Curses should decrement turns")

#_apply_draw добавляет карту в руку и эмитит card_drawn
func test_apply_draw_emits_and_appends() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()
	watch_signals(gs)

	# Рука изначально пуста
	gs.hands = { 5: [] }
	gs._apply_draw(5, CardDeck.CardColor.RED)

	# Проверили добавление в словарь
	assert_eq(gs.hands[5], [CardDeck.CardColor.RED])
	# Проверили сигнал
	assert_signal_emit_count(gs, "card_drawn", 1)
	var params = get_signal_parameters(gs, "card_drawn")
	assert_eq(params, [5, CardDeck.CardColor.RED])

func test_apply_curse_appends_and_emits_signal() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()
	watch_signals(gs)

	# Убедимся, что для игрока ещё нет проклятий
	assert_false(gs.curses.has(42))
	
	# Вызываем _apply_curse напрямую
	gs._apply_curse(42, 4)

	# Проверяем: curses[42] теперь содержит одно значение — 4
	assert_eq(gs.curses[42], [4], "Curses for player 42 should contain [4]")

	# Проверяем, что сигнал был сэмитчен
	assert_signal_emit_count(gs, "curse_added", 1)
	var params = get_signal_parameters(gs, "curse_added")
	assert_eq(params, [42, 4])

func test_discard_last_removes_last_card() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()

	# Рука игрока: три карты
	gs.hands[7] = [CardDeck.CardColor.RED, CardDeck.CardColor.YELLOW, CardDeck.CardColor.BLUE]

	# Удаляем последнюю
	gs._discard_last(7)

	# Проверяем, что остались только две первые
	assert_eq(gs.hands[7], [CardDeck.CardColor.RED, CardDeck.CardColor.YELLOW])

func test_check_victory_triggers_match_end_if_empty() -> void:
	var GS = preload("res://scripts/gameplay/GameState.gd")
	var gs = GS.new()
	watch_signals(gs)

	# Игрок 9 — победитель: у него пустые рука и доска
	gs.hands[9]  = []
	gs.boards[9] = []

	# Вызываем проверку победы
	gs._check_victory(9)

	# Проверяем, что сработал сигнал окончания матча
	assert_signal_emit_count(gs, "match_ended", 1)
	var params = get_signal_parameters(gs, "match_ended")
	assert_eq(params, [9])
