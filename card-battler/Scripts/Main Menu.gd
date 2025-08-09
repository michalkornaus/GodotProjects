extends Node2D

@onready var player1_gold_box: SpinBox = $MainMenu/DebugPanel/P1GoldInputBox
@onready var player2_gold_box: SpinBox = $MainMenu/DebugPanel/P2GoldInputBox
@onready var wave_time_box: SpinBox = $MainMenu/DebugPanel/WaveTimeInputBox
@onready var start_time_box: SpinBox = $MainMenu/DebugPanel/StartTimeInputBox
@onready var main_menu_container: BoxContainer = $MainMenu/HBoxContainer/VBoxContainer/TitleScreenContainer/MainMenuContainer
@onready var play_container: BoxContainer = $MainMenu/HBoxContainer/VBoxContainer/TitleScreenContainer/PlayContainer
@onready var debug_panel: Control = $MainMenu/DebugPanel
@onready var player1_team_color: OptionButton = $MainMenu/DebugPanel/P1TeamColor
@onready var player2_team_color: OptionButton = $MainMenu/DebugPanel/P2TeamColor
## Loading resources variables
@onready var loading_container: VBoxContainer = $MainMenu/HBoxContainer/VBoxContainer/LoadingResContainer
@onready var loading_bar: ProgressBar = $MainMenu/HBoxContainer/VBoxContainer/LoadingResContainer/ProgressBar
var ffa_4_scene: PackedScene
var start_process: bool = false
var loading_status
var await_quit: bool = false

func _ready():
	var status = ResourceLoader.load_threaded_request("res://Scenes/Levels/Terrain Test.tscn", "PackedScene", true)
	if status == 0:
		loading_container.visible = true
		start_process = true
	
func _process(delta):
	if start_process:
		var status_array: Array
		loading_status = ResourceLoader.load_threaded_get_status("res://Scenes/Levels/Terrain Test.tscn", status_array)
		loading_bar.value = status_array[0]
		if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
			if await_quit:
				get_tree().quit()
			else:
				ffa_4_scene = ResourceLoader.load_threaded_get("res://Scenes/Levels/Terrain Test.tscn")
				$MainMenu/HBoxContainer/VBoxContainer/TitleScreenContainer/PlayContainer/FFA4Button.disabled = false
				$MainMenu/HBoxContainer/VBoxContainer/TitleScreenContainer/MainMenuContainer/ExitButton.disabled = false
				loading_container.visible = false
				start_process = false

func _on_main_menu_play_button_pressed():
	play_container.visible = true
	main_menu_container.visible = false
	debug_panel.visible = true
	
func _on_return_button_pressed():
	play_container.visible = false
	main_menu_container.visible = true
	debug_panel.visible = false

func _on_play_button_pressed():
	Game.setup_players(2)
	Game.player_stats[0].gold = player1_gold_box.value
	Game.player_stats[1].gold = player2_gold_box.value
	for i in Game.player_stats.size():
		var _player_string = "player" + str(i+1) + "_team_color"
		var player_team_color = get(_player_string)
		var id = player_team_color.get_selected_id()
		Game.player_stats[i].color = Game.colors_array[id]
		Game.player_stats[i].building_dark_color = Game.building_colors_array[id * 2]
		Game.player_stats[i].building_light_color = Game.building_colors_array[(id * 2) + 1]
	Game.wave_time = wave_time_box.value
	Game.start_delay_time = start_time_box.value
	get_tree().change_scene_to_file("res://Scenes/Levels/2FFA.tscn")

func _on_exit_button_pressed():
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().quit()
	else:
		await_quit = true

func _on_player1_team_color_item_selected(index):
	if player2_team_color.selected == index:
		var ids: Array = [0,1,2,3]
		ids.erase(index)
		player2_team_color.selected = ids.pick_random()

func _on_player2_team_color_item_selected(index):
	if player1_team_color.selected == index:
		var ids: Array = [0,1,2,3]
		ids.erase(index)
		player1_team_color.selected = ids.pick_random()

func _on_debug_play_button_pressed():
	Game.setup_players(2)
	for i in Game.player_stats.size():
		Game.player_stats[i].gold = 100000
		var _player_string = "player" + str(i+1) + "_team_color"
		var player_team_color = get(_player_string)
		var id = player_team_color.get_selected_id()
		Game.player_stats[i].color = Game.colors_array[id]
		Game.player_stats[i].building_dark_color = Game.building_colors_array[id * 2]
		Game.player_stats[i].building_light_color = Game.building_colors_array[(id * 2) + 1]
	get_tree().change_scene_to_file("res://Scenes/Levels/Debug Play.tscn")

func _on_ffa_button_pressed():
	Game.setup_players(4)
	for i in Game.player_stats.size():
		Game.player_stats[i].color = Game.colors_array[i]
		Game.player_stats[i].building_dark_color = Game.building_colors_array[i * 2]
		Game.player_stats[i].building_light_color = Game.building_colors_array[(i * 2) + 1]
	Game.wave_time = wave_time_box.value
	Game.start_delay_time = start_time_box.value
	get_tree().change_scene_to_packed(ffa_4_scene)
