extends CanvasLayer

const LABEL = {
	CardDeck.CardColor.RED: "Красная",
	CardDeck.CardColor.YELLOW: "Жёлтая",
	CardDeck.CardColor.BLUE: "Синяя",
}

signal player_picked(pid: int)

@onready var pid: int
@onready var Hand: Field = $Node/Hand
@onready var Board: Field = $Node/Board
@onready var Turn: RichTextLabel = $Turn
@onready var Players: ItemList = $Players
@onready var TimeLabel: RichTextLabel = $Time
@onready var BG: ColorRect
@onready var _timer: Timer = $"../TurnTimer"
@onready var castSpell: Button = $CastSpell
@onready var _gs: Node = $"../GameState"
var is_local: bool
var split: float = 0.5

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")   


func card_label(c: CardDeck.CardColor) -> String:
	return LABEL[c]
	
func _ready() -> void:
	pid = multiplayer.get_unique_id()
	#is_local = pid == 
	#if not is_local:
		#self.visible = false
	_connect_signals()
	
func _process(delta: float) -> void:
	if not _timer.is_stopped():
		TimeLabel.text = " %.1f сек" % _timer.time_left
	else:
		TimeLabel.text = ""      


func _on_card_added(idx: int, is_left):
	_gs.request_play(idx, true, is_left)

func _connect_signals() -> void:
	castSpell.pressed.connect(_on_clear_button_pressed)
	Board.card_added.connect(_on_card_added)
	_gs.card_drawn.connect(_on_card_drawn)
	_gs.card_played.connect(_on_card_played)
	_gs.board_cleared.connect(_on_board_cleared)
	_gs.turn_started.connect(_on_turn_started)
	_gs.match_ended.connect(_on_match_ended)

func _on_card_drawn(pid: int, card: CardDeck.CardColor):
	if pid == self.pid:
		var card_sc = CARD_SCENE.instantiate()
		card_sc.color = card 
		card_sc.home_field = Hand
		card_sc.index = _gs.hands[multiplayer.get_unique_id()].size()
		Hand.cards_holder.add_child(card_sc)

func _on_turn_started(turn_pid: int, time_left: float):
	if turn_pid == pid:
		Turn.text = "Your Turn"
		Hand.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		Hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Turn.text = "Turn of %d" % turn_pid

func _on_clear_button_pressed():
	_gs.request_play(-1, false, false)

func _on_board_cleared(pid: int, seq: Array):
	for child in Board.cards_holder.get_children():
		child.free()
	
func _on_card_played(pid: int, card: CardDeck.CardColor):
	pass
	
func _on_match_ended(winner_pid: int):
	pass
	
