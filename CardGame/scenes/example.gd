extends Node

@onready var field: Field = $"CanvasLayer/Field"
@onready var cardScene: PackedScene = preload("res://scenes/card.tscn")  

func _ready():
	for i in range(0, 6):
		var card = cardScene.instantiate()
		card.home_field = field
		field.cards_holder.add_child(card)
