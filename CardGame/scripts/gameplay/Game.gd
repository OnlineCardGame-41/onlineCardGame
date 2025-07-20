extends Node2D

@onready var _gs: Node = $GameState  # ссылка на логику


func _ready() -> void:
	_gs.connect("turn_started", Callable(self, "_on_first_turn_started"), CONNECT_ONE_SHOT)


func _on_first_turn_started(_pid: int, _time: float) -> void:
	_spawn_player_view(multiplayer.get_unique_id())


func _spawn_player_view(pid: int) -> void:
	pass
