extends Control

@export var Icons: Dictionary
@onready var buffHBoxContainer: HBoxContainer = $BuffHBoxContainer
@onready var debuffHBoxContainer: HBoxContainer = $DebuffHBoxContainer

func add_buff(buff_type: String):
	if buffHBoxContainer.get_node_or_null(buff_type) != null:
		return
	var text_node = TextureRect.new()
	text_node.custom_minimum_size = Vector2(48,48)
	text_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	text_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text_node.texture = Icons[buff_type]
	text_node.name = buff_type
	buffHBoxContainer.add_child(text_node)

func remove_buff(buff_type: String):
	if buffHBoxContainer.get_node_or_null(buff_type) == null:
		return
	var text_node = buffHBoxContainer.get_node(buff_type)
	buffHBoxContainer.remove_child(text_node)
	text_node.queue_free()

func add_debuff(debuff_type: String):
	if debuffHBoxContainer.get_node_or_null(debuff_type) != null:
		return
	var text_node = TextureRect.new()
	text_node.custom_minimum_size = Vector2(48,48)
	text_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	text_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text_node.texture = Icons[debuff_type]
	text_node.name = debuff_type
	debuffHBoxContainer.add_child(text_node)
	
func remove_debuff(debuff_type: String):
	if debuffHBoxContainer.get_node_or_null(debuff_type) == null:
		return
	var text_node = debuffHBoxContainer.get_node(debuff_type)
	debuffHBoxContainer.remove_child(text_node)
	text_node.queue_free()
