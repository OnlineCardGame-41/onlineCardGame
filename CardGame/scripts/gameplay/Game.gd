extends Node2D
@export var player_view_scene: PackedScene = preload("res://scenes/PlayerView.tscn")

@onready var _gs: Node = $GameState  # ссылка на логику
@onready var _players_ui: Control = $PlayerViews  # контейнер в UI


func _ready() -> void:
	_gs.connect("turn_started", Callable(self, "_on_first_turn_started"), CONNECT_ONE_SHOT)


func _on_first_turn_started(_pid: int, _time: float) -> void:
	_spawn_player_view(multiplayer.get_unique_id())


func _spawn_player_view(pid: int) -> void:
	var pv = player_view_scene.instantiate()
	pv.pid = pid
	_players_ui.add_child(pv)
	pv.init(_gs)
	_gs._set_player_view(pv)
	if pid == multiplayer.get_unique_id():
		_players_ui.move_child(pv, 0)
