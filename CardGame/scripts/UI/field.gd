class_name Field
extends MarginContainer

signal card_added(idx: int, is_left: bool)

@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_holder: HBoxContainer = $CardsHolder
@export var is_final: bool = false

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
	var idx = card.index 
	var put_left = !field_areas.has(card_drop_area_right)

	card.reparent(cards_holder)           
	cards_holder.move_child(card, 0 if put_left else cards_holder.get_child_count())
	if is_final:
		card.mouse_filter = MOUSE_FILTER_IGNORE
	#print("PutLeft: ", put_left)
	print("card_added ", idx, " ",  put_left)
	emit_signal("card_added", idx, put_left)
	
