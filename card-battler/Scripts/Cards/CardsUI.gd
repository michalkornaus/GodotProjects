extends CanvasLayer

@onready var ui = $CardsUI
@onready var top_button: Button = $CardsUI/OptionsPanel/OptionButtons/TopButton
@onready var middle_button: Button = $CardsUI/OptionsPanel/OptionButtons/MiddleButton
@onready var bottom_button: Button = $CardsUI/OptionsPanel/OptionButtons/BottomButton
@onready var upgrades_button: Button = $CardsUI/OptionsPanel/OptionButtons/UpgradeButton
var lane_value: int = 0 #0 - top, 1 - middle, 2 - bottom, 3 - upgrades
var ui_open: bool = false
var upgrades_open: bool = false
var was_ui_open: bool = false

@onready var nexusNode: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/Player1_Nexus")

@export var card_scene: PackedScene
#different tiers of all cards
var all_cards_common: Array
var all_cards_rare: Array
var all_cards_epic: Array
var all_cards_legendary: Array

@onready var shop_nodes : Array = get_tree().get_nodes_in_group("shop_zone")

@onready var top_lane_nodes: Array = get_tree().get_nodes_in_group("top_zone")
@export var top_lane_deck: Control

@onready var middle_lane_nodes: Array = get_tree().get_nodes_in_group("middle_zone")
@export var middle_lane_deck: Control

@onready var bottom_lane_nodes: Array = get_tree().get_nodes_in_group("botton_zone")
@export var bottom_lane_deck: Control

@onready var cards_panel: Control = $CardsUI/BottomPanel/CardsPanelsAndTools
@onready var upgrades_panel: Control = $CardsUI/BottomPanel/UpgradesPanel
@onready var roll_button: Button = $CardsUI/BottomPanel/CardsPanelsAndTools/Tools/Roll

@onready var shop_button: Button = $CardsUI/BottomPanel/CardsPanelsAndTools/CardsPanels/ShopSpacer/ShopButton
@onready var shop_key: Control = $CardsUI/BottomPanel/CardsPanelsAndTools/CardsPanels/ShopSpacer/ShopButton/ShopKeyPanel
@onready var percentage_box : Control = $CardsUI/BottomPanel/CardsPanelsAndTools/CardsPanels/ShopSpacer/PercentageBox
@onready var common_label: Label = $CardsUI/BottomPanel/CardsPanelsAndTools/CardsPanels/ShopSpacer/PercentageBox/HBoxContainer/CommonLabel
@onready var rare_label: Label = $CardsUI/BottomPanel/CardsPanelsAndTools/CardsPanels/ShopSpacer/PercentageBox/HBoxContainer/RareLabel
@onready var epic_label: Label = $CardsUI/BottomPanel/CardsPanelsAndTools/CardsPanels/ShopSpacer/PercentageBox/HBoxContainer/EpicLabel
@onready var legendary_label: Label = $CardsUI/BottomPanel/CardsPanelsAndTools/CardsPanels/ShopSpacer/PercentageBox/HBoxContainer/LegendaryLabel

func _ready():
	roll_button.text = "ROLL\n(" + str(Game.shop_roll) + "G)"
	init_cards_array()
	top_button.button_pressed = true
	if !all_cards_common.is_empty():
		call_deferred("fill_the_shop")
	call_deferred("unlock_the_buttons")
	
func on_new_nexus_level():
	common_label.text = "Common: " + str(Game.get("common_"+str(nexusNode.building_tier))) + "%"
	rare_label.text = "Rare: "+str(Game.get("rare_"+str(nexusNode.building_tier))) + "%"
	epic_label.text = "Epic: "+ str(Game.get("epic_"+str(nexusNode.building_tier))) + "%"
	legendary_label.text = "Legendary: " + str(Game.get("legendary_"+str(nexusNode.building_tier))) + "%"
	var cards_to_delete = get_tree().get_nodes_in_group("shop_card")
	for card in cards_to_delete:
		card.queue_free()
	if !all_cards_common.is_empty():
		fill_the_shop()

func init_cards_array():
	for card in Game.human_kingdom_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)
	for card in Game.outlaws_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)
	for card in Game.mountain_clan_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)	
	for card in Game.forest_orcs_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)
	for card in Game.blood_brotherhood_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)	
	for card in Game.undead_pact_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)	
	for card in Game.moon_elves_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)
	for card in Game.sun_elves_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)
	for card in Game.beast_cards_array:
		match card.tier:
			0: 
				all_cards_common.append(card)
			1:
				all_cards_rare.append(card)
			2:
				all_cards_epic.append(card)
			3:
				all_cards_legendary.append(card)
	all_cards_common.shuffle()
	all_cards_rare.shuffle()
	all_cards_epic.shuffle()
	all_cards_legendary.shuffle()

func unlock_the_buttons():
	for node in top_lane_nodes:
		if node.is_in_group("locked"):
			node.get_node("LockedLabel").modulate = Color.WHITE
			node.get_node("UnlockButton").disabled = false
			break
	for node in middle_lane_nodes:
		if node.is_in_group("locked"):
			node.get_node("LockedLabel").modulate = Color.WHITE
			node.get_node("UnlockButton").disabled = false
			break
	for node in bottom_lane_nodes:
		if node.is_in_group("locked"):
			node.get_node("LockedLabel").modulate = Color.WHITE
			node.get_node("UnlockButton").disabled = false
			break

func fill_the_shop():
	var index = 0
	for node in shop_nodes:
		var card: Control = card_scene.instantiate()
		card.add_to_group("shop_card")
		var tier = Game.return_tier(nexusNode.building_tier)
		var resource
		match tier:
			0: resource = all_cards_common.pick_random()
			1: resource = all_cards_rare.pick_random()
			2: resource = all_cards_epic.pick_random()
			3: resource = all_cards_legendary.pick_random()
		card.card_resource = resource
		node.card = card
		var position = node.global_position + node.pivot_offset
		node.add_child(card)
		card.global_position = position
		card.set_rest_node(node)
		card.name = "Card" + str(index) + " " + resource.card_name 
		index += 1

func _process(delta):
	if Input.is_action_just_pressed("open_shop") && !upgrades_open:
		_on_shop_button_pressed()
		
	if Input.is_action_just_pressed("upgrades_left"):
		if lane_value <= 0:
			lane_value = 3
		else:
			lane_value -= 1
		change_lane()
	if Input.is_action_just_pressed("upgrades_right"):
		if lane_value >= 3:
			lane_value = 0
		else:
			lane_value += 1
		change_lane()
		
	if Input.is_action_just_pressed("KEY_1"):
		lane_value = 0
		change_lane()	
	if Input.is_action_just_pressed("KEY_2"):
		lane_value = 1
		change_lane()	
	if Input.is_action_just_pressed("KEY_3"):
		lane_value = 2
		change_lane()
	if Input.is_action_just_pressed("KEY_4"):
		lane_value = 3
		change_lane()	
		
	if Input.is_action_just_released("roll_shop"):
		if roll_button.disabled == false:
			_on_roll_pressed()
		
func change_lane():
	match lane_value:
		0: 
			_on_top_button_pressed()
		1: 
			_on_middle_button_pressed()
		2: 
			_on_bottom_button_pressed()
		3:
			_on_upgrades_button_pressed()

func _on_shop_button_pressed():
	if !ui_open:
		open_ui()
	else:
		hide_ui()

func open_ui():
	roll_button.disabled = false
	percentage_box.visible = true
	shop_key.position = Vector2(73,6)
	shop_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui.position.y -= 175
	ui_open = true
		
func hide_ui():
	roll_button.disabled = true
	percentage_box.visible = false
	shop_key.position  = Vector2(466,6)
	shop_button.alignment  = HORIZONTAL_ALIGNMENT_CENTER
	ui.position.y += 175
	ui_open = false

func _on_roll_pressed():
	var cards_to_delete = get_tree().get_nodes_in_group("shop_card")
	if Game.player_stats[0].gold >= Game.shop_roll:
		Game.player_stats[0].gold -= Game.shop_roll
		for card in cards_to_delete:
			card.queue_free()
		if !all_cards_common.is_empty():
			fill_the_shop()

func _on_top_button_pressed():
	lane_value = 0
	top_button.button_pressed = true
	middle_button.button_pressed = false
	bottom_button.button_pressed = false
	upgrades_button.button_pressed = false
	
	cards_panel.visible = true
	top_lane_deck.visible = true
	middle_lane_deck.visible = false
	bottom_lane_deck.visible = false
	upgrades_panel.visible = false
	
	if upgrades_open:
		if !was_ui_open:
			hide_ui()
			
	upgrades_open = false

func _on_middle_button_pressed():
	lane_value = 1
	top_button.button_pressed = false
	middle_button.button_pressed = true
	bottom_button.button_pressed = false
	upgrades_button.button_pressed = false
	
	cards_panel.visible = true
	top_lane_deck.visible = false
	middle_lane_deck.visible = true
	bottom_lane_deck.visible = false
	upgrades_panel.visible = false
	
	if upgrades_open:
		if !was_ui_open:
			hide_ui()
			
	upgrades_open = false

func _on_bottom_button_pressed():
	lane_value = 2
	top_button.button_pressed = false
	middle_button.button_pressed = false
	bottom_button.button_pressed = true
	upgrades_button.button_pressed = false
	
	cards_panel.visible = true
	top_lane_deck.visible = false
	middle_lane_deck.visible = false
	bottom_lane_deck.visible = true
	upgrades_panel.visible = false
	
	if upgrades_open:
		if !was_ui_open:
			hide_ui()
			
	upgrades_open = false
	
func _on_upgrades_button_pressed():
	lane_value = 3
	top_button.button_pressed = false
	middle_button.button_pressed = false
	bottom_button.button_pressed = false
	upgrades_button.button_pressed = true
	
	cards_panel.visible = false
	upgrades_panel.visible = true
	
	upgrades_open = true
	
	was_ui_open = ui_open
	if !ui_open:
		open_ui()
