extends Node2D

#@export var websocket_url = "wss://godot-golang-webrtc-signal.onrender.com/ws"
@export var websocket_url = "wss://onlinecardgame.onrender.com/ws"
@export var HostButton : Button
@export var JoinButton : Button
@export var JoinMode: Button
@export var JoinList: Button
@export var TakeCard : Button
@export var LobbyInfo : Label
@export var EnterLobbyId : Label
@export var LobbyId_getter : LineEdit
@export var PlayerList : ItemList
@export var LobbiesList: ItemList
@export var PlayerName_getter : LineEdit
@export var PINGME: Button
@export var Game: Node2D
@export var game_scene : PackedScene = preload("res://scenes/Game.tscn")

var client: SignalWsClient

@onready var rtc_mesh := WebRTCMultiplayerPeer.new()
var ice_servers := [{ "urls": "stun:stun.l.google.com:19302" }, #Stun and Turn server adresses and credentials
 {"urls": "stun:stun1.l.google.com:3478"},
 {
		"urls": "relay1.expressturn.com:3480",
		"username": "000000002065841620",
		"credential": "xPemnFVrdPUHMn7nliW+mHLxxt8="
 }
]

var peers = {}

var is_host = false

var current_mode = 0
#0 = basic screen
#1 = lobbies list
#2 = in lobby

func to_join_mode():
	var current_mode = 1
	HostButton.visible = false
	JoinMode.visible = false
	JoinButton.visible = true
	LobbyId_getter.visible = true
	TakeCard.visible = true
	PlayerList.visible = true
	JoinList.visible = true
	LobbiesList.visible = true
	EnterLobbyId.visible = true
	TakeCard.visible = false
	PlayerList.visible = false
	client.get_lobbies()
	
func to_startScreen_mode():
	var current_mode = 0
	HostButton.visible = true
	JoinMode.visible = true
	JoinButton.visible = false
	LobbyId_getter.visible = false
	TakeCard.visible = false
	PlayerList.visible = false
	JoinList.visible = false
	LobbiesList.visible = false
	EnterLobbyId.visible = false
	TakeCard.visible = false
	PlayerList.visible = false
	
func to_lobbyScreen_mode():
	var current_mode = 2
	HostButton.visible = false
	JoinMode.visible = false
	JoinButton.visible = false
	LobbyId_getter.visible = false
	TakeCard.visible = false
	PlayerList.visible = false
	JoinList.visible = false
	LobbiesList.visible = false
	EnterLobbyId.visible = false
	TakeCard.visible = true
	PlayerList.visible = true
	
func _ready() -> void:
	LobbyInfo.text = "Connecting..."
	to_startScreen_mode()
	HostButton.disabled = true
	JoinMode.disabled = true
	
	client = SignalWsClient.new()
	
	rtc_mesh = WebRTCMultiplayerPeer.new()
	
	client.lobby_hosted.connect(_on_lobby_hosted)
	client.lobby_joined.connect(_on_lobby_joined)
	client.lobby_sealed.connect(_on_lobby_sealed)
	client.offer_received.connect(_on_offer_received)
	client.answer_received.connect(_on_answer_received)
	client.candidate_received.connect(_on_candidate_received)
	client.we_joined.connect(_on_we_joined)
	client.peer_connected.connect(_on_peer_connected)
	client.new_lobby_received.connect(_on_new_lobby_received)
	
	client.connect_to_server(websocket_url)

func _process(_delta):
	if client != null:
		client.poll()

#buttons
func _on_host_button_pressed() -> void:
	LobbyInfo.text = "Hosting..."
	client.host_lobby(PlayerName_getter.text)
	rtc_mesh.create_server()
	multiplayer.multiplayer_peer = rtc_mesh
	to_lobbyScreen_mode()
	
func _on_join_button_pressed() -> void:
	var id = int(LobbyId_getter.text)
	print("Joining...", id)
	client.join_lobby(id, PlayerName_getter.text)
	
	rtc_mesh.create_client(2)
	multiplayer.multiplayer_peer = rtc_mesh

func _on_take_card_pressed() -> void:
	if not is_multiplayer_authority():
		return  
	rpc("game_start")


func _on_ping_pressed() -> void:
	rpc("test_ping")

#after connection to server
func _on_we_joined():
	HostButton.disabled = false
	JoinMode.disabled = false
	LobbyInfo.text = "Connected to server"

func _on_lobby_hosted(pid: int, lobby_id: int) -> void:
	print(pid)
	LobbyInfo.text = "Lobby ID: %d" % lobby_id
	_add_self_to_list()
	TakeCard.disabled = false
	var name = PlayerName_getter.text.strip_edges()

func _on_lobby_sealed(sealed_lobby_id: int):
	LobbyInfo.text += " (sealed)"

func _on_lobby_joined(pid: int, lobby_id: int, sealed: bool) -> void:
	to_lobbyScreen_mode()
	LobbyInfo.text = "Joined Lobby %d (sealed=%s)" % [lobby_id, str(sealed)]
	_add_self_to_list()
	TakeCard.disabled = false
	
func _spawn_pc(pid: int, polite: bool) -> WebRTCPeerConnection:
	var pc := WebRTCPeerConnection.new()
	pc.initialize({ "iceServers": ice_servers })
	

	pc.session_description_created.connect(
		func(type: String, sdp: String):
			if type == "offer":
				client.send_offer(pid, sdp)
			if type == "answer":
				client.send_answer(pid, sdp)
	)
	pc.ice_candidate_created.connect(
		func(mid: String, idx: int, sdp: String):
			client.send_candidate(pid, mid, idx, sdp)
	)

	rtc_mesh.add_peer(pc, pid)

	print("Created peer connection with: ", pid)
	
	if not polite:
		# ❗ Убедитесь, что есть каналы/треки до create_offer
		pc.create_data_channel("data")  # например, создаём data channel
		pc.create_offer()
	return pc

func _on_offer_received(from_pid: int, sdp: String) -> void:
	var pc = _spawn_pc(from_pid, true)
	if pc == null:
		return
	pc.set_remote_description("offer", sdp)

func _on_answer_received(from_pid: int, sdp: String) -> void:
	if not rtc_mesh.has_peer(from_pid):
		push_warning("Answer received from unknown peer %d — пропускаем" % from_pid)
		return
	var peer_info = rtc_mesh.get_peer(from_pid)
	if peer_info == null:
		push_warning("Peer info is null for peer %d" % from_pid)
		return
	var pc = peer_info.get("connection", null)
	if pc == null:
		push_warning("Peer connection is null for peer %d" % from_pid)
		return
	pc.set_remote_description("answer", sdp)

func _on_candidate_received(from_pid: int, mid: String, idx: int, sdp: String) -> void:
	if not rtc_mesh.has_peer(from_pid):
		push_warning("ICE candidate from unknown peer %d — пропускаем" % from_pid)
		return
	var peer_info = rtc_mesh.get_peer(from_pid)
	var pc : WebRTCPeerConnection = peer_info["connection"]
	pc.add_ice_candidate(mid, idx, sdp)

func _on_network_peer_connected(id:int) -> void:
	var name = PlayerName_getter.text.strip_edges()
	if name == "": name = "Guest"
	rpc("_rpc_add_player", name)

func _add_self_to_list() -> void:
	var name = PlayerName_getter.text.strip_edges()
	if name == "": 
		name = "Guest" if HostButton.disabled else "Host"
	if !_player_list_has(name):
		PlayerList.add_item(name)

func _player_list_has(name: String) -> bool:
	for i in PlayerList.item_count:
		if PlayerList.get_item_text(i) == name:
			return true
	return false
	
func _on_peer_connected(pid: int):
	if is_multiplayer_authority():
		# Мы хост — создаём соединение и сразу offer
		_spawn_pc(pid, false)
	else:
		# Клиент просто ждёт offer от хоста
		print("Connected to peer %d, waiting for offer" % pid)	

@rpc("any_peer")
func test_ping():
	print("smth")

@rpc("authority", "call_local")
func game_start():
	var gm = game_scene.instantiate()
	get_parent().add_child(gm)
	self.visible = false
	var gs : Node = gm.get_node("GameState")
	var peer_ids : PackedInt32Array = [multiplayer.get_unique_id()]
	peer_ids.append_array(multiplayer.get_peers())
	if multiplayer.is_server():
		gs.start_match.rpc(peer_ids)

@rpc("any_peer")
func _rpc_add_player(name:String) -> void:
	if PlayerList.find_item(name) == -1:
		PlayerList.add_item(name)


func _on_joinMode_pressed() -> void:
	to_join_mode()


func _on_X_pressed() -> void:
	get_tree().reload_current_scene()
	
func _on_new_lobby_received(lobby_id: int, host_name: String):
	var entry = "%s (ID: %d)" % [host_name, lobby_id]
	var index = LobbiesList.add_item(entry)
	LobbiesList.set_item_metadata(index, lobby_id)


func _on_join_list_pressed() -> void:
	var selected_index = LobbiesList.get_selected_items()
	if selected_index.is_empty():
		LobbyInfo.text = "Выберите лобби в списке"
		return
	var index = selected_index[0]
	var id = LobbiesList.get_item_metadata(index)
	print("Joining...", id)
	client.join_lobby(id, PlayerName_getter.text)
	rtc_mesh.create_client(2)
	multiplayer.multiplayer_peer = rtc_mesh
