class_name CardDeck
enum CardColor { RED, YELLOW, BLUE }

static var _rng := RandomNumberGenerator.new()


static func draw() -> CardColor:
	_rng.randomize()
	return CardColor.values()[_rng.randi_range(0, 2)]
