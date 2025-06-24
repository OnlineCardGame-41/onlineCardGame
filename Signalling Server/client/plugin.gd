@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("SignalLobby", "Node", preload("signal_lobby_node.gd"), preload("icon.png"))


func _exit_tree() -> void:
	remove_custom_type("SignalLobby")
