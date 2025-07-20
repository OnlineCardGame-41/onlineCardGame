extends CardState


func _enter():
	card.Sprite.scale = Vector2(1.1, 1.1)


func on_gui_input(event: InputEvent):
	if event.is_action_pressed("mouse_left"):
		card.pivot_offset = card.get_global_mouse_position() - card.global_position
		transitioned.emit("Click")


func on_mouse_exited():
	transitioned.emit("Idle")
