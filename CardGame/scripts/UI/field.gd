class_name Field
extends MarginContainer


@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_holder: HBoxContainer = $CardsHolder


func _ready():
	$Label.text = name
	
	for child in cards_holder.get_children():
		var card := child as Card
		card.home_field = self


func return_card_starting_position(card: Card):
	card.reparent(cards_holder)
	cards_holder.move_child(card, card.index)


func set_new_card(card: Card):
	card_reposition(card)
	card.home_field = self


func card_reposition(card: Card):
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	var index: int = 0
	
	index = cards_holder.get_child_count() if field_areas.has(card_drop_area_right) else 0

	card.reparent(cards_holder)
	cards_holder.move_child(card, index)
