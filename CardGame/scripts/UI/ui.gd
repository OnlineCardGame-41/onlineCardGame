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
@onready var TimeLabel: RichTextLabel = $Time
@onready var BG: ColorRect
@onready var _timer: Timer = $"../TurnTimer"
@onready var castSpell: Button = $CastSpell
@onready var _gs: Node = $"../GameState"
var is_local: bool
var split: float = 0.5

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")   
const CARD_SPRITE: PackedScene = preload("res://scenes/CardSprite.tscn")
@onready var _enemy_seats : Array = [
	$"Enemy1",  
	$"Enemy2",
	$"Enemy3",
	$"Enemy4",  
]
var _seat_of_pid : Dictionary = {}    



func initial() -> void:
	pid = multiplayer.get_unique_id()
	var seat_idx = 0
	print("_seat_of_pid:", _gs.players)
	for ppid: int in _gs.players:
		if ppid == pid:
			continue                          # skip yourself

		if seat_idx >= _enemy_seats.size():
			push_error("Not enough Enemy‑slots for pid %s" % ppid)
			break                             # or wrap/extend as you prefer

		_seat_of_pid[ppid] = _enemy_seats[seat_idx]
		var player: Control = _seat_of_pid[ppid]
		var nick = player.get_node("NickName")
		nick.text = Multiplayer.peer_names.get(ppid, "Unknown")
		
		
		seat_idx += 1
		print("_seat_of_pid:", _seat_of_pid)
	_refresh_board() 
	_connect_signals()

func card_label(c: CardDeck.CardColor) -> String:
	return LABEL[c]

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
	_refresh_board() 
	if pid == self.pid:
		var card_sc = CARD_SCENE.instantiate()
		card_sc.color = card 
		card_sc.home_field = Hand
		card_sc.index = _gs.hands[multiplayer.get_unique_id()].size()
		Hand.cards_holder.add_child(card_sc)

func _on_turn_started(turn_pid: int, time_left: float):
	_refresh_board() 
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
	_refresh_board() 
	
func _on_card_played(pid: int, card: CardDeck.CardColor):
	_refresh_board() 
	
func _on_match_ended(winner_pid: int):
	pass
	
	
func _refresh_board() -> void:
	for pid in _seat_of_pid.keys():
		print("LOLKEK228",pid)
		var seat  : Control        = _seat_of_pid[pid]
		var holder: HBoxContainer  = seat.get_node("Board")   
		for c in holder.get_children():
			c.queue_free()
		for card_data in _gs.boards.get(pid, []):
			var sprite = CARD_SPRITE.instantiate()
			sprite.set_card(card_data)   
			holder.add_child(sprite)
	
