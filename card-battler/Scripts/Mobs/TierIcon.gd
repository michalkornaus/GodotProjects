extends Control

@export var TierIcons: Dictionary
@export var ClassIcons: Dictionary
@export var BuildingIcons: Dictionary

func set_up_icon(tier, sub_class, size, is_minion: bool):
	var prev_icon = get_node_or_null(str(tier-1))
	if prev_icon != null:
		prev_icon.queue_free()
	var tier_node = TextureRect.new()
	if tier == -1: 
		tier_node.custom_minimum_size = Vector2(size - 8, size - 8)
		tier_node.position += Vector2(4, 4)
	else: tier_node.custom_minimum_size = Vector2(size, size)
	tier_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tier_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	tier_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var index_tier = tier if is_minion else tier - 1
	tier_node.texture = TierIcons.get(index_tier, TierIcons[-1])
	tier_node.name = str(tier)
	tier_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var type_node = TextureRect.new()
	if tier == -1: 
		type_node.custom_minimum_size = Vector2(size - 8, size - 8)
	else: 
		type_node.custom_minimum_size = Vector2(size, size)
	type_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	type_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	type_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	type_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_minion:
		type_node.texture = ClassIcons.get(sub_class, ClassIcons[0])
		type_node.position += Vector2(0, 2)
	else:
		type_node.texture = BuildingIcons.get(sub_class, BuildingIcons[0])
	tier_node.add_child(type_node)
	add_child(tier_node)
