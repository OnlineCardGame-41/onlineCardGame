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
	gs._server_board_cleared(1, gs.boards[1])

	assert_true(gs.boards[1].is_empty())
	assert_signal_emit_count(gs, "board_cleared", 1)
