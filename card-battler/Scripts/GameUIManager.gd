extends Node3D
var format_gold_stats: String = "GOLD: [b][color=GOLD]%sG[/color][/b]"

var seconds: int = 0
var format_time: String = "%02d:%02d"
@onready var time_label: Label = $HUD/Labels/UpperPanel/TimePanel/TimeLabel
@onready var pause_panel: Panel = $HUD/Labels/UpperPanel/PausePanel
var is_game_paused: bool = false
@onready var settings_panel: Panel = $HUD/Labels/UpperPanel/PausePanel/SettingsPanel
@onready var pause_subpanel: Panel = $HUD/Labels/UpperPanel/PausePanel/PausePanel
@onready var controls_panel: Panel = $HUD/Labels/UpperPanel/PausePanel/ControlPanel
@onready var video_panel: Panel = $HUD/Labels/UpperPanel/PausePanel/VideoPanel
@onready var checkbox: CheckBox = $HUD/Labels/UpperPanel/PausePanel/ControlPanel/MouseMovementCheckBox
@onready var screen_optionbox: OptionButton = $HUD/Labels/UpperPanel/PausePanel/VideoPanel/ScreenModeButton
@onready var resolution_optionbox: OptionButton = $HUD/Labels/UpperPanel/PausePanel/VideoPanel/ResolutionButton
@onready var confirmation_dialog: ConfirmationDialog = $HUD/Labels/UpperPanel/ConfirmationDialog

var cursor_index: int = 0

var actual_gold_stats: String
@onready var gold_label: RichTextLabel = $HUD/Labels/UpperPanel/GoldLabel

func _ready():
	checkbox.button_pressed = Game.lolcammove
	screen_optionbox.select(get_window().mode)
	if !OS.is_debug_build():
		$HUD/InstaWinButton.visible = false
		$HUD/Labels/UpperPanel/Speedx1Button.visible = false
		$HUD/Labels/UpperPanel/Speedx2Button.visible = false
		$HUD/Labels/UpperPanel/Speedx4Button.visible = false
		
func _process(delta):
	if Input.is_action_just_released("pause"):
		is_game_paused = !is_game_paused
		pause_game()
	
	actual_gold_stats = format_gold_stats % [Game.player_stats[0].gold]
	gold_label.text = actual_gold_stats
	time_label.text = format_time % [seconds/60, seconds%60]

func pause_game():
	if is_game_paused:
		Engine.time_scale = 1
		Engine.physics_ticks_per_second = 60
		time_label.label_settings.font_color = Color.GRAY
		pause_panel.visible = true
		pause_subpanel.visible = true
	else:
		time_label.label_settings.font_color = Color.WHITE
		pause_panel.visible = false
		video_panel.visible = false
		settings_panel.visible = false
		controls_panel.visible = false
		
func _on_settings_button_pressed():
	settings_panel.visible = true
	pause_subpanel.visible = false

func _on_time_timer_timeout():
	seconds += 1

func _on_pause_menu_button_pressed():
	is_game_paused = !is_game_paused
	pause_game()

func _on_menu_button_pressed():
	confirmation_dialog.show()

func _on_return_button_pressed():
	is_game_paused = !is_game_paused
	pause_game()

func _on_insta_win_button_pressed():
	Game.winner = "PLAYER 1"
	get_tree().change_scene_to_file("res://Scenes/Levels/End Scene.tscn")

func _on_lol_like_cam_move_pressed():
	Game.lolcammove = !Game.lolcammove
	checkbox.button_pressed = Game.lolcammove
	if !Game.lolcammove:
		Input.action_release("mouse_move_up")
		Input.action_release("mouse_move_down")
		Input.action_release("mouse_move_left")
		Input.action_release("mouse_move_right")

func _on_controls_button_pressed():
	controls_panel.visible = true
	settings_panel.visible = false

func _on_return_settings_button_pressed():
	settings_panel.visible = false
	pause_subpanel.visible = true

func _on_close_button_pressed():
	controls_panel.visible = false
	video_panel.visible = false
	settings_panel.visible = true

func _on_video_button_pressed():
	video_panel.visible = true
	settings_panel.visible = false

func _on_screen_mode_button_item_selected(index):
	screen_optionbox.select(index)
	var id = screen_optionbox.get_selected_id()
	get_window().mode = id

func _on_speedx_1_button_pressed():
	Engine.time_scale = 1
	Engine.physics_ticks_per_second = 60

func _on_speedx_2_button_pressed():
	Engine.time_scale = 2
	Engine.physics_ticks_per_second = 90

func _on_speedx_4_button_pressed():
	Engine.time_scale = 4
	Engine.physics_ticks_per_second = 120

func _on_speedx_8_button_pressed():
	Engine.time_scale = 8
	Engine.physics_ticks_per_second = 150

func _on_confirmation_dialog_confirmed():
	get_tree().change_scene_to_file("res://Scenes/Levels/Main Menu.tscn")

func _on_cursor_button_pressed():
	var hotspot
	cursor_index += 1
	if cursor_index >= Game.cursors_array.size():
		cursor_index = 0
	match cursor_index:
		0:
			Game.current_cursor = "default"
			Input.set_custom_mouse_cursor(Game.cursors_array[cursor_index])
		1:
			Game.current_cursor = "circle_black"
			Input.set_custom_mouse_cursor(Game.cursors_array[cursor_index] ,0 , Vector2(32, 32))
		2:
			Game.current_cursor = "circle_green"
			Input.set_custom_mouse_cursor(Game.cursors_array[cursor_index] ,0 , Vector2(32, 32))
		3:
			Game.current_cursor = "circle_red"
			Input.set_custom_mouse_cursor(Game.cursors_array[cursor_index] ,0 , Vector2(32, 32))
