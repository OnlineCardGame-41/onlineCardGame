extends Control
class_name PlayerView

@export var pid : int                      
var is_local : bool
@onready var Hand : ItemList = $Hand
var _gs : Node    

const LABEL := {
	CardDeck.CardColor.RED:    "Красная",
	CardDeck.CardColor.YELLOW: "Жёлтая",
	CardDeck.CardColor.BLUE:   "Синяя",
}

func card_label(c:CardDeck) -> String:   return LABEL[c]


func _ready() -> void:
	is_local = pid == multiplayer.get_unique_id()
	if not is_local:
		self.visible = false   

	
func init(gs : Node) -> void:
	_gs = gs
	_sync_full_hand()            
	_connect_signals()

func _sync_full_hand() -> void:
	Hand.clear()
	if not _gs.hands.has(pid):
		return                    # ещё не раздали
	for color in _gs.hands[pid]:
		Hand.add_item(card_label(color))

func _connect_signals() -> void:
	_gs.card_drawn.connect(_on_card_drawn)
	_gs.card_played.connect(_on_card_played)
	_gs.board_cleared.connect(_on_board_cleared)

func _on_card_drawn(draw_pid:int, color:CardDeck) -> void:
	if draw_pid != pid: return
	Hand.add_item(card_label(color))

func _on_card_played(play_pid:int, color:CardDeck) -> void:
	if play_pid != pid: return
	
	for i in Hand.item_count:
		if Hand.get_item_label(i) == card_label(color):
			Hand.remove_item(i)
			break

func _on_board_cleared(clr_pid:int, _seq:Array[int]) -> void:
	if clr_pid == pid:          
		_sync_full_hand()       
