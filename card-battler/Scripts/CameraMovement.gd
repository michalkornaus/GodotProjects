extends Node3D

@export var movement_speed = 25
@export var camera_borders_x: Vector2
@export var camera_borders_z: Vector2
@onready var camera: Camera3D = $Camera3D
var mouse_position

@onready var cardex: CanvasLayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	var is_debug = get_node_or_null("/root/GameNode/HUD/CardEncyclopedia")
	if is_debug != null:
		cardex = is_debug
	else:
		cardex = get_node("/root/GameNode/HUD/GameUIManager/HUD/CardEncyclopedia")

func _process(delta):
	_move(delta)
	mouse_position = (get_viewport().get_mouse_position() / get_viewport().get_visible_rect().size)
	if Game.lolcammove == true && get_window().has_focus():
		if mouse_position.x < 0.005 and mouse_position.x > -0.02:
			Input.action_press("mouse_move_left")
		if mouse_position.x > 0.995 and mouse_position.x < 1.02:
			Input.action_press("mouse_move_right")
		if mouse_position.y > 0.995 and mouse_position.y < 1.02:
			Input.action_press("mouse_move_down")
		if mouse_position.y < 0.005 and mouse_position.y > -0.02:
			Input.action_press("mouse_move_up")
		
		if (mouse_position.y < 0.995 and mouse_position.y > 0.005) or (mouse_position.y > 1.02 or mouse_position.y < -0.02):
			Input.action_release("mouse_move_up")
			Input.action_release("mouse_move_down")
		if (mouse_position.x < 0.995 and mouse_position.x > 0.005) or (mouse_position.x > 1.02 or mouse_position.x < -0.02):
			Input.action_release("mouse_move_left")
			Input.action_release("mouse_move_right")

func _move(delta):
	var velocity = Vector3()
	# camera movement
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("mouse_move_up"):
		velocity -= Vector3.BACK
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("mouse_move_down"):
		velocity += Vector3.BACK
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("mouse_move_left"):
		velocity -= Vector3.RIGHT
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("mouse_move_right"):
		velocity += Vector3.RIGHT
	if Input.is_action_just_pressed("mwheelup"):
		if cardex == null || (cardex != null && !cardex.is_on_scrollable_menu):
			position.y -= 1	
	if Input.is_action_just_pressed("mwheeldown"):
		if cardex == null || (cardex != null && !cardex.is_on_scrollable_menu):
			position.y += 1
	# moving the camera
	translate(velocity.normalized() * delta * movement_speed)
	#clamping the position to world borders
	var x_pos = clamp(position.x, camera_borders_x.x, camera_borders_x.y)
	#y_pos value below 10.0 makes the camera clip with the assets
	var y_pos = clamp(position.y, 7.5, 30)
	var z_pos = clamp(position.z, camera_borders_z.x, camera_borders_z.y)
	var new_pos = Vector3(x_pos,y_pos,z_pos)
	position = new_pos
	
	#rotating the camera based on the normalized height
	var normalized_height = smoothstep(-40.0, 30, position.y)
	camera.rotation_degrees.x = -rad_to_deg(sin(normalized_height))
