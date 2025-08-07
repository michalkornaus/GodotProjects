@tool 
extends Node3D
class_name HexGrid3D

signal grid_changed

@export_group("Hexagon properties")
@export var hexagon_scene: PackedScene: 
	set(value):
		if hexagon_scene == value: return
		hexagon_scene = value
		_remove_ghost_hex()
		emit_signal("grid_changed")
@export var container_script: Script
@export var hexagon_radius: float = 1.0:
	set(value):
		if hexagon_radius == value: return
		hexagon_radius = value
		if hexagon_radius <= 0.01: hexagon_radius = 0.01 
		emit_signal("grid_changed")
@export var spacing: float = 0.1: 
	set(value):
		if spacing == value: return
		spacing = value
		emit_signal("grid_changed")

@export_group("Tiles placement")
@export var is_pointy_topped: bool = true: 
	set(value):
		if is_pointy_topped == value: return
		is_pointy_topped = value
		emit_signal("grid_changed")
@export var grid_width: int = 5: 
	set(value):
		if grid_width == value: return
		grid_width = value
		if grid_width < 1: grid_width = 1
		emit_signal("grid_changed")
@export var grid_height: int = 5: 
	set(value):
		if grid_height == value: return
		grid_height = value
		if grid_height < 1: grid_height = 1
		emit_signal("grid_changed")
@export var is_grid_center: bool = true: 
	set(value):
		if is_grid_center == value: return
		is_grid_center = value
		emit_signal("grid_changed")
		
@export_group("Force grid regeneration")
@export_tool_button("Regenerate grid") var redraw_grid_tool_button = _button_force_update

# --- Constants
const SQRT3: float = 1.73205081
const SQRT3_3: float = SQRT3 / 3.0 

# --- Edition options
enum EditMode { NONE, DRAW, DELETE }
var _current_edit_mode: EditMode =  EditMode.NONE
	
# --- Private variables
var _hexagon_container: Node3D = null 
var _is_generating: bool = false 
var _hexagons_dict: Dictionary = {}
var _hexagon_ghost: Node3D = null
var _last_cursor_coords: Vector2i = Vector2i(-10000, -10000)

func _enter_tree():
	if not grid_changed.is_connected(_on_grid_changed):
		grid_changed.connect(_on_grid_changed)
	_find_or_create_container()
	if Engine.is_editor_hint():
		call_deferred("_update_grid_if_needed")
			
func _exit_tree():
	_remove_ghost_hex()
	if grid_changed.is_connected(_on_grid_changed):
		grid_changed.disconnect(_on_grid_changed)
		
func change_edit_mode(index: int):
	match(index):
		0:
			_current_edit_mode = EditMode.NONE
			print("HexGrid3D: Edycja Interaktywna WYŁĄCZONA")
		1:
			_current_edit_mode = EditMode.DRAW
			print("HexGrid3D: Tryb Malowania WŁĄCZONY")
		2:
			_current_edit_mode = EditMode.DELETE
			print("HexGrid3D: Tryb Usuwania WŁĄCZONY")
	_remove_ghost_hex()
		
func _button_force_update():
	if Engine.is_editor_hint():
		print("HexGrid3D: Wymuszono regenerację siatki przez przycisk.")
		_update_grid()

func _on_grid_changed():
	if Engine.is_editor_hint() and is_inside_tree():
		call_deferred("_update_grid")

func _update_grid_if_needed():
	if _hexagon_container and _hexagon_container.get_child_count() == 0 and hexagon_scene:
		_update_grid()

func _find_or_create_container():
	if _hexagon_container and is_instance_valid(_hexagon_container):
		return
	_hexagon_container = get_node_or_null(^"HexagonTiles") as Node3D
	if not _hexagon_container: 
		_hexagon_container = Node3D.new()
		_hexagon_container.name = "HexagonTiles"
		_hexagon_container.set_script(container_script)
		_hexagon_container.add_to_group("Tiles")
		add_child(_hexagon_container)
		if Engine.is_editor_hint() and self.owner:
			_hexagon_container.owner = self.owner
	else:
		for child in _hexagon_container.get_children():
			var coords = child.name.lstrip("Tile")
			var q: int = int(coords.get_slice(",", 0))
			var r: int =  int(coords.get_slice(",", 1))
			if !_hexagons_dict.has(Vector2i(q,r)):
				_hexagons_dict[Vector2i(q,r)] = child
			else:
				printerr("HexGrid3D: Próbowano dodać istniejący wpis w słowniku!")

func _clean_hexagons():
	if not is_instance_valid(_hexagon_container):
		_find_or_create_container()
		if not is_instance_valid(_hexagon_container):
			printerr("HexGrid3D: Błąd krytyczny - nie można znaleźć ani utworzyć kontenera hexagonów.")
			return
	while _hexagon_container.get_child_count() > 0:
		var child = _hexagon_container.get_child(0)
		_hexagon_container.remove_child(child)
		child.queue_free() 
	_hexagons_dict.clear()
	_remove_ghost_hex()

func _update_grid():
	if _is_generating: return 
	_is_generating = true

	if not Engine.is_editor_hint() or not is_inside_tree():
		_is_generating = false
		return
		
	_find_or_create_container() 
	_clean_hexagons() 

	if not hexagon_scene:
		if Engine.is_editor_hint(): print("HexGrid3D: Scena hexagonu nie jest ustawiona. Siatka wyczyszczona.")
		_is_generating = false
		return
		
	if hexagon_radius <= 0:
		if Engine.is_editor_hint(): printerr("HexGrid3D: Promień hexagonu musi być dodatni. Siatka nie została wygenerowana.")
		_is_generating = false
		return

	call_deferred("_generate_grid")

func _generate_grid():
	if not is_instance_valid(_hexagon_container) or not hexagon_scene:
		_is_generating = false
		return
	var placement_radius : float = hexagon_radius + spacing / SQRT3
	
	var offset_x_central: float = 0.0
	var offset_z_central: float = 0.0

	if is_grid_center:
		var avg_q: float = (grid_width - 1.0) / 2.0
		var avg_r: float = (grid_height - 1.0) / 2.0
		var temp_pos_center = _calculate_local_hex_middle_pos(avg_q, avg_r, placement_radius)
		offset_x_central = -temp_pos_center.x
		offset_z_central = -temp_pos_center.z

	for q_idx in range(grid_width):
		for r_idx in range(grid_height):
			var hex_pos_local_no_offset = _calculate_local_hex_middle_pos(float(q_idx), float(r_idx), placement_radius)
			var final_pos = Vector3(hex_pos_local_no_offset.x + offset_x_central, 0, hex_pos_local_no_offset.z + offset_z_central)
			_create_hexagon(q_idx, r_idx, final_pos)
	
	_is_generating = false 
	if Engine.is_editor_hint():
		print("HexGrid3D: Generowanie siatki zakończone.")
		
func _create_ghost_hex():
	if not hexagon_scene: return
	if is_instance_valid(_hexagon_ghost): _hexagon_ghost.queue_free()
	
	_hexagon_ghost = hexagon_scene.instantiate() as Node3D
	if not _hexagon_ghost: return
	var ghost_mat = StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(0.5, 0.5, 1.0, 0.4) 
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	_hexagon_ghost.get_node("MeshInstance3D").material_override = ghost_mat

	add_child(_hexagon_ghost) 
	_hexagon_ghost.visible = false	
	
func _remove_ghost_hex():
	if is_instance_valid(_hexagon_ghost):
		_hexagon_ghost.queue_free()
		_hexagon_ghost = null
	_last_cursor_coords = Vector2i(-10000, -10000) # Resetuj ostatnią 

func _calculate_local_hex_middle_pos(q_float: float, r_float: float, placement_radius: float) -> Vector3:
	var pos_x: float
	var pos_z: float
	if is_pointy_topped:
		pos_x = placement_radius * (3.0/2.0 * q_float)
		pos_z = placement_radius * (SQRT3/2.0 * q_float + SQRT3 * r_float)
	else: 
		pos_x = placement_radius * (SQRT3 * q_float + SQRT3/2.0 * r_float)
		pos_z = placement_radius * (3.0/2.0 * r_float)
	return Vector3(pos_x, 0, pos_z)

func _world_to_grid(global_pos: Vector3) -> Vector2i:
	var _local_point_to_grid = to_local(global_pos)
	var placement_radius_calc = hexagon_radius + spacing / SQRT3
	if is_grid_center:
		var avg_q_grid: float = (grid_width - 1.0) / 2.0
		var avg_r_grid: float = (grid_height - 1.0) / 2.0
		var middle_offset = _calculate_local_hex_middle_pos(avg_q_grid, avg_r_grid, placement_radius_calc)
		_local_point_to_grid += middle_offset 
	var q_frac: float
	var r_frac: float
	if is_pointy_topped:
		q_frac = ( (2.0/3.0 * _local_point_to_grid.x)) / placement_radius_calc
		r_frac = ( (-1.0/3.0 * _local_point_to_grid.x) + (SQRT3_3 * _local_point_to_grid.z)) / placement_radius_calc
	else: 
		q_frac = ( (SQRT3_3 * _local_point_to_grid.x) - (1.0/3.0 * _local_point_to_grid.z)) / placement_radius_calc
		r_frac = ( (2.0/3.0 * _local_point_to_grid.z)) / placement_radius_calc
	
	return _round_to_grid(q_frac, r_frac)

func _round_to_grid(fq: float, fr: float) -> Vector2i:
	var fs: float = -fq - fr

	var q: int = int(round(fq))
	var r: int = int(round(fr))
	var s: int = int(round(fs))

	var q_diff: float = abs(q - fq)
	var r_diff: float = abs(r - fr)
	var s_diff: float = abs(s - fs)
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	else:
		s = -q - r 
	return Vector2i(q, r)

func _calculate_final_hex_position(q: int, r: int) -> Vector3:
	var placement_radius_calc = hexagon_radius + spacing / SQRT3
	var pos_local_no_offset = _calculate_local_hex_middle_pos(float(q), float(r), placement_radius_calc)
	if is_grid_center:
		var avg_q_grid: float = (grid_width - 1.0) / 2.0
		var avg_r_grid: float = (grid_height - 1.0) / 2.0
		var middle_offset = _calculate_local_hex_middle_pos(avg_q_grid, avg_r_grid, placement_radius_calc)
		return pos_local_no_offset - middle_offset
	else:
		return pos_local_no_offset

func public_handle_editor_spatial_input(camera: Camera3D, event: InputEvent, index: int) -> bool:
	if index != _current_edit_mode:
		change_edit_mode(index)
	if _current_edit_mode == EditMode.NONE or not hexagon_scene:
		_remove_ghost_hex() 
		return false 
	if not is_instance_valid(_hexagon_container):
		_find_or_create_container()
		if not is_instance_valid(_hexagon_container): return false
		
	var is_event_handled = false
	var mouse_pos = event.get_position() if event is InputEventMouse else Vector2() # Pozycja myszy na ekranie
	
	var radius_start = camera.project_ray_origin(mouse_pos)
	var radius_dir = camera.project_ray_normal(mouse_pos)
	
	var grid_plane = Plane(global_transform.basis.y.normalized(), global_transform.origin.y)
	
	var global_intersection_point = grid_plane.intersects_ray(radius_start, radius_dir * camera.far)

	if global_intersection_point != null: 
		var grid_dest_coords: Vector2i = _world_to_grid(global_intersection_point)
		if event is InputEventMouseMotion:
			if not is_instance_valid(_hexagon_ghost): _create_ghost_hex()
			if is_instance_valid(_hexagon_ghost):
				if grid_dest_coords != _last_cursor_coords: 
					var ghost_local_pos = _calculate_final_hex_position(grid_dest_coords.x, grid_dest_coords.y)
					_hexagon_ghost.position = ghost_local_pos
					_hexagon_ghost.visible = true
					_last_cursor_coords = grid_dest_coords
					var does_hex_exist = _hexagons_dict.has(grid_dest_coords)
					var ghost_mat = _hexagon_ghost.get_node("MeshInstance3D").material_override as StandardMaterial3D
					if ghost_mat:
						var dest_color = Color.WHITE
						if _current_edit_mode == EditMode.DRAW:
							dest_color = Color.GREEN if not does_hex_exist else Color.ORANGE # Zielony - można dodać, Pomarańczowy - już jest
						elif _current_edit_mode == EditMode.DELETE:
							dest_color = Color.RED if does_hex_exist else Color.LIGHT_BLUE # Czerwony - można usunąć, Niebieski - puste
						ghost_mat.albedo_color = Color(dest_color.r, dest_color.g, dest_color.b, 0.4) # Zachowaj przezroczystość
				is_event_handled = true
		# Obsługa kliknięcia myszą
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if _current_edit_mode == EditMode.DRAW:
				_try_add_hexagon(grid_dest_coords.x, grid_dest_coords.y)
				is_event_handled = true
			elif _current_edit_mode == EditMode.DELETE:
				_try_remove_hexagon(grid_dest_coords.x, grid_dest_coords.y)
				is_event_handled = true
	else: 
		if is_instance_valid(_hexagon_ghost):
			_hexagon_ghost.visible = false
		_last_cursor_coords = Vector2i(-10000, -10000)
	if is_event_handled:
		get_viewport().set_input_as_handled()
	return is_event_handled 
	
func _create_hexagon(q: int, r: int, local_pos: Vector3):
	if not hexagon_scene or not is_instance_valid(_hexagon_container): return null
	var hexagon_instantiation: Node3D = hexagon_scene.instantiate() as Node3D
	if not hexagon_instantiation: return null
	hexagon_instantiation.name = "Tile"+str(q)+","+str(r)
	_hexagon_container.add_child(hexagon_instantiation)
	if Engine.is_editor_hint() and self.owner and not hexagon_instantiation.owner:
		hexagon_instantiation.owner = self.owner 
	hexagon_instantiation.position = local_pos
	_hexagons_dict[Vector2i(q,r)] = hexagon_instantiation
	return hexagon_instantiation

func _try_add_hexagon(q: int, r: int):
	if _hexagons_dict.has(Vector2i(q,r)):
		print("HexGrid3D: Hexagon już istnieje w (" + str(q) + "," + str(r) + ")")
		return
	var local_pos = _calculate_final_hex_position(q,r)
	var added_hex = _create_hexagon(q,r, local_pos)
	if is_instance_valid(_hexagon_ghost) and _hexagon_ghost.visible and _last_cursor_coords == Vector2i(q,r):
		var ghost_mat = _hexagon_ghost.get_node("MeshInstance3D").material_override as StandardMaterial3D
		if ghost_mat: ghost_mat.albedo_color = Color(Color.ORANGE, 0.4) 

func _try_remove_hexagon(q: int, r: int):
	if not _hexagons_dict.has(Vector2i(q,r)):
		print("HexGrid3D: Brak hexagonu do usunięcia w (" + str(q) + "," + str(r) + ")")
		return
	var crds = Vector2i(q,r)
	var hex_instant = _hexagons_dict[crds]
	if is_instance_valid(hex_instant):
		if is_instance_valid(_hexagon_container):
			_hexagon_container.remove_child(hex_instant)
		hex_instant.queue_free()
	_hexagons_dict.erase(crds)
	print("HexGrid3D: Usunięto hexagon z (" + str(q) + "," + str(r) + ")")
	if is_instance_valid(_hexagon_ghost) and _hexagon_ghost.visible and _last_cursor_coords == crds:
		var ghost_mat = _hexagon_ghost.get_node("MeshInstance3D").material_override as StandardMaterial3D
		if ghost_mat: ghost_mat.albedo_color = Color(Color.GREEN if _current_edit_mode == EditMode.DRAW else Color.LIGHT_BLUE, 0.4)
