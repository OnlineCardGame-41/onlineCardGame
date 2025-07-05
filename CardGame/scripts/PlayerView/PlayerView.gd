class_name PlayerView
extends Control


const LABEL := {
	CardDeck.CardColor.RED: "Красная",
	CardDeck.CardColor.YELLOW: "Жёлтая",
	CardDeck.CardColor.BLUE: "Синяя",
}

@export var pid: int
@export var Hand: ItemList
@export var Board: ItemList
@export var Turn: RichTextLabel
@export var Players: ItemList
signal player_picked(pid: int)
var is_local: bool
var _gs: Node


func card_label(c: CardDeck.CardColor) -> String:
	return LABEL[c]


func _ready() -> void:
	is_local = pid == multiplayer.get_unique_id()
	if not is_local:
		self.visible = false
	Hand.item_selected.connect(_on_hand_click)
	Players.item_selected.connect(_on_players_click)


func init(gs: Node) -> void:
	_gs = gs
	_connect_signals()
	_refresh_hand()   
	_refresh_board()
	_refresh_players()
	_on_turn_started(1, 30.0)


func _connect_signals() -> void:
	_gs.card_drawn.connect(_on_card_drawn)
	_gs.card_played.connect(_on_card_played)
	_gs.board_cleared.connect(_on_board_cleared)
	_gs.turn_started.connect(_on_turn_started)

func _on_turn_started(turn_pid: int, time_left: float):
	if turn_pid == pid:
		Turn.text = "Your Turn"
	else:
		Turn.text = "Turn of %d" % turn_pid
	_refresh_hand()

func _on_card_drawn(draw_pid: int, color: CardDeck.CardColor) -> void:
	if draw_pid != pid:
		return
	Hand.add_item(card_label(color))


func _on_card_played(play_pid: int, color: CardDeck.CardColor) -> void:
	if play_pid == pid:
		for i in Hand.item_count:
			if Hand.get_item_text(i) == card_label(color):
				Hand.remove_item(i)
				break
	_refresh_board()
	_refresh_players()


func _refresh_board():
	Board.clear()
	for p in _gs.players:
		var seq = _gs.boards.get(p, [])
		var text := "%s: %s" % [(str(p) if p != pid else "You"),
		" ".join(seq.map(func(c): return LABEL.get(c)))]
		Board.add_item(text)


func _refresh_hand():
	Hand.clear()
	for c in _gs.hands[pid]:
		Hand.add_item(card_label(c))

func _refresh_players():
	Players.clear()
	for p in _gs.players:
		var cur = _gs.curses.get(p, []).size()
		var shields = _gs.shields.get(p, 0)
		var hand = _gs.hands.get(p, []).size()
		var text = "%s: Рука: %d Щиты: %d Проклятия: %s" % [(str(p) if p != pid else "You"), hand, shields, cur]
		var idx = Players.add_item(text)
		Players.set_item_metadata(idx, p)


func _on_board_cleared(clr_pid: int, _seq: Array) -> void:
	_refresh_board() 
	_refresh_hand()
	_refresh_players()


func _on_hand_click(idx: int) -> void:
	if pid != multiplayer.get_unique_id():  # чужую руку не трогаем
		return
	_gs.request_play(idx, true)

func _on_players_click(idx: int) -> void:
	emit_signal("player_picked", Players.get_item_metadata(idx))

func _on_clear_button_pressed() -> void:
	_gs.request_play(-1, false)


func _on_finish_button_pressed() -> void:
	_gs.finish()
