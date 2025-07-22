extends Control

const LABEL = {
	CardDeck.CardColor.RED: "RED",
	CardDeck.CardColor.YELLOW: "YELLOW",
	CardDeck.CardColor.BLUE: "BLUE",
}



func set_card(color: CardDeck.CardColor) -> void:
	$TextureRect.texture = load("res://src/%s.png" % LABEL[color])
