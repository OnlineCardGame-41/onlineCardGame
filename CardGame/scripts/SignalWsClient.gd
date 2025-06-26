class_name SignalWsClient

signal connected(pid: int)
signal lobby_hosted(pid: int, lobby_id: int)
signal lobby_joined(pid: int, lobby_id: int, is_sealed: bool)
signal lobby_sealed(lobby_id: int)
signal peer_connected(pid: int)
signal peer_disconnected(pid: int)
signal offer_received(pid: int, offer: String)
signal answer_received(pid: int, answer: String)
signal candidate_received(pid: int, mid: String, index: int, sdp: String)

signal we_joined

var peer: SignalWsPeer
var prev_state := WebSocketPeer.STATE_CLOSED

# Connect to server. Connect to given lobby_id, or if lobby_id is not provided,
# the client will host a new game
func connect_to_server(server_url: String) -> void:
	print("[client] Connecting to server: ", server_url)
	if peer != null:
		peer.ws.close()

	# We don't know the peer id yet, so we use 0 until `SignalWsMsg.Type.CONNECTED`
	# message is received. Client peer connections are monitored by the server
	# which will generate / assign peer ids.
	peer = SignalWsPeer.new(0)
	peer.ws.connect_to_url(server_url)
	peer.lobby_id = 0

func host_lobby(name: String):
	update_name(name)
	if peer == null or not peer.is_open():
		print("Error: Not connected to server.")
		return
	
	peer.send_msg(SignalWsMsg.new(0, SignalWsMsg.Type.HOST))

func update_name(name: String):
	peer.send_msg(SignalWsMsg.new(0, SignalWsMsg.Type.UPDATENAME, name))

func join_lobby(lobby_id: int, name: String):
	update_name(name)
	if peer == null or not peer.is_open():
		print("Error: Not connected to server.")
		return
	
	peer.lobby_id = lobby_id
	peer.send_msg(SignalWsMsg.new(lobby_id, SignalWsMsg.Type.JOIN))

func seal_lobby() -> void:
	if peer == null:
		print("Error: Peer is null.")
		return

	if peer.lobby_id == 0:
		print("Error: Cannot seal lobby without a lobby id.")
		return

	print("[client] Sealing lobby with id: ", peer.lobby_id)
	peer.send_msg(SignalWsMsg.new(peer.lobby_id, SignalWsMsg.Type.SEAL))

# Handle current peer message
func handle_peer_msg() -> bool:
	var msg = SignalWsMsg.parse(peer.get_msg())
	if msg == null:
		return false

	match msg.type:
		SignalWsMsg.Type.CONNECTED:
			print("[client] Connected to server with peer id: ", msg.id)
			peer.peer_id = msg.id
			connected.emit(peer.peer_id)

		SignalWsMsg.Type.HOST:
			print("[client] Hosted game with lobby id: ", msg.id)
			peer.lobby_id = msg.id
			lobby_hosted.emit(peer.peer_id, peer.lobby_id)

		SignalWsMsg.Type.JOIN:
			if msg.id != peer.lobby_id:
				print("Error: Joined lobby id does not match requested lobby id.")
				return false

			print("[client] Joined game with lobby id: ", msg.id)
			lobby_joined.emit(peer.peer_id, peer.lobby_id, msg.data == "true")

		SignalWsMsg.Type.SEAL:
			print("[client] Lobby sealed with id: ", msg.id)
			lobby_sealed.emit(msg.id)

		SignalWsMsg.Type.PEER_CONNECT:
			peer_connected.emit(msg.id)

		SignalWsMsg.Type.PEER_DISCONNECT:
			peer_disconnected.emit(msg.id)

		SignalWsMsg.Type.OFFER:
			print("[client] ", peer.peer_id, " offer from ", msg.id)
			offer_received.emit(msg.id, msg.data)

		SignalWsMsg.Type.ANSWER:
			print("[client] ", peer.peer_id, " answer from ", msg.id)
			answer_received.emit(msg.id, msg.data)

		SignalWsMsg.Type.CANDIDATE:
			print("[client] ", peer.peer_id, " candidate from ", msg.id)
			# data is in the form of "mid|index|sdp"
			var tokens: PackedStringArray = msg.data.split("|")

			if tokens.size() != 3:
				print("Error parsing candidate message.")
				return false

			var mid: String = tokens[0]
			var index: int = tokens[1].to_int()
			var sdp: String = tokens[2]

			candidate_received.emit(msg.id, mid, index, sdp)

		_:
			print("Unhandled message type: ", msg.type)
			return false

	return true

func poll() -> void:
	if peer == null:
		return

	peer.ws.poll()

	var state = peer.ws.get_ready_state()
	if state != prev_state:
		prev_state = state

		if state == WebSocketPeer.STATE_OPEN:
			print("[client] WebSocket connection opened: ")
			emit_signal("we_joined")

	while peer.is_open() and peer.has_msg():
		if not handle_peer_msg():
			print("Error parsing signal message.")

func send_offer(pid: int, offer: String) -> void:
	peer.send_msg(SignalWsMsg.new(pid, SignalWsMsg.Type.OFFER, offer))

func send_answer(pid: int, answer: String) -> void:
	peer.send_msg(SignalWsMsg.new(pid, SignalWsMsg.Type.ANSWER, answer))

func send_candidate(pid: int, mid: String, index: int, sdp: String) -> void:
	var data = mid + "|" + str(index) + "|" + sdp
	peer.send_msg(SignalWsMsg.new(pid, SignalWsMsg.Type.CANDIDATE, data))
