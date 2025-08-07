extends Control
class_name UIManager
@export var camera_manager: CameraManager
@onready var button1: Control = $CanvasLayer/Panel/HBoxContainer/Button1
@onready var button2: Control = $CanvasLayer/Panel/HBoxContainer/Button2
@onready var button3: Control = $CanvasLayer/Panel/HBoxContainer/Button3
@onready var progress_bar: ProgressBar = $CanvasLayer/ScorePanel/ProgressBar
@onready var score_label: RichTextLabel = $CanvasLayer/ScorePanel/ProgressBar/VBoxContainer/ScoreLabel
@export var blue_img: CompressedTexture2D
@export var red_img: CompressedTexture2D
@export var green_img: CompressedTexture2D
@export var yellow_img: CompressedTexture2D
@export var white_img: CompressedTexture2D
@export var black_img: CompressedTexture2D
@export var purple_img: CompressedTexture2D
var button1_array: Array
var button2_array: Array
var button3_array: Array
var current_selected_array: Array
var current_index: int
var resizing: bool = false

func _ready():
	GlobalNode.score_changed.connect(on_changed_score)
	randomize_stacks()
	
func randomize_stacks():
	randomize_stack(button1_array)
	randomize_stack(button2_array)
	randomize_stack(button3_array)
	call_deferred("update_buttons")
	
func update_button(idx: int):
	var _button = get("button" + str(idx))
	var _button_array: Array = get("button" + str(idx) + "_array")
	for child in _button.get_children():
		child.queue_free()
	var image_control: Control = Control.new()
	image_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	image_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.add_child(image_control)
	var index = 0
	var reverse_array: Array = _button_array.duplicate()
	reverse_array.reverse()
	for value in reverse_array:
		var color_string
		var new_sprite = Sprite2D.new()
		match value:
			0: new_sprite.texture = red_img
			1: new_sprite.texture = green_img
			2: new_sprite.texture = blue_img
			3: new_sprite.texture = yellow_img
			4: new_sprite.texture = white_img
			5: new_sprite.texture = black_img
			6: new_sprite.texture = purple_img
		var sx = (_button.size.x / new_sprite.texture.get_size().x) * 0.6
		var sy = (_button.size.y / new_sprite.texture.get_size().y) * 0.6
		var s = min(0.45, sx*sy)
		s = max(s, 0.35)
		var stack_space = remap(s, 0.211, 0.75, 10, 40)
		new_sprite.scale = Vector2(s, s)
		new_sprite.position.x = _button.size.x / 2
		new_sprite.position.y = _button.size.y - (_button.size.y / 4 + (stack_space * index))
		image_control.add_child(new_sprite)
		index += 1

func update_buttons():
	update_button(1)
	update_button(2)
	update_button(3)

func randomize_stack(button_array: Array):
	button_array.clear()
	## Correct values -> 4, 8
	var count = randi_range(4, 8)
	## Correct values -> 2, count
	var first_section_count = randi_range(2, count)
	var second_section_count = count - first_section_count
	var first_section_value = randi_range(0, 3 + GlobalNode.difficulty_level)
	for i in first_section_count:
		button_array.append(first_section_value)
	if second_section_count > 0:
		var second_section_value = randi_range(0, 3 + GlobalNode.difficulty_level)
		if second_section_value == first_section_value:
			if first_section_value >= 3:
				second_section_value = 0
			else:
				second_section_value = first_section_value + 1
		for i in second_section_count:
			button_array.append(second_section_value)
			
func on_changed_score(value: int):
	score_label.text = "[center]" + str(value) + " / " + str(GlobalNode.level_score) + "[/center]"
	progress_bar.value = value
	if GlobalNode.difficulty_level < 3 && value >= (GlobalNode.difficulty_level + 1) * 100:
		GlobalNode.difficulty_level += 1

func clean_button(index: int):
	set("button" + str(index) +"_array", [])
	var _button = get("button" + str(index))
	for child in _button.get_children():
		child.queue_free()
	if button1_array.is_empty() && button2_array.is_empty() && button3_array.is_empty():
		randomize_stacks()

func _on_reset_button_pressed():
	randomize_stacks()

func _on_panel_resized():
	if resizing:
		return
	resizing = true
	await get_tree().create_timer(0.15).timeout
	resizing = false
	call_deferred("update_buttons")
	
func _on_button_gui_input(event):
	if button1_array.is_empty() || camera_manager.is_dragging:
		return
	if event is InputEventScreenDrag:
		button1.get_child(0).scale = Vector2(0.75, 0.75)
		button1.get_child(0).modulate = Color(1, 1, 1, 0.80)
		button1.get_child(0).position = event.position - Vector2(button1.size.x/2 * 0.75, button1.size.y/2 * 0.75) - Vector2(0, button1.size.y/3.5)
		camera_manager.check_hover_from_drag(get_global_mouse_position())
	if event is InputEventScreenTouch:
		if event.is_pressed():			
			current_selected_array = button1_array
			current_index = 1
		elif !event.is_pressed():
			if !camera_manager.check_position_from_drag(get_global_mouse_position()):
				button1.get_child(0).scale = Vector2(1, 1)
				button1.get_child(0).modulate = Color(1, 1, 1, 1)
				button1.get_child(0).position = Vector2(0, 0)
				current_selected_array = []

func _on_button_2_gui_input(event):
	if button2_array.is_empty() || camera_manager.is_dragging:
		return
	if event is InputEventScreenDrag:
		button2.get_child(0).scale = Vector2(0.75, 0.75)
		button2.get_child(0).modulate = Color(1, 1, 1, 0.80)
		button2.get_child(0).position = event.position - Vector2(button2.size.x/2 * 0.75, button2.size.y/2 * 0.75) - Vector2(0, button1.size.y/3.5)
		camera_manager.check_hover_from_drag(get_global_mouse_position())
	if event is InputEventScreenTouch:
		if event.is_pressed():			
			current_selected_array = button2_array
			current_index = 2
		elif !event.is_pressed():
			if !camera_manager.check_position_from_drag(get_global_mouse_position()):
				button2.get_child(0).scale = Vector2(1, 1)
				button2.get_child(0).modulate = Color(1, 1, 1, 1)
				button2.get_child(0).position = Vector2(0, 0)
				current_selected_array = []

func _on_button_3_gui_input(event):
	if button3_array.is_empty() || camera_manager.is_dragging:
		return
	if event is InputEventScreenDrag:
		button3.get_child(0).scale = Vector2(0.75, 0.75)
		button3.get_child(0).modulate = Color(1, 1, 1, 0.80)
		button3.get_child(0).position = event.position - Vector2(button3.size.x/2 * 0.75, button3.size.y/2 * 0.75) - Vector2(0, button1.size.y/3.5)
		camera_manager.check_hover_from_drag(get_global_mouse_position())
	if event is InputEventScreenTouch:
		if event.is_pressed():		
			current_selected_array = button3_array
			current_index = 3
		elif !event.is_pressed():
			if !camera_manager.check_position_from_drag(get_global_mouse_position()):
				button3.get_child(0).scale = Vector2(1, 1)
				button3.get_child(0).modulate = Color(1, 1, 1, 1)
				button3.get_child(0).position = Vector2(0, 0)
				current_selected_array = []
