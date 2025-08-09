extends Node
enum player_names {Player2, Player3, Player4}
@export var player_name: player_names
@onready var nexus_node: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/"+str(player_names.keys()[player_name])+"_Nexus")
@onready var tower_top_node: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/"+str(player_names.keys()[player_name])+"_TopTower")
@onready var tower_mid_node: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/"+str(player_names.keys()[player_name])+"_MidTower")
@onready var tower_bot_node: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/"+str(player_names.keys()[player_name])+"_BotTower")
@onready var barrack_top_node: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/"+str(player_names.keys()[player_name])+"_TopBarrack")
@onready var barrack_mid_node: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/"+str(player_names.keys()[player_name])+"_MidBarrack")
@onready var barrack_bot_node: Node3D = get_node("/root/GameNode/Terrain/NavigationRegion3D/"+str(player_names.keys()[player_name])+"_BotBarrack")

@export var tower_upgrades_array: Array[Resource]
@export var barrack_upgrades_array: Array[Resource]
@export var nexus_upgrades_array: Array[Resource]

#different tiers of all cards
var all_cards_common: Array
var all_cards_rare: Array
var all_cards_epic: Array
var all_cards_legendary: Array

var top_lane_cards: Array
var middle_lane_cards: Array
var bottom_lane_cards: Array

var shop_cards: Array

enum action_state {DECK_BUILDING, NEW_NEXUS, NEW_TOWER, NEW_BARRACK, NEW_SLOT, FULL_DECKS, NO_MORE_SLOTS, FULL_DECKS_NO_MORE_SLOTS}
var state: action_state

## Variables for controlling decks slots
var no_slots: bool = false
var no_slot_top: bool = false
var no_slot_mid: bool = false
var no_slot_bot: bool = false

## Variables for controlling decks cards
var full_decks: bool = false
var full_deck_top: bool = false
var full_deck_mid: bool = false
var full_deck_bot: bool = false

## Variables for controlling upgrades
var full_nexus: bool = false
var full_tower_top: bool = false
var full_tower_mid: bool = false
var full_tower_bot: bool = false
var full_barrack_top: bool = false
var full_barrack_mid: bool = false
var full_barrack_bot: bool = false

var building_lane: String = ""

var initial_percentages: bool = true
## Dynamic percentages for AI decising mechanism 
var initial_deck_perc: float = 0.9 #0.9 for deck, automatically means 0.1 for nexus etc.

var base_deck_perc: float = 0.70
var base_nexus_perc: float = 0.15
var base_tower_perc: float = 0.05
var base_barrack_perc: float = 0.08
var base_new_slot_perc: float = 0.02

var current_deck_perc: float = base_deck_perc
var current_nexus_perc: float = base_nexus_perc
var current_tower_perc: float = base_tower_perc
var current_barrack_perc: float = base_barrack_perc
var current_new_slot_perc: float = base_new_slot_perc

const card_down_perc: float = 0.06

## Debug section - info panel
@onready var info_panel = $CanvasLayer/InfoPanel
@onready var log_label: RichTextLabel = $CanvasLayer/InfoPanel/DebugLabel
@onready var stats_label: RichTextLabel = $CanvasLayer/InfoPanel/StatsLabel
@onready var perc_label: RichTextLabel = $CanvasLayer/InfoPanel/PercentagesLabel
@onready var info_button: Button = $CanvasLayer/InfoButton
var panel_on: bool = false

func _init():
	state = action_state.DECK_BUILDING
	top_lane_cards.resize(3)
	middle_lane_cards.resize(3)
	bottom_lane_cards.resize(3)
	shop_cards.resize(6)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	if !OS.is_debug_build():
		info_panel.visible = false
		info_button.visible = false
	else:
		info_panel.position.x += player_name * 50
		info_button.position.x += player_name * 50
	init_cards_array()
	roll_the_shop()
	perform_action()
	
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

func _process(delta):
	if Input.is_action_just_released("debug_ai") && OS.is_debug_build():
		panel_on = !panel_on
		if panel_on:
			info_panel.visible = true
		else:
			info_panel.visible = false
	if panel_on:
		show_info()

func _on_info_button_pressed():
	panel_on = !panel_on
	info_panel.visible = panel_on
	
func show_info():
	var top_cards_string: String
	var mid_cards_string: String
	var bot_cards_string: String
	var shop_cards_string: String
	for card in top_lane_cards:
		if card != null:
			top_cards_string += create_color_string(card.card_name, card.tier)
		else:
			top_cards_string += "[color=GRAY]Null[/color], "
	for card in middle_lane_cards:
		if card != null:
			mid_cards_string += create_color_string(card.card_name, card.tier)
		else:
			mid_cards_string += "[color=GRAY]Null[/color], "
	for card in bottom_lane_cards:
		if card != null:
			bot_cards_string += create_color_string(card.card_name, card.tier)
		else:
			bot_cards_string += "[color=GRAY]Null[/color], "
	for card in shop_cards:
		if card != null:
			shop_cards_string += create_color_string(card.card_name, card.tier)
		else:
			shop_cards_string += "[color=GRAY]Null[/color], "
	stats_label.text = "Available gold: " + str(Game.player_stats[player_name + 1].gold) + "\t\t\t\tNexus tier: " + str(nexus_node.building_tier) + "\n" + \
	"Current AI state: " + str(action_state.keys()[state])+"\n" + \
	"Top Lane: " + top_cards_string + "\n" + "Mid Lane: "+  mid_cards_string + "\n" + "Bot Lane: " + bot_cards_string + \
	"\nShop cards: \n" + shop_cards_string
	var perc_sum: float
	if !initial_percentages:
		perc_sum = current_deck_perc + current_nexus_perc + current_tower_perc + current_barrack_perc + current_new_slot_perc
		perc_label.text = "Percentages prints:\n" + "Base deck perc: " + str(current_deck_perc) + "\n" + "Base nexus perc: " + str(current_nexus_perc) + "\n" + \
		"Base tower perc: " + str(current_tower_perc) + "\n" + "Base barrack perc: " + str(current_barrack_perc) + "\n" + "Base new slot perc: " + str(current_new_slot_perc)
	else:
		perc_sum = initial_deck_perc + (1 - initial_deck_perc)
		perc_label.text = "Percentages prints:\n" + "Initial deck perc: " + str(initial_deck_perc) + "\n" + "Initial nexus perc: " + str(1 - initial_deck_perc) + "\n"
	perc_label.text += "\nTotal perc sum: " + str(perc_sum)
	
func create_color_string(_name: String, _tier: int):
	var color_string
	match _tier:
		0:
			color_string = "[color=WHITE]"
		1:
			color_string = "[color=#80c4ff]"
		2:
			color_string = "[color=MEDIUM_ORCHID]"
		3:
			color_string = "[color=DARK_ORANGE]"
	color_string += _name + "[/color], "
	return color_string
	
func new_slot():
	## No slots available on every lane changes action state to NO_MORE_SLOTS
	if no_slot_top && no_slot_mid && no_slot_bot:
		log_label.append_text("No more slots upgrades!\n")
		no_slots = true
		state = action_state.NO_MORE_SLOTS
		return
	## Check if bot has enough gold for new slot - if not return and wait for money
	if Game.player_stats[player_name + 1].gold < 100:
		return
	Game.player_stats[player_name + 1].gold -= 100
	## Check what lanes have slots to buy
	var lane_array: Array
	if !no_slot_top:
		lane_array.append(0)
	if !no_slot_mid:
		lane_array.append(1)
	if !no_slot_bot:
		lane_array.append(2)
	var lane = lane_array.pick_random()
	var array_string: String
	match lane:
		0: array_string = "top_lane_cards"
		1: array_string = "middle_lane_cards"
		2: array_string = "bottom_lane_cards"
	if get(array_string).size() < 6:
		get(array_string).append(null)
		get(array_string).sort_custom(sort_team)
		log_label.append_text("Bot have new slot at " + array_string.get_slice("_", 0).capitalize() + "!\n")
		match lane:
			0: full_deck_top = false
			1: full_deck_mid = false
			2: full_deck_bot = false
	if get(array_string).size() == 6: ## Deck is full - no more slots to buy!
		match lane:
			0: no_slot_top = true
			1: no_slot_mid = true
			2: no_slot_bot = true
	## After completing action without interruption, bot has a chance to change current action state
	change_action()
	
func adjust_percentages(action: String, tier: int):
	var items: float = 0
	if !full_decks && action != "card":
		items += 1
	if !no_slots && action != "slot":
		items += 1
	if !full_nexus && action != "nexus":
		items += 1
	if action != "tower" && (!full_tower_top || !full_tower_mid || !full_tower_bot):
		items += 1
	if action != "barrack" && (!full_barrack_top || !full_barrack_mid || !full_barrack_bot):
		items += 1
	if items <= 0:
		log_label.append_text("Adjusting percentages - No action available, Returning!\n")
		return
	var split_perc: float
	var snapped_value: float = 0.01
	match action:
		"card":
			current_deck_perc -= card_down_perc
			split_perc = snapped(card_down_perc / items, snapped_value)
		"tower":
			var diff_perc: float = 0.015 + (0.01 * tier)
			current_tower_perc = snapped(base_tower_perc - diff_perc, snapped_value)
			split_perc = snapped(diff_perc / items, snapped_value)
		"nexus":
			var diff_perc: float = 0.03 + (0.01 * tier)
			current_nexus_perc = snapped(base_nexus_perc - diff_perc, snapped_value)
			split_perc = snapped(diff_perc / items, snapped_value)
		"barrack":
			var diff_perc: float = 0.015 + (0.01 * tier)
			current_barrack_perc = snapped(base_barrack_perc - diff_perc, snapped_value)
			split_perc = snapped(diff_perc / items, snapped_value)
		"slot":
			pass
	if !no_slots && action != "slot":
		current_new_slot_perc = base_new_slot_perc + split_perc
	if action != "tower" && (!full_tower_top || !full_tower_mid || !full_tower_bot):
		current_tower_perc = base_tower_perc + split_perc
	if !full_nexus && action != "nexus":
		current_nexus_perc = base_nexus_perc + split_perc
	if !full_decks && action != "card":
		current_deck_perc = base_deck_perc + split_perc
	if action != "barrack" && (!full_barrack_top || !full_barrack_mid || !full_barrack_bot):
		current_barrack_perc = base_barrack_perc + split_perc
	
func new_card():
	if full_deck_top && full_deck_mid && full_deck_bot:
		log_label.append_text("All decks are full!\n")
		full_decks = true
		state = action_state.FULL_DECKS
		return
	var card = pick_best_from_shop()
	if card == null:
		return
	if Game.player_stats[player_name + 1].gold < card.cost:
		return
	Game.player_stats[player_name + 1].gold -= card.cost
	## Check what deck lanes have empty slots for card
	var lane_array: Array
	if !full_deck_top:
		lane_array.append(0)
	if !full_deck_mid:
		lane_array.append(1)
	if !full_deck_bot:
		lane_array.append(2)
	var lane = lane_array.pick_random()
	var array_string: String
	match lane:
		0: array_string = "top_lane_cards"
		1: array_string = "middle_lane_cards"
		2: array_string = "bottom_lane_cards"
	for index in get(array_string).size():
		if get(array_string)[index] == null:
			get(array_string)[index] = card
			log_label.append_text("New "+ array_string.get_slice("_", 0).capitalize() +" card: " + card.card_name + ", " + str(card.health) + "HP, "+ \
			str(Game.mob_class.keys()[card.type]).capitalize() + " " + str(Game.mob_sub_class.keys()[card.sub_type]).capitalize() + \
			", " + str(card.cost) +' Gold\n')
			var card_to_remove = shop_cards.find(card)
			shop_cards[card_to_remove] = null
			get(array_string).sort_custom(sort_team)
			if !initial_percentages:
				adjust_percentages("card", 0)
			## After completing action without interruption, bot has a chance to change current action state
			change_action()
			break
	if is_deck_full(array_string) == true:
		log_label.append_text(array_string.get_slice("_", 0).capitalize() + " Deck full!\n")
		match lane:
			0: full_deck_top = true
			1: full_deck_mid = true
			2: full_deck_bot = true

func is_deck_full(lane_string: String):
	for index in get(lane_string).size():
		if get(lane_string)[index] == null:
			return false
	return true

func sort_team(a_card, b_card):
	var a_value = 0
	var b_value = 0
	if a_card != null:
		a_value = a_card.type
	if b_card != null:
		b_value = b_card.type
	if a_value < b_value:
		return true
	return false
	
func is_shop_empty():
	for card in shop_cards:
		if card != null:
			return false
	return true
	
func roll_the_shop():
	for index in shop_cards.size():
		var tier = Game.return_tier(nexus_node.building_tier)
		var resource
		match tier:
			0: resource = all_cards_common.pick_random()
			1: resource = all_cards_rare.pick_random()
			2: resource = all_cards_epic.pick_random()
			3: resource = all_cards_legendary.pick_random()
		shop_cards[index] = resource
							
func pick_best_from_shop():
	var best_card
	var card_stats = 0.0
	for card in shop_cards:	
		if card != null:
			var _stats = card.attack_damage + card.armor + card.health
			if _stats > card_stats:
				card_stats = _stats
				best_card = card
	if card_stats == 0:
		return null
	else:
		return best_card		

func sell_worst_card():
	## Sell worst card and find better for a deck
	change_action()
	pass

func deck_building():
	## When there no slots to buy and all decks are full - check the decks and buy better cards
	#WARNING - Implement selling cards by bot in deck building function!
	if no_slots && full_decks:
		sell_worst_card()
		#print("Sell the worst card in the deck and replace it! NOT IMPLEMENTED YET!")
		return
	## Before buying card check if there are any cards left in shop - if not roll
	if !is_shop_empty():
		call_deferred("new_card")
	else:
		## Roll the shop, if there is enough money try to buy the card
		if Game.player_stats[player_name + 1].gold >= Game.shop_roll:
			Game.player_stats[player_name + 1].gold -= Game.shop_roll
			log_label.append_text("Shop empty - rolling it!\n")
			roll_the_shop()
			call_deferred("new_card")

func new_upgrade(upgrade_type: String, lane: String):
	if lane.is_empty():
		match upgrade_type:
			"nexus":
				building_lane = ""
			"tower":
				## Get random lane if not specified already
				var lane_array: Array
				if !full_tower_top:
					lane_array.append("top")
				if !full_tower_mid:
					lane_array.append("mid")
				if !full_tower_bot:
					lane_array.append("bot")
				building_lane = lane_array.pick_random()
			"barrack":
				## Get random lane if not specified already
				var lane_array: Array
				if !full_barrack_top:
					lane_array.append("top")
				if !full_barrack_mid:
					lane_array.append("mid")
				if !full_barrack_bot:
					lane_array.append("bot")
				building_lane = lane_array.pick_random()
	var building: Node3D
	if building_lane.is_empty(): 
		building = get(upgrade_type + "_node") 
	else:
		if is_instance_valid(get(upgrade_type + "_" + building_lane + "_node")):
			building = get(upgrade_type + "_" + building_lane + "_node")
		else:
			building = null
	if building == null:
		match upgrade_type:
			"nexus":
				full_nexus = true
				base_nexus_perc = 0.0
				current_nexus_perc = 0.0
			"tower":
				match building_lane:
					"top":
						full_tower_top = true
					"mid":
						full_tower_mid = true
					"bot":
						full_tower_bot = true
			"barrack":
				match building_lane:
					"top":
						full_barrack_top = true
					"mid":
						full_barrack_mid = true
					"bot":
						full_barrack_bot = true
		log_label.append_text(building_lane.capitalize() + " " + upgrade_type.capitalize() + " destroyed!\n")
		if full_tower_top && full_tower_mid && full_tower_bot:
			log_label.append_text("All towers destroyed!\n")
			base_tower_perc = 0.0
			current_tower_perc = 0.0
		if full_barrack_top && full_barrack_mid && full_barrack_bot:
			log_label.append_text("All barracks destroyed!\n")
			base_barrack_perc = 0.0
			current_barrack_perc = 0.0
		change_action()
		return
	var tier = building.building_tier
	var array: Array = get(upgrade_type+"_upgrades_array")
	## If player does not have enough money for upgrade, return
	if array[tier].upgrade_cost > Game.player_stats[player_name + 1].gold:
		return
	Game.player_stats[player_name + 1].gold -= array[tier].upgrade_cost
	building.building_tier = tier + 1
	building.health_value += array[tier].bonus_health
	building.building_health += array[tier].bonus_health
	building.building_damage += array[tier].bonus_damage
	building.building_armor +=  array[tier].bonus_armor
	building.building_speed -= array[tier].bonus_speed
	building.building_range += array[tier].bonus_range
	if array[tier].passive_gold > 0:
		if building.passive_gold_enabled == false:
			building.passive_gold_enabled = true
		building.passive_gold_amount = array[tier].passive_gold
		building.passive_gold_time = array[tier].passive_gold_per_seconds
	log_label.append_text(building_lane.capitalize() + " " + upgrade_type.capitalize() + " upgraded to Tier " + str(tier + 1) + "\n")
	adjust_percentages(upgrade_type, tier + 1)
	building.update_stats()
	if upgrade_type == "nexus":
		roll_the_shop()
	## If there are no more upgrades after the current one
	## TowerUpgrades - array.size = 3, tier - 0,1,2,3
	if tier + 1 >= array.size():
		match upgrade_type:
			"nexus":
				full_nexus = true
				log_label.append_text("Nexus fully upgraded!\n")
				base_tower_perc = 0.0
				current_tower_perc = 0.0
			"tower":
				match building_lane:
					"top":
						full_tower_top = true
					"mid":
						full_tower_mid = true
					"bot":
						full_tower_bot = true
			"barrack":
				match building_lane:
					"top":
						full_barrack_top = true
					"mid":
						full_barrack_mid = true
					"bot":
						full_barrack_bot = true
		log_label.append_text(building_lane.capitalize() + " " + upgrade_type.capitalize() + " fully upgraded!\n")
		if full_tower_top && full_tower_mid && full_tower_bot:
			log_label.append_text("All towers fully upgraded!\n")
			base_tower_perc = 0.0
			current_tower_perc = 0.0
		if full_barrack_top && full_barrack_mid && full_barrack_bot:
			log_label.append_text("All barracks fully upgraded!\n")
			base_barrack_perc = 0.0
			current_barrack_perc = 0.0
	building_lane = ""
	change_action()

## AI decides what action to perform
func perform_action():
	match state:
		action_state.DECK_BUILDING:
			deck_building()
		action_state.NEW_NEXUS:
			new_upgrade("nexus", "")
		action_state.NEW_TOWER:
			new_upgrade("tower", building_lane)
		action_state.NEW_BARRACK:
			new_upgrade("barrack", building_lane)
		action_state.NEW_SLOT:
			new_slot()
		action_state.FULL_DECKS: ## Full decks - check if there are slots to buy
			if !no_slots:
				new_slot()
			else:
				action_state.FULL_DECKS_NO_MORE_SLOTS
				deck_building()
		action_state.NO_MORE_SLOTS: ## No more slots - check if there are cards to buy
			if full_decks:
				action_state.FULL_DECKS_NO_MORE_SLOTS
				deck_building()
			else:
				deck_building()
		action_state.FULL_DECKS_NO_MORE_SLOTS: ## No more slots or cards - manage deck
			log_label.append_text("No more cards or slots to buy!\n")
			deck_building()
	
func change_action():
	var max_perc = current_deck_perc + current_nexus_perc + current_tower_perc + current_barrack_perc + current_new_slot_perc
	var value = randf_range(0.0, max_perc)
	if initial_percentages:
		if value >= initial_deck_perc:
			## buy nexus upgrade
			initial_percentages = false
			state = action_state.NEW_NEXUS
		else:
			## buy new deck card
			initial_deck_perc -= 0.1
			state = action_state.DECK_BUILDING
	else:
		if value < current_deck_perc:
			state = action_state.DECK_BUILDING
		elif !full_nexus && value < current_deck_perc + current_nexus_perc:
			state = action_state.NEW_NEXUS
		elif value < current_deck_perc + current_nexus_perc + current_tower_perc:
			state = action_state.NEW_TOWER
		elif value < current_deck_perc + current_nexus_perc + current_tower_perc + current_barrack_perc:
			state = action_state.NEW_BARRACK
		elif value <= max_perc:
			state = action_state.NEW_SLOT
	log_label.append_text("New state action: " + str(action_state.keys()[state])+"\n")

func _on_action_timer_timeout():
	perform_action()

func _on_close_button_pressed():
	panel_on = false
	info_panel.visible = false
	info_button.visible = true
