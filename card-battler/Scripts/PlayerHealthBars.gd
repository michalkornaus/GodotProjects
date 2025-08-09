extends Control
@onready var nexus_progress_bar: ProgressBar = $NexusProgressBar
@onready var tower_top_bar: ProgressBar = $TowerTopBar
@onready var tower_mid_bar: ProgressBar = $TowerMidBar
@onready var tower_bot_bar: ProgressBar = $TowerBotBar
@onready var barrack_top_bar: ProgressBar = $BarrackTopBar
@onready var barrack_mid_bar: ProgressBar = $BarrackMidBar
@onready var barrack_bot_bar: ProgressBar = $BarrackBotBar
@onready var refresh_timer: Timer = $RefreshTimer
@export_enum("Player 1", "Player 2") var player_enum: int
@export var revert_ui: bool = false
var _nexus: Node3D
var _tower_top: Node3D
var _tower_mid: Node3D
var _tower_bot: Node3D
var _barrack_top: Node3D
var _barrack_mid: Node3D
var _barrack_bot: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var _color: Color
	var buildings: Array[Node]	
	_color = Game.player_stats[player_enum].color
	$NexusLabel.text = "Nexus P" + str(player_enum + 1)
	buildings = get_tree().get_nodes_in_group("player"+str(player_enum + 1))
	nexus_progress_bar.get_theme_stylebox("fill").bg_color = _color
	tower_top_bar.get_theme_stylebox("fill").bg_color = _color
	tower_mid_bar.get_theme_stylebox("fill").bg_color = _color
	tower_bot_bar.get_theme_stylebox("fill").bg_color = _color
	barrack_top_bar.get_theme_stylebox("fill").bg_color = _color
	barrack_mid_bar.get_theme_stylebox("fill").bg_color = _color
	barrack_bot_bar.get_theme_stylebox("fill").bg_color = _color
	if revert_ui:
		var vector_bot = Vector2(250, 0)
		tower_bot_bar.position += vector_bot
		barrack_bot_bar.position += vector_bot
		$LabelBot.position += vector_bot
		var vector_mid = Vector2(190, 0)
		tower_mid_bar.position += vector_mid
		barrack_mid_bar.position += vector_mid
		$LabelMid.position += vector_mid
		var vector_top = Vector2(130, 0)
		tower_top_bar.position += vector_top
		barrack_top_bar.position += vector_top
		$LabelTop.position += vector_top
	for building in buildings:
		match building.building_type:
			0: #Tower
				match building.building_lane:
					0: #Top
						_tower_top = building
					1: #Mid
						_tower_mid = building
					2: #Bot
						_tower_bot = building
			1: #Barrack
				match building.building_lane:
					0: #Top
						_barrack_top = building
					1: #Mid
						_barrack_mid = building
					2: #Bot
						_barrack_bot = building
			2:
				_nexus = building
	nexus_progress_bar.set_max(_nexus.building_health)
	if _tower_top == null:
		tower_top_bar.queue_free()
	else:
		tower_top_bar.set_max(_tower_top.building_health)
	tower_mid_bar.set_max(_tower_mid.building_health)
	if _tower_bot == null:
		tower_bot_bar.queue_free()
	else:
		tower_bot_bar.set_max(_tower_bot.building_health)
	if _barrack_top == null:
		barrack_top_bar.queue_free()
	else:
		barrack_top_bar.set_max(_barrack_top.building_health)
	barrack_mid_bar.set_max(_barrack_mid.building_health)
	if _barrack_bot == null:
		barrack_bot_bar.queue_free()
	else:
		barrack_bot_bar.set_max(_barrack_bot.building_health)
	refresh_bars()
	refresh_timer.start(180)

func  refresh_bars():
	if _nexus != null && nexus_progress_bar != null:
		nexus_progress_bar.set_value(_nexus.health_value)
	elif is_instance_valid(nexus_progress_bar):
		nexus_progress_bar.queue_free()
	if _tower_top != null && tower_top_bar != null:
		tower_top_bar.set_value(_tower_top.health_value)
	elif is_instance_valid(tower_top_bar):
		tower_top_bar.queue_free()
	if _tower_mid != null && tower_mid_bar != null:
		tower_mid_bar.set_value(_tower_mid.health_value)
	elif is_instance_valid(tower_mid_bar):
		tower_mid_bar.queue_free()
	if _tower_bot != null && tower_bot_bar != null:
		tower_bot_bar.set_value(_tower_bot.health_value)
	elif is_instance_valid(tower_bot_bar):
		tower_bot_bar.queue_free()
	if _barrack_top != null && barrack_top_bar != null:
		barrack_top_bar.set_value(_barrack_top.health_value)
	elif is_instance_valid(barrack_top_bar):
		barrack_top_bar.queue_free()
	if _barrack_mid != null && barrack_mid_bar != null:
		barrack_mid_bar.set_value(_barrack_mid.health_value)
	elif is_instance_valid(barrack_mid_bar):
		barrack_mid_bar.queue_free()
	if _barrack_bot != null && barrack_bot_bar != null:
		barrack_bot_bar.set_value(_barrack_bot.health_value)
	elif is_instance_valid(barrack_bot_bar):
		barrack_bot_bar.queue_free()


func _on_refresh_timer_timeout():
	refresh_bars()
	refresh_timer.start(1.5)
