extends Control

@export var Icons: Dictionary
@onready var IconsHBoxContainer: HBoxContainer = $IconsHBoxContainer
@onready var SpecialAbilityLabel: RichTextLabel = $SpecialAbilityLabel

func add_icon(icon_type: String, size: int, small_card: bool, ability: MobSpecialAbility):
	#if IconsHBoxContainer.get_node_or_null(icon_type) != null:
	#	return
	var text_node = TextureRect.new()
	if small_card:
		text_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		text_node.mouse_entered.connect(self.on_text_node_mouse_entered.bind(text_node, ability))
		text_node.mouse_exited.connect(self.on_text_node_mouse_exited.bind(text_node))
		text_node.mouse_filter = Control.MOUSE_FILTER_PASS
	text_node.custom_minimum_size = Vector2(size, size)
	text_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT 
	text_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text_node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	text_node.texture = Icons.get(icon_type, Icons["Empty"])
	text_node.name = icon_type
	IconsHBoxContainer.add_child(text_node)

func on_text_node_mouse_entered(texture_rect: Control, ability: MobSpecialAbility):
	SpecialAbilityLabel.text = ""
	SpecialAbilityLabel.size = Vector2(140, 20)
	var first_position = "[center]" + ability.ability_type + " "
	var second_position = ""
	if ability.ability_type == "Summon":
		second_position = ability.ability_minion_to_spawn.card_name + " ("+ str(Game.mob_race.keys()[ability.ability_minion_to_spawn.race]).capitalize() +")"
	if ability.ability_amount != 0:
		if ability.ability_amount >= 1:
			match ability.ability_type:
				"Buff":
					second_position = "[color=53c349]"+str(ability.ability_amount)+"[/color] "
				"DOT", "Explode", "DMG", "True DMG", "Mark", "AOE":
					second_position = "[color=#fc8f78]"+str(ability.ability_amount) + " DMG[/color] "
				"Gold":
					second_position = "[color=gold]"+str(ability.ability_amount) +  "G[/color] "
				_:
					second_position = str(ability.ability_amount) +  " "
		else:
			second_position = str(ability.ability_amount * 100) + "% "
	if ability.ability_duration != 0.0:
		second_position += "for " + str(ability.ability_duration) + "s "
	var third_position = ""
	if ability.ability_dot_type != "":
		third_position = ability.ability_dot_type.capitalize() + " "
	elif ability.ability_buff_type != "":
		third_position = ability.ability_buff_type.capitalize() + " "
	var forth_position = ""
	if ability.ability_activation != Game.activation.BUFF && ability.ability_activation != Game.activation.FLAT:
		forth_position = str(Game.activation.keys()[ability.ability_activation]).capitalize() + " | "
	var fifth_position = ""
	if ability.ability_radius != 0.0:
		fifth_position += "Range: " + str(ability.ability_radius) + " | "
	var sixth_position = ""
	if ability.ability_chance != 0:
		sixth_position += str(ability.ability_chance) + "% Chance | "
	if ability.ability_cooldown != 0.0:
		sixth_position += str(ability.ability_cooldown) + "s CD | "
	var actual_string = first_position + second_position + third_position + "\n" + forth_position + fifth_position + sixth_position
	if actual_string.right(2).contains("|"):
		actual_string = actual_string.left(actual_string.length()-2)
	var seventh_position = ""
	if ability.ability_hits_to_activate != 0:
		seventh_position += str(ability.ability_hits_to_activate) + " hits to activate | "
	if ability.ability_threshold != 0.0:
		seventh_position += str(ability.ability_threshold) + "% Threshold | "
	if seventh_position.right(2).contains("|"):
		seventh_position = seventh_position.left(seventh_position.length() - 2)
	if seventh_position != "":
		actual_string += "\n" + seventh_position +  "[/center]"
	else:
		actual_string += "[/center]"
	SpecialAbilityLabel.text = actual_string
	SpecialAbilityLabel.position = texture_rect.global_position - Vector2(SpecialAbilityLabel.size.x/2, SpecialAbilityLabel.size.y/2) + \
	Vector2(texture_rect.size.x/2, -texture_rect.size.y/2)
	texture_rect.modulate = Color(0.8, 0.8, 0.8)
	SpecialAbilityLabel.visible = true

func on_text_node_mouse_exited(texture_rect: Control):
	SpecialAbilityLabel.size = Vector2(140, 20)
	SpecialAbilityLabel.visible = false
	SpecialAbilityLabel.text = ""
	texture_rect.modulate = Color(1, 1, 1)
