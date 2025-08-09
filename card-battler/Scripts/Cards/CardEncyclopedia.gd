extends CanvasLayer
@onready var grid_container: GridContainer = $HBoxContainer/ScrollContainer/VBoxContainer/GridContainer
@export var card_zone: PackedScene
@export var card_scene: PackedScene
enum zone_type {DECK, SHOP, SELL}
var cards_array: Array
@onready var option_button_type: OptionButton = $HBoxContainer/ControlPanel/VBoxContainer/OptionButtonType
@onready var option_button_order: OptionButton = $HBoxContainer/ControlPanel/VBoxContainer/OptionButtonOrder
@onready var menu_button_race: MenuButton = $HBoxContainer/ControlPanel/VBoxContainer/MenuButtonRace
@onready var menu_button_tier: MenuButton = $HBoxContainer/ControlPanel/VBoxContainer/MenuButtonTier
@onready var menu_button_class: MenuButton = $HBoxContainer/ControlPanel/VBoxContainer/MenuButtonClass

var is_on_scrollable_menu: bool = false
var is_button_specials_toggled: bool = false
var is_changed_array: bool = false

var sorter: Sorter
class Sorter:
	enum types {Race, Tier, Health, Damage, Class}
	var sort_type: types
	enum orders {Ascending, Descending}
	var sort_order: orders 
	var get_string: String = "race"
	func custom_sort(a_card, b_card):
		#Default value - race for sorting cards, and tier for sorting further
		var inner_sort_string: String
		match sort_type:
			types.Race:
				get_string = "race"
				inner_sort_string = "tier"
			types.Tier:
				get_string = "tier"
				inner_sort_string = "race"
			types.Health:
				get_string = "health"
				inner_sort_string = "tier"
			types.Damage:
				get_string = "attack_damage"
				inner_sort_string = "tier"
			types.Class:
				get_string = "sub_type"
				inner_sort_string = "tier"
		var a_value = 0
		var b_value = 0
		if a_card != null:
			a_value = a_card.get(get_string)
		if b_card != null:
			b_value = b_card.get(get_string)
			
		var a_order_value: int = a_value if sort_order == orders.Ascending else b_value
		var b_order_value: int = b_value if sort_order == orders.Ascending else a_value
		if a_order_value < b_order_value:
			return true
		elif a_value == b_value:
			if a_card != null:
				a_value = a_card.get(inner_sort_string)
			if b_card != null:
				b_value = b_card.get(inner_sort_string)
			if a_value < b_value:
				return true
		return false

func _ready():
	set_up_filters()
	set_up_sorter()
	set_up_array()
	cards_array.sort_custom(sorter.custom_sort)
	create_grid()
	
func filter_grid():
	set_up_array()
	cards_array.sort_custom(sorter.custom_sort)
	create_grid()
	
func _process(delta):
	if Input.is_action_just_pressed("cardex"):
		visible = !visible
		if visible == false:
			is_on_scrollable_menu = false
		
func set_up_filters():
	menu_button_race.get_popup().id_pressed.connect(on_race_popup_id_pressed)
	menu_button_race.get_popup().popup_hide.connect(on_popup_hide)
	menu_button_race.get_popup().hide_on_checkable_item_selection = false
	
	menu_button_tier.get_popup().id_pressed.connect(on_tier_popup_id_pressed)
	menu_button_tier.get_popup().popup_hide.connect(on_popup_hide)
	menu_button_tier.get_popup().hide_on_checkable_item_selection = false
	
	menu_button_class.get_popup().id_pressed.connect(on_class_popup_id_pressed)
	menu_button_class.get_popup().popup_hide.connect(on_popup_hide)
	menu_button_class.get_popup().hide_on_checkable_item_selection = false

func on_popup_hide():
	if is_changed_array:
		filter_grid()
		is_changed_array = false

func on_race_popup_id_pressed(id: int):
	var item_status = menu_button_race.get_popup().is_item_checked(id)
	menu_button_race.get_popup().set_item_checked(id, !item_status)
	is_changed_array = true

func on_tier_popup_id_pressed(id: int):
	var item_status = menu_button_tier.get_popup().is_item_checked(id)
	menu_button_tier.get_popup().set_item_checked(id, !item_status)
	is_changed_array = true

func on_class_popup_id_pressed(id: int):
	var item_status = menu_button_class.get_popup().is_item_checked(id)
	menu_button_class.get_popup().set_item_checked(id, !item_status)
	is_changed_array = true

func set_up_sorter():
	sorter = Sorter.new()
	sorter.sort_type = sorter.types.Race
	sorter.sort_order = sorter.orders.Ascending

func set_up_array():
	cards_array.clear()
	if OS.has_feature("editor"):
		if Game.test_cards_array.size() > 0:
			for card in Game.test_cards_array:
				cards_array.append(card)
	for i in 9:
		if menu_button_race.get_popup().is_item_checked(i):
			var array
			match i:
				0: array = Game.human_kingdom_cards_array
				1: array = Game.outlaws_cards_array
				2: array = Game.mountain_clan_cards_array
				3: array = Game.forest_orcs_cards_array
				4: array = Game.blood_brotherhood_cards_array
				5: array = Game.undead_pact_cards_array
				6: array = Game.moon_elves_cards_array
				7: array = Game.sun_elves_cards_array
				8: array = Game.beast_cards_array
			for card in array:
				if (is_button_specials_toggled && !card.special_ability_stats.is_empty()) || !is_button_specials_toggled:
					if menu_button_tier.get_popup().is_item_checked(card.tier) && menu_button_class.get_popup().is_item_checked(card.sub_type):
						cards_array.append(card)

func create_header(empty_spaces: int, text: String):
	var empty_node: Panel = Panel.new()
	empty_node.self_modulate = Color(0,0,0,0)
	empty_node.custom_minimum_size = Vector2(140, 35)
	
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 25)
	label.text = text
	label.anchors_preset = Control.PRESET_FULL_RECT
	
	var header_node = empty_node.duplicate()
	header_node.add_child(label)
	
	if empty_spaces > 0:
		for i in empty_spaces:
			grid_container.add_child(empty_node.duplicate())
			
	grid_container.add_child(header_node)
	grid_container.add_child(empty_node.duplicate())
	grid_container.add_child(empty_node.duplicate())
	grid_container.add_child(empty_node.duplicate())
	
func create_text(card):
	var text: String
	match sorter.sort_type:
		sorter.types.Race:
			var race = card.get(sorter.get_string)
			var _race = str(Game.mob_race.keys()[race])
			var _race_words = _race.split("_")
			if _race_words.size() > 1:
				_race = _race_words[0].capitalize() + " " + _race_words[1].capitalize()
			else:
				_race = _race.capitalize()
			text = _race + " cards: "
		sorter.types.Tier:
			text = str(Game.card_tier.keys()[card.get(sorter.get_string)]).capitalize() + " Tier cards:"
		sorter.types.Health:
			text = "Cards with " + str(card.get(sorter.get_string)) + " Health: "
		sorter.types.Damage:
			text = "Cards with " + str(card.get(sorter.get_string)) + " AD: "
		sorter.types.Class:
			text = str(Game.mob_sub_class.keys()[card.get(sorter.get_string)]).capitalize()  + " Class cards:"
	return text
	
func create_grid():
	for child in grid_container.get_children():
		child.queue_free()
	var index: int = 1
	var prev_card: Resource = null
	for card in cards_array:
		if index == 1:
			var text = create_text(card)
			create_header(0, text)
			index += 3
		elif prev_card != null && card.get(sorter.get_string) != prev_card.get(sorter.get_string):
			var spaces = index % 4
			if spaces > 0:
				spaces = 4 - spaces
			var text = create_text(card)
			create_header(spaces, text)
			index += 4 + spaces
		fill_up_card(card)
		prev_card = card
		index += 1

func fill_up_card(resource_card):
	var node: Control = card_zone.instantiate()
	node.zone = zone_type.SHOP
	grid_container.add_child(node)
	
	var card: Control = card_scene.instantiate()
	card.add_to_group("codex_card")
	var resource = resource_card
	card.card_resource = resource
	node.card = card
	var position = node.global_position + node.pivot_offset
	node.add_child(card)
	card.global_position = position
	card.set_rest_node(node)
	card.name = "Card " + resource.card_name 

func _on_view_cards_button_pressed():
	visible = !visible

func _on_option_button_type_item_selected(index):
	sorter.sort_type = index
	cards_array.sort_custom(sorter.custom_sort)
	create_grid()

func _on_option_button_order_item_selected(index):
	sorter.sort_order = index
	cards_array.sort_custom(sorter.custom_sort)
	create_grid()

func _on_button_pressed():
	visible = false
	is_on_scrollable_menu = false

func _on_scroll_container_gui_input(event):
	is_on_scrollable_menu = true

func _on_scroll_container_mouse_exited():
	is_on_scrollable_menu = false

func _on_codex_button_pressed():
	visible = !visible
	if visible == false:
		is_on_scrollable_menu = false

func _on_check_button_specials_toggled(toggled_on):
	is_button_specials_toggled = toggled_on
	filter_grid()
