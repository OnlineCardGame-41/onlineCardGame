extends Timer
var current_pid := 0

func _ready() -> void:
	autostart = false
	one_shot  = true
	connect("timeout", Callable(self, "_on_timeout"))

func _on_timeout() -> void:
	var gs := get_parent()           
	if gs.players[gs.active_idx] == gs.multiplayer.get_unique_id():
		gs.request_draw.rpc()
