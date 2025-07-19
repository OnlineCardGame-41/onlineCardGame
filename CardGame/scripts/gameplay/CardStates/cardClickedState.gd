extends CardState

func enter() -> void:
	card_ui.drop_point_detector.monitoring = true

func on_iput(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("click")
		transition_requested.emit(self, CardState.State.DRAGGING)
