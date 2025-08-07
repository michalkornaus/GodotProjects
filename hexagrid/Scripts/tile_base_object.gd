extends StaticBody3D
class_name Tile
var adjacent_tiles: Array[Tile]
signal changed_stack(new_value)
var stack: Stack:
	get:
		return stack
	set(value):
		stack = value
		changed_stack.emit(value)
var is_stack_changing: bool = false
var tiles_parent: Node3D

@export var normal_tile_mat: StandardMaterial3D
@export var locked_tile_mat: StandardMaterial3D
@export var hover_tile_mat: StandardMaterial3D
@export var locked: bool = false
@export var unlock_value: int 

func _ready():
	changed_stack.connect(on_stack_changed)
	GlobalNode.score_changed.connect(on_changed_score)
	if locked:
		$MeshInstance3D.material_override = locked_tile_mat
		$Sprite3D.visible = true
		$Label3D.visible = true
		$Label3D.text = " " + str(unlock_value)
	call_deferred("setup_adjacent")
	
func setup_adjacent():
	tiles_parent = get_parent_node_3d()
	if tiles_parent.get("all_tiles") != null:
		adjacent_tiles = tiles_parent.all_tiles.filter(found_adjacent)
	
func unlock():
	locked = false
	$Label3D.text = ""
	$Sprite3D.visible = false
	$MeshInstance3D.material_override = normal_tile_mat
	
func on_changed_score(value: int):
	if locked:
		if value >= unlock_value:
			unlock()
	
func on_stack_changed(value: Stack):
	await get_tree().create_timer(0.1).timeout
	# browse adjacent tiles and check if there are same colors on top
	var top_piece = value.stack_list[value.stack_list.size() - 1]
	var adjacent_tiles_array: Array[Tile]
	for tile in adjacent_tiles:
		if tile.stack != null && is_instance_valid(tile.stack) && !tile.stack.is_queued_for_deletion():
			var top_piece_adj = tile.stack.stack_list[tile.stack.stack_list.size() - 1]
			if top_piece == top_piece_adj:
				adjacent_tiles_array.append(tile)
	if adjacent_tiles_array.size() > 0:
		for tile in adjacent_tiles_array:
			if tile.is_stack_changing || is_stack_changing:
				continue
			if adjacent_tiles_array.size() >= 2:
				call("connect_stacks", tile, self)
			else:
				## connects stack -> stack to take from; stack to give to, tile to take from
				## tile with less should transfer to tile with more count
				var top_piece_count = value.check_top_count()
				var top_piece_adj_count = tile.stack.check_top_count()
				if top_piece_count >= top_piece_adj_count:
					if top_piece_adj_count == tile.stack.stack_list.size():
						if top_piece_count == value.stack_list.size():
							call("connect_stacks", tile, self)
						else:
							call("connect_stacks", self, tile)
					else:
						call("connect_stacks", tile, self)
				else:
					if top_piece_count == value.stack_list.size():
						if top_piece_adj_count == tile.stack.stack_list.size():
							call("connect_stacks", self, tile)
						else:
							call("connect_stacks", tile, self)
					else:
						call("connect_stacks", self, tile)
	call_deferred("check_endgame")
			
func check_endgame():
	if tiles_parent.check_if_board_full():
		await get_tree().create_timer(1.5).timeout
		if tiles_parent.check_if_board_full():
			print("End the game - No more space!")
			GlobalNode.call_deferred("reset_current_level")
			
func check_stack():
	if !is_instance_valid(stack) || stack.is_queued_for_deletion():
		return
	if (stack.check_top_count() >= 10):
		is_stack_changing = true
		var reverse_stack = stack.stack_list.duplicate()
		reverse_stack.reverse()
		var value_to_remove = reverse_stack[0]
		for value in reverse_stack:
			if value == value_to_remove:
				await get_tree().create_timer(0.07).timeout
				stack.stack_list.pop_back()
				stack.clean_mesh()
				stack.update_mesh()
				## Add stack.check_top_count to global score
				GlobalNode.score += 1
			else:
				break
		await get_tree().create_timer(0.1).timeout
		is_stack_changing = false
		if is_instance_valid(stack) && !stack.is_queued_for_deletion() && !is_stack_changing:
			call_deferred("on_stack_changed", stack)
	
func connect_stacks(tileFrom: Tile, tileTo: Tile):
	var stackFrom: Stack = tileFrom.stack
	var stackTo: Stack = tileTo.stack
	if !is_instance_valid(stackFrom) || !is_instance_valid(stackTo) || tileFrom.is_stack_changing || tileTo.is_stack_changing:
		return
	tileTo.is_stack_changing = true
	tileFrom.is_stack_changing = true
	var reverse_stack1 = stackFrom.stack_list.duplicate()
	reverse_stack1.reverse()
	var value_to_move = reverse_stack1[0]
	for value in reverse_stack1:
		if value == value_to_move:
			await get_tree().create_timer(0.14).timeout
			stackFrom.stack_list.pop_back()
			stackTo.stack_list.push_back(value)
			# Updating mesh
			stackFrom.clean_mesh()
			stackTo.clean_mesh()
			stackFrom.update_mesh()
			stackTo.update_mesh()
		else:
			break
	await get_tree().create_timer(0.2).timeout
	tileTo.is_stack_changing = false
	tileFrom.is_stack_changing = false
	await get_tree().create_timer(0.1).timeout
	# check if after connectings stacks there are more stacks to connect to adjacent tile and current tile
	if is_instance_valid(stackFrom) && !stackFrom.is_queued_for_deletion() && !tileFrom.is_stack_changing:
		tileFrom.call_deferred("on_stack_changed", stackFrom)
	if is_instance_valid(stackTo) && !stackTo.is_queued_for_deletion() && !tileTo.is_stack_changing:
		tileTo.call_deferred("on_stack_changed", stackTo)
	## check if after connecting tiles - and no more tiles are connecting if there are more than 10 same color in the row -> clean them and add up points
	await get_tree().create_timer(0.75).timeout
	if !tileTo.is_stack_changing:
		tileTo.check_stack()

func found_adjacent(tile: Tile):
	if tile == self:
		return
	if tile.position.distance_to(self.position) <= 0.25:
		return tile
