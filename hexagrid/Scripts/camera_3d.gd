extends Camera3D
class_name CameraManager
@export var stack_to_spawn: PackedScene
@export var UIManagerRef: UIManager
var camera_rotator: Node3D
var drag_velocity: float
var is_dragging: bool = false
var hover_collider

func _ready():
	camera_rotator = get_parent_node_3d()

func _process(delta):
	look_at(Vector3(0, 0, 0))
	rotation_degrees.x += remap(DisplayServer.screen_get_size().y, 640, 2340, 5, 15)
	if Input.is_key_pressed(KEY_A):
		camera_rotator.rotation_degrees.y -= 100 * delta
	elif Input.is_key_pressed(KEY_D):
		camera_rotator.rotation_degrees.y += 100 * delta
	## Phone Drag calculation
	if drag_velocity != 0:
		camera_rotator.rotation_degrees.y += -drag_velocity * 12 * delta
		if drag_velocity > 0.01:
			drag_velocity -= 7 * drag_velocity * delta
		elif  drag_velocity < -0.01:
			drag_velocity += 7 * -drag_velocity * delta
		else:
			drag_velocity = 0
			
func check_position_from_drag(_mouse_pos):
	var result_b: bool = false
	var worldspace = get_world_3d().direct_space_state
	var start = project_ray_origin(_mouse_pos)
	var end = project_position(_mouse_pos, 1000)
	var result = worldspace.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
	if result:
		var collider = result.collider
		if collider.is_in_group("Tile"):
			if collider.stack != null || collider.locked == true:
				return
			if UIManagerRef.current_selected_array.is_empty():
				return
			var new_stack : Stack = stack_to_spawn.instantiate()
			var stack_array = UIManagerRef.current_selected_array
			stack_array.reverse()
			for value in stack_array:
				new_stack.stack_list.append(value)
			UIManagerRef.current_selected_array = []
			UIManagerRef.clean_button(UIManagerRef.current_index)
			collider.stack = new_stack
			new_stack.update_mesh()
			collider.add_child(new_stack)
			collider.get_node("MeshInstance3D").material_override = collider.normal_tile_mat
			new_stack.global_position = collider.global_position + Vector3(0, 0.02, 0)
			result_b = true
	return result_b

func check_hover_from_drag(_mouse_pos):
	var worldspace = get_world_3d().direct_space_state
	var start = project_ray_origin(_mouse_pos)
	var end = project_position(_mouse_pos, 1000)
	var result = worldspace.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
	if result:
		var collider = result.collider
		if collider.is_in_group("Tile"):
			if collider.stack != null || collider.locked == true:
				return
			for tile: Tile in collider.tiles_parent.all_tiles:
				if !tile.locked:
					if tile.get_node("MeshInstance3D").get_surface_override_material(0) != collider.normal_tile_mat:
						tile.get_node("MeshInstance3D").material_override = collider.normal_tile_mat
			hover_collider = collider
			collider.get_node("MeshInstance3D").material_override = collider.hover_tile_mat
		else:
			if hover_collider != null:
				hover_collider.get_node("MeshInstance3D").material_override = hover_collider.normal_tile_mat

func _unhandled_input(event):
	if event is InputEventScreenDrag:
		if event.screen_relative.x > 2:
			is_dragging = true
			drag_velocity = minf(event.screen_relative.x, 10)
		elif event.screen_relative.x < -2:
			is_dragging = true
			drag_velocity = maxf(event.screen_relative.x, -10)
	if event is InputEventScreenTouch:
		if !event.is_pressed():
			is_dragging = false
