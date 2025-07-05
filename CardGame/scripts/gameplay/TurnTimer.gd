extends Timer



func _ready() -> void:
	autostart = false
	one_shot = true
	connect("timeout", Callable(self, "_on_timeout"))


func _on_timeout() -> void:
	var gs = $"../GameState"
	if gs.multiplayer.is_server():
		gs._begin_turn.rpc((gs.active_idx + 1) % gs.players.size())
