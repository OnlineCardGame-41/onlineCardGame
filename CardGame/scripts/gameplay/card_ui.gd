class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)

@onready var texture: TextureRect = $CardSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
