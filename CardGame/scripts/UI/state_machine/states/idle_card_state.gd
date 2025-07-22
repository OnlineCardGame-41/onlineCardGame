extends CardState


func _enter():
	card.Sprite.scale = Vector2(1., 1.)
	card.pivot_offset = Vector2.ZERO


func on_mouse_entered():
	transitioned.emit("hover")
