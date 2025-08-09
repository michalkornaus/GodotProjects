extends Node3D

@onready var p1_marker_top: Marker3D = get_node("/root/GameNode/Terrain/Player1_TopSpawner")
@onready var p1_marker_mid: Marker3D = get_node("/root/GameNode/Terrain/Player1_MidSpawner")
@onready var p1_marker_bot: Marker3D = get_node("/root/GameNode/Terrain/Player1_BotSpawner")

@onready var p2_marker_top: Marker3D = get_node("/root/GameNode/Terrain/Player2_TopSpawner")
@onready var p2_marker_mid: Marker3D = get_node("/root/GameNode/Terrain/Player2_MidSpawner")
@onready var p2_marker_bot: Marker3D = get_node("/root/GameNode/Terrain/Player2_BotSpawner")

@onready var p1_marker_top_exit: Marker3D = get_node("/root/GameNode/Terrain/Player1_TopExit")
@onready var p1_marker_mid_exit: Marker3D = get_node("/root/GameNode/Terrain/Player1_MidExit")
@onready var p1_marker_bot_exit: Marker3D = get_node("/root/GameNode/Terrain/Player1_BotExit")

@onready var p2_marker_top_exit: Marker3D = get_node("/root/GameNode/Terrain/Player2_TopExit")
@onready var p2_marker_mid_exit: Marker3D = get_node("/root/GameNode/Terrain/Player2_MidExit")
@onready var p2_marker_bot_exit: Marker3D = get_node("/root/GameNode/Terrain/Player2_BotExit")

@onready var botPath: Marker3D = get_node("/root/GameNode/Terrain/BotPath")
@onready var topPath: Marker3D = get_node("/root/GameNode/Terrain/TopPath")
@onready var midPath: Marker3D = get_node("/root/GameNode/Terrain/MidPath")

@onready var ai_controller: Node = get_node("/root/GameNode/AIControllerP2") 

@export var minionScene: PackedScene
@export var minion_models: Array

@onready var start_timer = $"../StartDelayTimer"
@onready var wave_timer = $"../WaveTimer"
@onready var p1_mob_wave_timer = $"../P1MobTimer"
@onready var p2_mob_wave_timer = $"../P2MobTimer"
@onready var upper_panel_wave_time_label: Label = get_node("/root/GameNode/HUD/GameUIManager/HUD/Labels/UpperPanel/WaveTimer")
@onready var p1_nexus_label = get_node("/root/GameNode/Terrain/NavigationRegion3D/Player1_Nexus/TimerLabel")
@onready var p2_nexus_label = get_node("/root/GameNode/Terrain/NavigationRegion3D/Player2_Nexus/TimerLabel")

var current_p1_count: int = 0
var current_p2_count: int = 0

var cardsUI: CanvasLayer
#amount of p1 minions per lane 
var wave_p1_max_count: int
var p1_top_count: int = 3
var p1_mid_count: int = 3
var p1_bot_count: int = 3
#amount of p2 minions per lane 
var wave_p2_max_count: int
var p2_top_count: int = 3
var p2_mid_count: int = 3
var p2_bot_count: int = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	cardsUI = get_tree().get_first_node_in_group("CardsUI")
	start_timer.wait_time = Game.start_delay_time
	wave_timer.wait_time = Game.wave_time
	start_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !wave_timer.is_stopped() && p1_nexus_label != null:
		p1_nexus_label.set_text("Next wave in: %.fs" % wave_timer.time_left)
		upper_panel_wave_time_label.set_text("Next wave in: %.fs" % wave_timer.time_left)
	elif !start_timer.is_stopped() && p1_nexus_label != null:
		p1_nexus_label.set_text("Next wave in: %.fs" % start_timer.time_left)
		upper_panel_wave_time_label.set_text("Next wave in: %.fs" % start_timer.time_left)
		
	if !wave_timer.is_stopped() && p2_nexus_label != null:
		p2_nexus_label.set_text("Next wave in: %.fs" % wave_timer.time_left)
	elif !start_timer.is_stopped() && p2_nexus_label != null:
		p2_nexus_label.set_text("Next wave in: %.fs" % start_timer.time_left)

func set_local_player_values():
	#check the value for top lane
	var index = 0
	for node in cardsUI.top_lane_nodes:
		if node.is_in_group("locked"):
			break
		index += 1
	p1_top_count = index
	#check the value for mid lane
	index = 0
	for node in cardsUI.middle_lane_nodes:
		if node.is_in_group("locked"):
			break
		index += 1
	p1_mid_count = index
	#check the value for bot lane
	index = 0
	for node in cardsUI.bottom_lane_nodes:
		if node.is_in_group("locked"):
			break
		index += 1
	p1_bot_count = index
	wave_p1_max_count = max(p1_top_count, p1_mid_count, p1_bot_count)
	
func set_players_values():
	for index in Game.player_stats.size():
		if index == 0: # set the values for local player 1
			set_local_player_values()
			continue
		match index:
			1:
				p2_top_count = ai_controller.top_lane_cards.size()
				p2_mid_count = ai_controller.middle_lane_cards.size()
				p2_bot_count = ai_controller.bottom_lane_cards.size()
				wave_p2_max_count = max(p2_top_count, p2_mid_count, p2_bot_count)
	
func start_wave():
	set_players_values()
	wave_timer.start()
	p1_mob_wave_timer.start()
	p2_mob_wave_timer.start()
	
func spawn_bot(team: String, path: String, marker: Marker3D):
	var target_positions : Array
	var bot_card
	match path:
		"bot":
			if team == "player2":
				target_positions = [p2_marker_bot_exit.global_position, botPath.global_position, p1_marker_bot_exit.global_position, p1_marker_bot.global_position]
				bot_card = ai_controller.bottom_lane_cards[current_p2_count]
			elif team == "player1":
				bot_card = cardsUI.bottom_lane_nodes[current_p1_count].card
				target_positions = [p1_marker_bot_exit.global_position, botPath.global_position, p2_marker_bot_exit.global_position, p2_marker_bot.global_position]
		"mid":
			if team == "player2":
				bot_card = ai_controller.middle_lane_cards[current_p2_count]
				target_positions = [p2_marker_mid_exit.global_position, midPath.global_position, p1_marker_mid_exit.global_position, p1_marker_mid.global_position]
			elif team == "player1":
				bot_card = cardsUI.middle_lane_nodes[current_p1_count].card
				target_positions = [p1_marker_mid_exit.global_position, midPath.global_position, p2_marker_mid_exit.global_position, p2_marker_mid.global_position]
		"top":
			if team == "player2":
				bot_card = ai_controller.top_lane_cards[current_p2_count]
				target_positions = [p2_marker_top_exit.global_position, topPath.global_position, p1_marker_top_exit.global_position, p1_marker_top.global_position]
			elif team == "player1":
				bot_card = cardsUI.top_lane_nodes[current_p1_count].card
				target_positions = [p1_marker_top_exit.global_position, topPath.global_position, p2_marker_top_exit.global_position, p2_marker_top.global_position]
	var model : PackedScene
	if bot_card != null:
		if bot_card.model != null:
			model = bot_card.model
		#INFO Placeholder model setting based on card race if card's model is empty
		#0 - HUMAN_KINGDOM, 1 - OUTLAWS, 2 - MOUNTAIN_CLAN, 3 - FOREST_ORCS, 4 - BLOOD_BROTHERHOOD
		#5 - UNDEAD_PACT, 6 - MOON_ELVES, 7 - SUN_ELVES, 8 - BEAST
		match bot_card.race:
			0, 6, 7:
				model = minion_models[7]
			1:
				model = minion_models[6]
			2, 3:
				model = minion_models[1]
			4:
				model = minion_models[5]
			5:
				model = minion_models[3]
			8:
				model = minion_models[2]
	else:
		model = minion_models[0]
	var bot: CharacterBody3D
	bot = minionScene.instantiate()
	bot.initialize(bot_card, team, path, model)
	bot.position = marker.position
	bot.rotation = marker.rotation
	bot.set_targets(target_positions)
	add_child(bot)
	
func interest_gold():
	for player in Game.player_stats:
		if player.gold > 99:
			var add_gold = min(player.gold, 500)
			player.gold += (add_gold/100)*10
	
func _on_wave_timer_timeout():
	set_players_values()
	interest_gold()
	wave_timer.start()
	current_p1_count = 0
	current_p2_count = 0
	p1_mob_wave_timer.start()
	p2_mob_wave_timer.start()

func _on_p1_mob_timer_timeout():
	if current_p1_count < p1_top_count:
		spawn_bot("player1", "top", p1_marker_top)
	if current_p1_count < p1_mid_count:
		spawn_bot("player1", "mid", p1_marker_mid)
	if current_p1_count < p1_bot_count:
		spawn_bot("player1", "bot", p1_marker_bot)

	current_p1_count += 1
	if current_p1_count == wave_p1_max_count:
		p1_mob_wave_timer.stop()

func _on_p2_mob_timer_timeout():
	if current_p2_count < p2_top_count:
		spawn_bot("player2", "top", p2_marker_top)
	if current_p2_count < p2_mid_count:
		spawn_bot("player2", "mid", p2_marker_mid)
	if current_p2_count < p2_bot_count:
		spawn_bot("player2", "bot", p2_marker_bot)
		
	current_p2_count += 1
	if current_p2_count == wave_p2_max_count:
		p2_mob_wave_timer.stop()
	
func _on_start_delay_timer_timeout():
	start_wave()
