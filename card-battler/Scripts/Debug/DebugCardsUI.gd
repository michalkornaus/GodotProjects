extends CanvasLayer
enum player_names {Player1, Player2}
@export var player_name: player_names
@onready var middle_button: Button = $CardsUI/OptionsPanel/OptionButtons/MiddleButton
@onready var upgrades_button: Button = $CardsUI/OptionsPanel/OptionButtons/UpgradeButton
var lane_value: int = 1 #1 - middle, 3 - upgrades
var ui_open: bool = false
var upgrades_open: bool = false
var was_ui_open: bool = false

@export var card_scene: PackedScene

@export var middle_lane_deck: Control
@onready var middle_lane_nodes: Array = middle_lane_deck.get_children()

@onready var cards_panel: Control = $CardsUI/BottomPanel/CardsPanelsAndTools
@onready var upgrades_panel: Control = $CardsUI/BottomPanel/UpgradesPanel

func _ready():
	call_deferred("unlock_the_buttons")
	middle_button.button_pressed = true

func unlock_the_buttons():
	for node in middle_lane_nodes:
		if node.is_in_group("locked"):
			node.get_node("UnlockButton").disabled = false
			break

func _process(delta):
	if Input.is_action_just_pressed("open_shop") && !upgrades_open:
		_on_shop_button_pressed()
		
func change_lane():
	match lane_value:
		1: 
			_on_middle_button_pressed()
		3: 
			_on_upgrades_button_pressed()

func _on_shop_button_pressed():
	if !ui_open:
		open_ui()
	else:
		hide_ui()

func open_ui():
	ui_open = true
		
func hide_ui():
	ui_open = false

func _on_middle_button_pressed():
	lane_value = 1
	middle_button.button_pressed = true
	upgrades_button.button_pressed = false
	
	cards_panel.visible = true
	middle_lane_deck.visible = true
	upgrades_panel.visible = false
	
	if upgrades_open:
		if !was_ui_open:
			hide_ui()
			
	upgrades_open = false


func _on_upgrades_button_pressed():
	lane_value = 3
	middle_button.button_pressed = false
	upgrades_button.button_pressed = true
	
	cards_panel.visible = false
	upgrades_panel.visible = true
	upgrades_open = true
	
	was_ui_open = ui_open
	if !ui_open:
		open_ui()

func _on_clear_decks_button_pressed():
	var cards_to_delete = get_tree().get_nodes_in_group("deck_card")
	for card in cards_to_delete:
		card.queue_free()
