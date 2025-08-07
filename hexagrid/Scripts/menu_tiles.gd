extends Tiles
@export var stack_to_spawn: PackedScene

func _ready():
	super()
	call_deferred("place_stack")
	call_deferred("place_stack")
	call_deferred("place_random_stack")

func place_random_stack():
	place_stack()
	await get_tree().create_timer(5).timeout
	place_random_stack()

func place_stack():
	var random_tile = all_tiles.pick_random()
	if random_tile.stack != null:
		if !check_if_board_full():
			place_stack()
		return
	var stack_array: Array
	var count = randi_range(4, 8)
	var first_section_count = randi_range(2, count)
	var second_section_count = count - first_section_count
	var first_section_value = randi_range(0, 3)
	for i in first_section_count:
		stack_array.append(first_section_value)
	if second_section_count > 0:
		var second_section_value = randi_range(0, 3)
		if second_section_value == first_section_value:
			if first_section_value >= 3:
				second_section_value = 0
			else:
				second_section_value = first_section_value + 1
		for i in second_section_count:
			stack_array.append(second_section_value)
	var new_stack : Stack = stack_to_spawn.instantiate()
	stack_array.reverse()
	for value in stack_array:
		new_stack.stack_list.append(value)
	random_tile.stack = new_stack
	new_stack.update_mesh()
	random_tile.add_child(new_stack)
	new_stack.global_position = random_tile.global_position + Vector3(0, 0.02, 0)
