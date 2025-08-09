extends Node3D

@onready var p1_marker_mid: Marker3D = get_node("/root/GameNode/Terrain/Player1_MidSpawner")
@onready var p2_marker_mid: Marker3D = get_node("/root/GameNode/Terrain/Player2_MidSpawner")
@onready var p1_marker_mid_exit: Marker3D = get_node("/root/GameNode/Terrain/Player1_MidExit")
@onready var p2_marker_mid_exit: Marker3D = get_node("/root/GameNode/Terrain/Player2_MidExit")
@onready var midPath: Marker3D = get_node("/root/GameNode/Terrain/MidPath")

@export var minionScene: PackedScene
@export var minion_models: Array[Resource]

@onready var p1_mob_wave_timer = $"../P1MobTimer"
@onready var p2_mob_wave_timer = $"../P2MobTimer"

var current_p1_count: int = 0
var current_p2_count: int = 0

@onready var cardsUI_P1: Node = get_node("/root/GameNode/HUD/CardsP1Debug")
@onready var cardsUI_P2: Node = get_node("/root/GameNode/HUD/CardsP2Debug")

var wave_p1_max_count: int
var p1_mid_count: int = 3

var wave_p2_max_count: int
var p2_mid_count: int = 3

func set_values(team: int):
	match team:
		0:
			var index = 0
			for node in cardsUI_P1.middle_lane_nodes:
				if node.is_in_group("locked"):
					break
				index += 1
			p1_mid_count = index
			#check the value for bot lane
			wave_p1_max_count = p1_mid_count
		1:
			var index = 0
			for node in cardsUI_P2.middle_lane_nodes:
				if node.is_in_group("locked"):
					break
				index += 1
			p2_mid_count = index
			#check the value for bot lane
			wave_p1_max_count = p2_mid_count
	
func spawn_bot(team: String, path: String, marker: Marker3D):
	var target_positions : Array
	var bot_card
	match path:
		"mid":
			if team == "player2":
				bot_card = cardsUI_P2.middle_lane_nodes[current_p2_count].card
				target_positions = [p2_marker_mid_exit.global_position, midPath.global_position, p1_marker_mid_exit.global_position, p1_marker_mid.global_position]
			elif team == "player1":
				bot_card = cardsUI_P1.middle_lane_nodes[current_p1_count].card
				target_positions = [p1_marker_mid_exit.global_position, midPath.global_position, p2_marker_mid_exit.global_position, p2_marker_mid.global_position]
	var model : PackedScene
	if bot_card != null:
		if bot_card.model != null:
			model = bot_card.model
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
	bot.position = marker.global_position
	bot.rotation = marker.global_rotation
	bot.set_targets(target_positions)
	add_child(bot)

func _on_spawn_wave_pressed():
	current_p1_count = 0
	current_p2_count = 0
	set_values(0)
	set_values(1)
	p1_mob_wave_timer.start()
	p2_mob_wave_timer.start()

func _on_p1_mob_timer_timeout():
	if current_p1_count < p1_mid_count:
		spawn_bot("player1", "mid", p1_marker_mid)
		
	current_p1_count += 1
	if current_p1_count == wave_p1_max_count:
		p1_mob_wave_timer.stop()

func _on_p2_mob_timer_timeout():
	if current_p2_count < p2_mid_count:
		spawn_bot("player2", "mid", p2_marker_mid)
		
	current_p2_count += 1
	if current_p2_count == wave_p2_max_count:
		p2_mob_wave_timer.stop()
