extends Control

@export var name_label_big: Label
@export var image_rect_big: TextureRect
@export var description_label: Label
@export var name_label_back: Label
@export var cost_label_big: Label
@export var special_ability_label: Label
@export var health_label_big: Label
@export var armor_label_big: Label
@export var attack_damage_label_big: Label

@export var name_label_small: Label
@export var image_rect_small: TextureRect
@export var cost_label_small: Label
@export var health_label_small: Label
@export var attack_damage_label_small: Label
@export var armor_label_small: Label
@export var cost_texture_small: TextureRect

@export var popup_label: Label
@export var cost_popup_label: Label
@export var cost_popup_timer: Timer

@export var delay_timer: Timer

@export var tier_icon_big: Control
@export var tier_icon_small: Control

var card_name: String
var image: Texture2D
var description: String

var health: int
var attack_damage: int
var armor: int
var attack_speed: float
var attack_range: float
var armor_penetration: float
var cost: int

var race: Game.mob_race
var type: Game.mob_class
var sub_type: Game.mob_sub_class
var tier: Game.card_tier
var model: PackedScene

@onready var card_icons_small: Control = $CardPanelSmall/CardIcons
@onready var card_icons_big: Control = $CardPanelBig/FaceSide/CardIcons
@export var card_resource: Resource	
var special_ability_stats: Array[MobSpecialAbility]

var is_showing_reverse: bool = false
var is_hovering_above: bool = false

#INFO drag & drop variables
var selected: bool = false
var rest_nodes = []
var rest_node: Control
var current_rest_node: int = -1
var cardsUI: Node

var lane: int = 0 # 0 - top, 1 - middle, 2 - bot

func _ready():
	cardsUI = get_tree().get_first_node_in_group("CardsUI")
	if card_resource != null:
		set_variables()
		update_card()
	
func set_rest_node(node: Control):
	rest_node = node

func set_variables():
	card_name = card_resource.card_name
	image = card_resource.image
	description = card_resource.description
	health = card_resource.health
	attack_damage = card_resource.attack_damage
	armor = card_resource.armor
	attack_speed = card_resource.attack_speed
	attack_range = card_resource.attack_range
	armor_penetration = card_resource.armor_penetration
	cost = card_resource.cost
	race = card_resource.race
	type = card_resource.type
	sub_type = card_resource.sub_type
	tier = card_resource.tier
	model = card_resource.model
	if !card_resource.special_ability_stats.is_empty():
		special_ability_stats = card_resource.special_ability_stats
	else:
		special_ability_stats = []

func update_card():
	if card_resource:
		$CardPanelSmall.visible = true
		$CardPanelBig.visible = false
		$CardPanelBig/FaceSide.visible = true
		$CardPanelBig/ReverseSide.visible = false
		name_label_big.text = card_name
		name_label_back.text = card_name
		name_label_small.text = card_name
		var ls = LabelSettings.new()
		ls.font_size = 20
		while name_label_small.get_theme_font("font").get_string_size(card_name, name_label_small.horizontal_alignment, -1, ls.font_size).x > name_label_small.size.x:
			ls.font_size -= 1
		#modify label color depending on card's tier
		var tier_value: int = tier
		match tier_value:
			0: #COMMON tier
				ls.font_color = Game.common_color
			1: #RARE tier
				ls.font_color = Game.rare_color
			2: #EPIC tier
				ls.font_color = Game.epic_color
			3: #LEGENDARY tier
				ls.font_color = Game.legendary_color
			_: #Default case
				ls.font_color = Game.common_color
		tier_icon_small.set_up_icon(tier_value, sub_type, 40 , true)
		tier_icon_big.set_up_icon(tier_value, sub_type, 48, true)
		ls.outline_size = 3
		ls.outline_color = Color.BLACK
		ls.shadow_color = Color(0,0,0, 0.675)
		ls.shadow_size = 1
		var fv = FontVariation.new()
		fv.set_variation_embolden(0.45)
		name_label_big.label_settings = ls
		name_label_big.add_theme_font_override("font", fv)
		name_label_small.label_settings = ls
		name_label_small.add_theme_font_override("font", fv)
		name_label_back.label_settings = ls
		name_label_back.add_theme_font_override("font", fv)
		#modify card's background color depending on card's race
		var color
		#0 - HUMAN_KINGDOM, 1 - OUTLAWS, 2 - MOUNTAIN_CLAN, 3 - FOREST_ORCS, 4 - BLOOD_BROTHERHOOD
		#5 - UNDEAD_PACT, 6 - MOON_ELVES, 7 - SUN_ELVES, 8 - BEAST
		var race_value: int = race
		match race_value:
			0: #HUMAN_KINGDOM
				color = Game.human_kingdom_color
			1: #OUTLAWS
				color = Game.outlaws_color
			2: #MOUNTAIN_CLAN
				color = Game.mountain_clan_color
			3: #FOREST_ORCS
				color = Game.forest_orcs_color
			4: #BLOOD_BROTHERHOOD
				color = Game.blood_brotherhood_color
			5: #UNDEAD_PACT
				color = Game.undead_pact_color
			6: #MOON_ELVES
				color = Game.moon_elves_color
			7: #SUN_ELVES
				color = Game.sun_elves_color
			8: #BEAST
				color = Game.beast_color
			_: #Default case - HUMAN_KINGDOM
				color = Game.human_kingdom_color
		var stylePanelBig: StyleBoxFlat = $CardPanelBig/Panel.get_theme_stylebox("panel")
		var stylePanelSmall: StyleBoxFlat = $CardPanelSmall/Panel.get_theme_stylebox("panel")
		stylePanelBig.border_color = color
		stylePanelSmall.border_color = color
		image_rect_big.texture = image
		image_rect_small.texture = image
		cost_label_big.text = str(cost)
		cost_label_small.text = str(cost)
		for ability in special_ability_stats:
			match ability.ability_type:
				"Buff":
					match ability.ability_buff_type:
						"Attack Damage":
							card_icons_small.add_icon("AD", 32, true, ability)
							card_icons_big.add_icon("AD", 36, false, ability)
						"Attack Speed":
							card_icons_small.add_icon("AS", 32, true, ability)
							card_icons_big.add_icon("AS", 36, false, ability)
						"Armor":
							card_icons_small.add_icon("Armor", 32, true, ability)
							card_icons_big.add_icon("Armor", 36, false, ability)
						"Barrier":
							card_icons_small.add_icon("Barrier", 32, true, ability)
							card_icons_big.add_icon("Barrier", 36, false, ability)
						"Movement Speed":
							card_icons_small.add_icon("MS", 32, true, ability)
							card_icons_big.add_icon("MS", 36, false, ability)
						"Heal":
							card_icons_small.add_icon("Regen", 32, true, ability)
							card_icons_big.add_icon("Regen", 36, false, ability)
				"DOT":
					card_icons_small.add_icon(ability.ability_dot_type, 32, true, ability)
					card_icons_big.add_icon(ability.ability_dot_type, 36, false, ability)
				_:
					card_icons_small.add_icon(ability.ability_type, 32, true, ability)
					card_icons_big.add_icon(ability.ability_type, 36, false, ability)
		card_icons_small.IconsHBoxContainer.alignment = BoxContainer.ALIGNMENT_BEGIN
		health_label_big.text = str(health)
		health_label_small.text = str(health)
		attack_damage_label_big.text = str(snapped(attack_damage * attack_speed, 0.1)) #DPS
		attack_damage_label_small.text = str(snapped(attack_damage * attack_speed, 0.1)) #DPS
		armor_label_small.text = str(armor)
		armor_label_big.text = str(armor)
		var _race = str(Game.mob_race.keys()[race])
		var _race_words = _race.split("_")
		if _race_words.size() > 1:
			_race = _race_words[0].capitalize() + " " + _race_words[1].capitalize()
		else:
			_race = _race.capitalize()
		var attack_length: float
		if model != null:
			var _anim: AnimationPlayer = model.get_node("AnimationPlayer")
			attack_length = _anim.get_animation("Attack").length
		else:
			attack_length = 1.1667
		attack_length = snapped(attack_length, 0.01)
		var hit_per_sec: float = (1 / attack_length) * attack_speed
		#print(attack_length , " ", attack_speed , " ", hit_per_sec)
		description_label.text = str(Game.card_tier.keys()[tier]) + " Unit" + "\n" + str(health) + " Health" + "\n" + \
		str(attack_damage) + " Attack Damage" + "\n" +str(snapped(hit_per_sec, 0.1)) + "/1s Attack Speed\n"+  str(armor) + " Armor Points" + "\n" + \
		str(attack_range) + " Attack Range" + "\n" + str(Game.mob_class.keys()[type]).capitalize() + \
		" " + str(Game.mob_sub_class.keys()[sub_type]).capitalize() + "\n" + _race
		
func _physics_process(delta):
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)
	else:
		if rest_node != null:
			var position = rest_node.global_position + rest_node.pivot_offset
			if is_hovering_above == true:
				position = position - Vector2(0, 15)
			global_position = lerp(global_position, position, 10 * delta)

func _on_mouse_click_control_gui_input(event):
	if !is_hovering_above:
		return
	var is_card_moved: bool = false
	var shop_visible: bool = false
	if event is InputEventMouse:
		if is_card_moved:
			return
		var sell_zone = get_tree().get_first_node_in_group("sell_zone")
		var distance = global_position.distance_to(sell_zone.global_position + sell_zone.pivot_offset)
		if distance < 70:
			if !is_in_group("shop_card"):
				popup_label.visible = true
				popup_label.text = "+" + str(cost / 2) + "G"
			else:
				popup_label.visible = true
				popup_label.text = "Cannot sell shop card!"
		else:
			popup_label.visible = false
			popup_label.text = ""
				
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not selected and event.pressed:
			# INFO change top level of the card to always be on top for duration of drag
			var position = global_position
			top_level = true
			global_position = position
			$MouseClickControl.mouse_default_cursor_shape = Control.CURSOR_DRAG
			selected = true
			delay_timer.stop()
		# Stop dragging if the button is released.
		if selected and not event.pressed:
			popup_label.visible = false
			popup_label.text = ""
			var shortest_dist = 70
			var index = 0
			var _lane_value = cardsUI.lane_value
			# INFO card is in shop and it does not have rest nodes array set yet - not in any deck
			if rest_nodes.is_empty():
				if OS.is_debug_build() && is_in_group("codex_card"):
					var _rest_nodes
					if str(get_tree().current_scene.get_path()) == "/root/GameNode":
						_rest_nodes = get_tree().get_nodes_in_group("middle_zone")
						for node in _rest_nodes:
							node.pivot_offset = Vector2(56, 57.6)
					else:
						match _lane_value:
							0: 
								_rest_nodes = cardsUI.top_lane_nodes
							1: 
								_rest_nodes = cardsUI.middle_lane_nodes
							2: 
								_rest_nodes = cardsUI.bottom_lane_nodes
					## INFO Moving Codex card into the deck
					for node: Control in _rest_nodes:
						if node.is_in_group("locked"):
							continue
						if node.card == null:
							var distance = global_position.distance_to(node.global_position + node.pivot_offset)
							if distance < shortest_dist:
								var card: Control = cardsUI.card_scene.instantiate()
								card.add_to_group("deck_card")
								var _resource = card_resource
								card.card_resource = _resource
								node.card = card
								var position = node.global_position + node.pivot_offset
								node.add_child(card)
								card.lane = 1
								card.rest_nodes = _rest_nodes
								card.cost_texture_small.visible = false
								card.current_rest_node = index
								card.global_position = position
								card.set_rest_node(node)
								card.name = "Card" + str(index) + " " + _resource.card_name 
								break
						index += 1	
					selected = false
					$MouseClickControl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					#reset the top level and position to not obstruct other cards
					var position = global_position
					top_level = false
					global_position = position
					return
				else:
					if !is_in_group("shop_card"):
						selected = false
						return
				var _rest_nodes
				match _lane_value:
					0: 
						_rest_nodes = cardsUI.top_lane_nodes
					1: 
						_rest_nodes = cardsUI.middle_lane_nodes
					2: 
						_rest_nodes = cardsUI.bottom_lane_nodes
				# INFO moving shop card into the deck - charging gold
				for node: Control in _rest_nodes:
					if node.is_in_group("locked"):
						continue
					if node.card == null:
						var distance = global_position.distance_to(node.global_position + node.pivot_offset)
						if distance < shortest_dist:
							if Game.player_stats[0].gold  >= cost:
								Game.player_stats[0].gold  -= cost
								cost_popup_label.visible = true
								cost_popup_label.text = "-" + str(cost) + "G"
								cost_popup_timer.start()
								add_to_group("deck_card")
								remove_from_group("shop_card")
								cost_texture_small.visible = false
								lane = _lane_value
								rest_node = node
								current_rest_node = index
								#changing the parent of card to the node in the deck
								get_parent().remove_child(self)
								node.add_child(self)
								node.card = self
								#assigning current lane card zones
								rest_nodes = _rest_nodes
								break
					index += 1	
			else:	
				for node: Control in rest_nodes:
					var distance = global_position.distance_to(node.global_position + node.pivot_offset)
					if distance < shortest_dist:
						if node.card:
							if !node.card.is_in_group("shop_card") && !is_in_group("shop_card"):
								rest_nodes[current_rest_node].remove_child(self)
								var temp_card: Control = node.card
								node.remove_child(temp_card)
								temp_card.rest_node = rest_node
								temp_card.current_rest_node = current_rest_node
								rest_nodes[current_rest_node].card = temp_card
								rest_node = node
								rest_nodes[current_rest_node].add_child(temp_card)
								current_rest_node = index
								node.add_child(self)
								node.card = self
								is_card_moved = true
								break
						else:
							if !node.is_in_group("locked"):
								if current_rest_node >= 0: 
									rest_nodes[current_rest_node].card = null
								rest_node = node
								rest_nodes[current_rest_node].remove_child(self)
								current_rest_node = index
								node.add_child(self)
								node.card = self
								is_card_moved = true
								break
					index += 1
				if !is_card_moved:
					var sell_zone = get_tree().get_first_node_in_group("sell_zone")
					var distance = global_position.distance_to(sell_zone.global_position + sell_zone.pivot_offset)
					if distance < shortest_dist:
						#INFO sell the card, as the rest node is the sell zone
						Game.player_stats[0].gold  += (cost / 2)
						rest_nodes[current_rest_node].card = null
						queue_free()
			selected = false
			$MouseClickControl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			#reset the top level and position to not obstruct other cards
			var position = global_position
			top_level = false
			global_position = position
			
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_RIGHT && is_hovering_above:
			delay_timer.stop()
			if is_showing_reverse:
				is_showing_reverse = false
				$CardPanelBig/FaceSide.visible = true
				$CardPanelBig/ReverseSide.visible = false
			else:
				is_showing_reverse = true
				$CardPanelBig/FaceSide.visible = false
				$CardPanelBig/ReverseSide.visible = true

func _on_mouse_click_control_mouse_entered():
	if not $MouseClickControl.get_rect().has_point(get_local_mouse_position()):
		return
	get_tree().call_group("hovered_card", "exit_card")
	add_to_group("hovered_card")
	is_hovering_above = true
	$CardPanelBig.visible = true
	$CardPanelSmall.visible = false
	$MouseClickControl.size = Vector2(150, 205)
	$MouseClickControl.position = Vector2(-75, -100)

func exit_card():
	remove_from_group("hovered_card")
	is_hovering_above = false
	$CardPanelBig.visible = false
	$CardPanelSmall.visible = true
	is_showing_reverse = false
	$MouseClickControl.size = Vector2(140, 160)
	$MouseClickControl.position = Vector2(-70, -72)
	$CardPanelBig/FaceSide.visible = true
	$CardPanelBig/ReverseSide.visible = false

func _on_mouse_click_control_mouse_exited():
	if $MouseClickControl.get_rect().has_point(get_local_mouse_position()):
		return		
	exit_card()

func _on_cost_timer_timeout():
	cost_popup_label.visible = false
	cost_popup_label.text = ""
