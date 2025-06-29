extends Control
class_name PlayerView

@export var pid: int
var is_local: bool
@onready var Hand: ItemList = $Hand
var _gs: Node
@onready var Board = $Board

const LABEL := {
	CardDeck.CardColor.RED: "Красная",
	CardDeck.CardColor.YELLOW: "Жёлтая",
	CardDeck.CardColor.BLUE: "Синяя",
}


func card_label(c: CardDeck.CardColor) -> String:
	return LABEL[c]


func _ready() -> void:
	is_local = pid == multiplayer.get_unique_id()
	if not is_local:
		self.visible = false
	Hand.item_selected.connect(_on_hand_click)


func init(gs: Node) -> void:
	_gs = gs
	_connect_signals()


func _connect_signals() -> void:
	_gs.card_drawn.connect(_on_card_drawn)
	_gs.card_played.connect(_on_card_played)
	_gs.board_cleared.connect(_on_board_cleared)


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


func _refresh_board():
	Board.clear()
	for p in _gs.players:
		var seq = _gs.boards.get(p, [])
		var text := "%d: %s" % [p, " ".join(seq.map(func(c): return LABEL.get(c)))]
		Board.add_item(text)


func _on_board_cleared(clr_pid: int, _seq: Array) -> void:
	_refresh_board()


func _on_hand_click(idx: int) -> void:
	if pid != multiplayer.get_unique_id():  # чужую руку не трогаем
		return
	_gs.request_play.rpc(idx, true)


func _on_clear_button_pressed() -> void:
	_gs.request_play.rpc(-1, false)


func _on_finish_button_pressed() -> void:
	_gs.finish()
