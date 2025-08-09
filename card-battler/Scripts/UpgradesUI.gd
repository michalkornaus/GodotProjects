extends HBoxContainer

##INFO upgrades variables
@export var upgrade_info_panel: Panel
@export var tower_upgrades_array: Array[Resource]
@export var barrack_upgrades_array: Array[Resource]
@export var nexus_upgrades_array: Array[Resource]

@export var delay_timer: Timer

var format_upgrade_cost: String = "> UPGRADE COST: [b][color=#dbac34]%sG[/color][/b]"
var format_bonus_health: String = "\n> HEALTH: %sHP -> [b][color=#53c349]%sHP[/color][/b] ([color=#53c349]+%sHP[/color])"
var format_bonus_damage: String = "\n> DAMAGE: %sAD -> [b][color=#fc8f78]%sAD[/color][/b] ([color=#fc8f78]+%sAD[/color])"
var format_bonus_armor: String = "\n> ARMOR: %sARM -> [b][color=#37b0ec]%sARM[/color][/b] ([color=#37b0ec]+%sARM[/color])"
var format_bonus_speed: String = "\n> SPEED: %ss -> [b][color=WHITE]%ss[/color][/b] ([color=WHITE]-%ss[/color])"
var format_bonus_range: String = "\n> RANGE: %s -> [b][color=WHITE]%s[/color][/b] ([color=WHITE]+%s[/color])"
var format_bonus_pen: String = "\n> ARMOR PEN: %s -> [b][color=WHITE]%s[/color][/b] ([color=WHITE]+%s[/color])"
var format_bonus_aoe: String = "\n> AOE: %s -> [b][color=WHITE]%s[/color][/b] ([color=WHITE]+%s[/color])"
var format_bonus_gold: String = "\n> GOLD INCOME: %sG/1s -> [b][color=GOLD]%sG[/color]/1s[/b]"

@onready var top_tower_button : Button = $TowerUpgrades/TopTower
var top_tower_tier: int = 0
@onready var mid_tower_button : Button = $TowerUpgrades/MidTower
var mid_tower_tier: int = 0
@onready var bot_tower_button : Button = $TowerUpgrades/BotTower
var bot_tower_tier: int = 0
@onready var top_barrack_button : Button = $BarrackUpgrades/TopBarrack
var top_barrack_tier: int = 0
@onready var mid_barrack_button : Button = $BarrackUpgrades/MidBarrack
var mid_barrack_tier: int = 0
@onready var bot_barrack_button : Button = $BarrackUpgrades/BotBarrack
var bot_barrack_tier: int = 0
@onready var nexus_button : Button = $NexusUpgrades/Nexus
var nexus_tier: int = 0

func _ready():
	top_tower_button.text = "TOP TOWER UPGRADE TIER 1\nCOST - " + str(tower_upgrades_array[0].upgrade_cost) + "G"
	mid_tower_button.text = "MID TOWER UPGRADE TIER 1\nCOST - " + str(tower_upgrades_array[0].upgrade_cost)+ "G"
	bot_tower_button.text = "BOT TOWER UPGRADE TIER 1\nCOST - " + str(tower_upgrades_array[0].upgrade_cost)+ "G"
	top_barrack_button.text = "TOP BARRACK UPGRADE TIER 1\nCOST - " + str(barrack_upgrades_array[0].upgrade_cost)+ "G"
	mid_barrack_button.text = "MID BARRACK UPGRADE TIER 1\nCOST - " + str(barrack_upgrades_array[0].upgrade_cost)+ "G"
	bot_barrack_button.text = "BOT BARRACK UPGRADE TIER 1\nCOST - " + str(barrack_upgrades_array[0].upgrade_cost)+ "G"
	nexus_button.text = "NEXUS UPGRADE TIER 1\nCOST - " + str(nexus_upgrades_array[0].upgrade_cost)+ "G"
	
func _process(delta):
	if top_tower_tier < tower_upgrades_array.size():
		if tower_upgrades_array[top_tower_tier].upgrade_cost > Game.player_stats[0].gold:
			top_tower_button.disabled = true
		else:
			top_tower_button.disabled = false
	if mid_tower_tier < tower_upgrades_array.size():
		if tower_upgrades_array[mid_tower_tier].upgrade_cost > Game.player_stats[0].gold:
			mid_tower_button.disabled = true
		else:
			mid_tower_button.disabled = false
	if bot_tower_tier < tower_upgrades_array.size():
		if tower_upgrades_array[bot_tower_tier].upgrade_cost > Game.player_stats[0].gold:
			bot_tower_button.disabled = true
		else:
			bot_tower_button.disabled = false
	if top_barrack_tier < barrack_upgrades_array.size():
		if barrack_upgrades_array[top_barrack_tier].upgrade_cost > Game.player_stats[0].gold:
			top_barrack_button.disabled = true
		else:
			top_barrack_button.disabled = false
	if mid_barrack_tier < barrack_upgrades_array.size():
		if barrack_upgrades_array[mid_barrack_tier].upgrade_cost > Game.player_stats[0].gold:
			mid_barrack_button.disabled = true
		else:
			mid_barrack_button.disabled = false
	if bot_barrack_tier < barrack_upgrades_array.size():
		if barrack_upgrades_array[bot_barrack_tier].upgrade_cost > Game.player_stats[0].gold:
			bot_barrack_button.disabled = true
		else:
			bot_barrack_button.disabled = false
	if nexus_tier < nexus_upgrades_array.size():
		if nexus_upgrades_array[nexus_tier].upgrade_cost > Game.player_stats[0].gold:
			nexus_button.disabled = true
		else:
			nexus_button.disabled = false

func update_upgrade_panel(type: String, lane: String, tier: int):
	var building = get_tree().get_nodes_in_group(lane.capitalize()+type.capitalize())[0]
	#INFO gets custom upgrade info panel text based on buttons variables
	var _lane : String = "" if lane == "" else lane.capitalize() + " Lane"
	upgrade_info_panel.get_node("Title").text = type.capitalize() + " " + _lane+"\nUpgrade the building to Tier " + str(tier)
	#INFO gets custom upgrade info description text
	var array_index = tier - 1 
	var array = get(type+"_upgrades_array")
	upgrade_info_panel.get_node("Description").text = "\n\n"
	upgrade_info_panel.get_node("Description").text += format_upgrade_cost % [array[array_index].upgrade_cost]
	var _hp = building.building_health
	var _bonus_hp = array[array_index].bonus_health
	upgrade_info_panel.get_node("Description").text += format_bonus_health % [_hp, _hp + _bonus_hp, _bonus_hp]
	var offset_value = 35
	upgrade_info_panel.size = Vector2(280, 130)
	if array[array_index].bonus_damage > 0:
		var _value = building.building_damage
		var _bonus_value = array[array_index].bonus_damage
		upgrade_info_panel.get_node("Description").text += format_bonus_damage % [_value, _value + _bonus_value, _bonus_value]
		upgrade_info_panel.size += Vector2(0, offset_value)
	if array[array_index].bonus_armor > 0:
		var _value = building.building_armor
		var _bonus_value = array[array_index].bonus_armor
		upgrade_info_panel.get_node("Description").text += format_bonus_armor % [_value, _value + _bonus_value, _bonus_value]
		upgrade_info_panel.size += Vector2(0, offset_value)
	if array[array_index].bonus_range > 0:
		var _value = building.building_range
		var _bonus_value = array[array_index].bonus_range
		upgrade_info_panel.get_node("Description").text += format_bonus_range % [_value, _value + _bonus_value, _bonus_value]
		upgrade_info_panel.size += Vector2(0, offset_value)
	if array[array_index].bonus_speed > 0:
		var _value = building.building_speed
		var _bonus_value = array[array_index].bonus_speed
		upgrade_info_panel.get_node("Description").text += format_bonus_speed % [_value, _value - _bonus_value, _bonus_value]
		upgrade_info_panel.size += Vector2(0, offset_value)
	if array[array_index].bonus_aoe > 0:
		var _value = building.aoe_dmg_percentage
		var _bonus_value = array[array_index].bonus_aoe
		upgrade_info_panel.get_node("Description").text += format_bonus_aoe % [_value, _value + _bonus_value, _bonus_value]
		upgrade_info_panel.size += Vector2(0, offset_value)
	if array[array_index].bonus_pen > 0:
		var _value = building.building_penetration
		var _bonus_value = array[array_index].bonus_pen
		upgrade_info_panel.get_node("Description").text += format_bonus_pen % [_value, _value + _bonus_value, _bonus_value]
		upgrade_info_panel.size += Vector2(0, offset_value)
	if array[array_index].passive_gold > 0:
		var _value = building.passive_gold_amount
		var _value_time = building.passive_gold_time
		var _building_gps = 0
		if _value > 0:
			_building_gps = _value/_value_time
		var _bonus_value = array[array_index].passive_gold
		var _bonus_time = array[array_index].passive_gold_per_seconds
		var _bonus_gps = _bonus_value/_bonus_time
		upgrade_info_panel.get_node("Description").text += format_bonus_gold % [snapped(_building_gps, 0.01) , snapped(_bonus_gps, 0.01)]
		upgrade_info_panel.get_node("Description").text += "\n> Increased chance of better cards!"
		upgrade_info_panel.get_node("Description").text += "\n> Rolls the shop after the upgrade!"
		upgrade_info_panel.size += Vector2(0, offset_value * 3)
	var panel_pos = get_global_mouse_position()
	if panel_pos.y + upgrade_info_panel.size.y > get_viewport_rect().size.y:
		panel_pos.y -= panel_pos.y + upgrade_info_panel.size.y - get_viewport_rect().size.y
	upgrade_info_panel.position = panel_pos
	upgrade_info_panel.visible = true

func _on_upgrade_button_mouse_entered(type: String, lane: String, tier: int):
	delay_timer.start()
	await delay_timer.timeout
	var node_string = type.capitalize()+"Upgrades/"+lane.capitalize()+type.capitalize()
	if get_node(node_string).disabled == true:
		return
	update_upgrade_panel(type, lane, tier)
	
func _on_upgrade_button_mouse_exited():
	delay_timer.stop()
	upgrade_info_panel.visible = false
	upgrade_info_panel.get_node("Title").text = ""
	upgrade_info_panel.get_node("Description").text = ""
	
func _on_upgrade_button_pressed(type: String, lane: String, tier: int):
	var array_index = tier - 1 
	var array: Array = get(type+"_upgrades_array")
	#If player does not have enough money for upgrade
	if array[array_index].upgrade_cost > Game.player1_gold:
		print("Not enought money!")
		return
	upgrade_info_panel.visible = false
	upgrade_info_panel.get_node("Title").text = ""
	upgrade_info_panel.get_node("Description").text = ""
	Game.player1_gold -= array[array_index].upgrade_cost
	var node_string = ""
	node_string = type.capitalize()+"Upgrades/"+lane.capitalize()+type.capitalize()
	var building = get_tree().get_nodes_in_group(lane.capitalize()+type.capitalize())[0] #0 - p1 team, 1 - p2 team
	var button = get_node(node_string)
	building.building_tier = tier
	building.health_value += array[array_index].bonus_health
	building.building_health += array[array_index].bonus_health
	building.building_damage += array[array_index].bonus_damage
	building.building_armor +=  array[array_index].bonus_armor
	building.building_speed -= array[array_index].bonus_speed
	building.building_range += array[array_index].bonus_range
	building.building_penetration += array[array_index].bonus_pen
	if array[array_index].passive_gold > 0:
		if building.passive_gold_enabled == false:
			building.passive_gold_enabled = true
		building.passive_gold_amount = array[array_index].passive_gold
		building.passive_gold_time = array[array_index].passive_gold_per_seconds
	#INFO building.building_health - maximum health of building
	#INFO building._health_value - current health value of building
	building.update_stats()
	if type == "nexus":
		get_tree().get_first_node_in_group("CardsUI").on_new_nexus_level()
		nexus_tier += 1
	else:
		var _str = str(lane + "_"+ type+"_tier")
		var _value = get(lane + "_"+ type+"_tier")
		set(_str, _value + 1)
	if array_index < array.size() - 1:
		button.text = lane.to_upper() + " " + type.to_upper() + " UPGRADE TIER "+ str(tier + 1) +"\nCOST - " + str(array[tier].upgrade_cost) + "G"
		button.disconnect("pressed", _on_upgrade_button_pressed)
		button.pressed.connect(_on_upgrade_button_pressed.bind(type, lane, tier + 1))
		button.disconnect("mouse_entered", _on_upgrade_button_mouse_entered)
		button.mouse_entered.connect(_on_upgrade_button_mouse_entered.bind(type, lane, tier + 1))
		_on_upgrade_button_mouse_entered(type, lane, tier + 1)
	else:
		button.text = lane.to_upper() + " " + type.to_upper() + " IS FULLY UPGRADED!"
		button.disabled = true
