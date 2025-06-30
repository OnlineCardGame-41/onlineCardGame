# Represent client peer connecting to server
class_name SignalWsPeer

extends RefCounted

const TIMEOUT_MS = 1_000

var peer_id: int
var lobby_id: int
var created_at = Time.get_ticks_msec()
var ws = WebSocketPeer.new()


func _init(id: int) -> void:
	peer_id = id


func is_open() -> bool:
	return ws.get_ready_state() == WebSocketPeer.STATE_OPEN


func has_msg() -> bool:
	return ws.get_available_packet_count() > 0


func get_msg() -> String:
	return ws.get_packet().get_string_from_utf8()


func send_msg(msg: SignalWsMsg) -> void:
	ws.send_text(msg.stringify())
