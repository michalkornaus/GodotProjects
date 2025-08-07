extends Node3D
class_name Tiles
var all_tiles: Array[Tile]
func _ready():
	for tile_child in get_children():
			all_tiles.append(tile_child)
			
func check_if_board_full():
	var is_full: bool = true
	for tile: Tile in all_tiles:
		if tile.locked:
			continue
		if tile.stack == null || !is_instance_valid(tile.stack) || tile.stack.is_queued_for_deletion() || tile.is_stack_changing:
			is_full = false
			break
	return is_full
