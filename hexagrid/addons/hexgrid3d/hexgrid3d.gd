@tool
extends EditorPlugin

const HexGridNodeScript = preload("res://addons/hexgrid3d/hex_grid_node.gd")
const HexGridNodeIcon = null 

#var _editor_interface: EditorInterface
var _selection: EditorSelection

# GUI variables
var _button: Button
var _current_id: int

func _enter_tree():
	add_custom_type("HexGrid3D", "Node3D", HexGridNodeScript, HexGridNodeIcon)
	_selection = EditorInterface.get_selection()
	if _selection:
		pass 
	else:
		printerr("HexGrid3D Plugin: Nie udało się pobrać EditorInterface Selection.")
	_add_button()

func _add_button():
	_button = OptionButton.new()
	_button.add_item("NONE", 0)
	_button.add_item("DRAW", 1)
	_button.add_item("DELETE", 2)
	_button.item_selected.connect(_change_current_item)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _button)

func _change_current_item(index: int):
	_current_id = index
	if not _selection:
		return false
	var selected_nodes = _selection.get_selected_nodes()
	if selected_nodes.is_empty():
		return false
	var target_node: HexGrid3D = null
	for node in selected_nodes:
		if node is HexGrid3D: 
			target_node = node
			break
	if target_node:
		if target_node.has_method("change_edit_mode"):
			target_node.call("change_edit_mode", _current_id)

func _exit_tree():
	remove_custom_type("HexGrid3D")
	_selection = null
	_button.queue_free()

func _handles(object: Object) -> bool:
	if object is HexGrid3D:
		return true
	return false

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent):
	if not _selection:
		return false
	var selected_nodes = _selection.get_selected_nodes()
	if selected_nodes.is_empty():
		return false
	var target_node: HexGrid3D = null
	for node in selected_nodes:
		if node is HexGrid3D: 
			target_node = node
			break
	if target_node:
		if target_node.has_method("public_handle_editor_spatial_input"):
			return target_node.call("public_handle_editor_spatial_input", camera, event, _current_id)
	return false # Zdarzenie nie zostało obsłużone przez naszą wtyczkę
