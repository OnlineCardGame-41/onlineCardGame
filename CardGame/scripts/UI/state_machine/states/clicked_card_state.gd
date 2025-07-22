extends CardState


func _enter():
	pass

func on_input(event):
	if event is InputEventMouseMotion:
		transitioned.emit("Drag")
