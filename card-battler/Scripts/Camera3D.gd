extends Camera3D

@onready var upgrades_ui: CanvasLayer = get_node("/root/GameNode/HUD/GameUIManager/HUD/UpgradesUI")
@onready var cards_ui: Node = get_node("/root/GameNode/HUD/GameUIManager/HUD/CardsUI")
var mouse: Vector2
var double_click_flag = false
@export var toggle_mouse_timer: Timer
var hover_selector: MeshInstance3D

func _unhandled_input(event):
	if event is InputEventMouse:
		mouse = event.position
		if Game.current_cursor != "default":
			var worldspace = get_world_3d().direct_space_state
			var start = project_ray_origin(mouse)
			var end = project_position(mouse, 1000)
			var result = worldspace.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
			if result:
				var collider = result.collider
				if collider.is_in_group("mob"):
					if hover_selector:
						if is_instance_valid(hover_selector):
							if hover_selector == collider.get_node("HoverOverSelector"):
								return
							else:
								hover_selector.visible = false
					hover_selector = collider.get_node("HoverOverSelector")
					hover_selector.visible = true
				else:
					if hover_selector:
						if is_instance_valid(hover_selector):
							hover_selector.visible = false
							self.hover_selector = null
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			double_click_flag = false
			if event.double_click:
				double_click_flag = true
				select_node(2)
				return
		else: 
			if event.is_released():
				toggle_mouse_timer.start()
				return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if OS.is_debug_build():
			if event.is_released():
				select_node(1)

func select_node(action: int):
	var worldspace = get_world_3d().direct_space_state
	var start = project_ray_origin(mouse)
	var end = project_position(mouse, 1000)
	var result = worldspace.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
	if !result:
		return
	var collider = result.collider
	if !(collider.is_in_group("building") || collider.is_in_group("mob")):
		return
	match action:
		0: #LMB single
			if collider.is_in_group("player1"): 
				if collider.is_in_group("TopTower") || collider.is_in_group("MidTower") || collider.is_in_group("BotTower") || collider.is_in_group("Nexus"):
					cards_ui.lane_value = 3
					cards_ui.change_lane()
				elif collider.is_in_group("TopBarrack"):
					cards_ui.lane_value = 0
					cards_ui.change_lane()
				elif collider.is_in_group("MidBarrack"):
					cards_ui.lane_value = 1
					cards_ui.change_lane()
				elif collider.is_in_group("BotBarrack"):
					cards_ui.lane_value = 2
					cards_ui.change_lane()
			else:
				if collider.is_in_group("building"):
					print("Clicked on enemy building!")
		1: #RMB single
			collider.queue_free()
		2: #LMB double click
			if collider.is_in_group("building"):
				collider.stats_label.visible = !collider.stats_label.visible
			elif collider.is_in_group("mob"):
				print("Print info on mob!")

func _on_toggle_mouse_timer_timeout():
	if !double_click_flag:
		select_node(0)
