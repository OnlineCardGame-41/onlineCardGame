# Messages passed over WebSocket connections
class_name SignalWsMsg


# Message types for WebSocket messages
enum Type {
	INVALID = 0,
	CONNECTED,
	HOST,
	JOIN,
	PEER_CONNECT,
	PEER_DISCONNECT,
	OFFER,
	ANSWER,
	CANDIDATE,
	SEAL
}


# Primary message payload. This could be a peer id or a
# lobby id depending on the message type
var id: int

# Message type
var type: Type

# Additional payload that some messages carry
var data: String

# Construct a new Msg objects (gets called by Msg.new())
func _init(id_: int, type_: Type, data_: String = "") -> void:
	id = id_
	type = type_
	data = data_

# Parse a message string in the form of "type|pid|data" to a Msg object
static func parse(msg_str: String) -> SignalWsMsg:
	# Split into max of 3 tokens
	# (data token for CANDIDATE messages contains additional "|" characters)
	var tokens: PackedStringArray = msg_str.split("|", true, 2)

	var type_ := tokens[0].to_int()
	var id_ := tokens[1].to_int()
	var data_ := tokens[2] if tokens.size() > 2 else ""

	if type_ == SignalWsMsg.Type.CANDIDATE:
		print("Parsing candidate message: ", data_)

	if type_ == Type.INVALID or (type_ != Type.HOST and id_ == 0):
		print("Could not parse message: ", msg_str)
		return null

	return SignalWsMsg.new(id_, type_, data_)

# Convert this message to a string in the form of "type|pid|data"
func stringify() -> String:
	return str(type) + "|" + str(id) + "|" + data