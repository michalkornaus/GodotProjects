@tool
class_name MobSpecialAbility extends Resource

# Constant variables needed for the specials to work
var ability_hits = 0
var ability_on_cooldown = false
var ability_cooldown_timer: Timer # To be set in the mob_behavior.gd script

@export var ability_activation: Game.activation:
	set(value):
		ability_activation = value
		ability_type = ""
		notify_property_list_changed()
		
var ability_type: String:
	set(value):
		ability_type = value
		ability_amount = 0
		ability_cooldown = 0
		ability_duration = 0
		ability_radius = 0
		ability_buff_type = ""
		ability_dot_type = ""
		notify_property_list_changed()
		
const buff_types = "Attack Damage,Attack Speed,Armor,Barrier,Heal,Movement Speed"
var ability_buff_type: String:
	set(value):
		ability_buff_type = value
		notify_property_list_changed()
		
const dot_types = "Fire,Acid,Bleed,Curse"
var ability_dot_type: String = "":
	set(value):
		ability_dot_type = value
		notify_property_list_changed()
## If Value < 1 -> percentage, Value > 1 -> int value
var ability_amount: float:
	set(value):
		ability_amount = value
var ability_radius: float:
	set(value):
		ability_radius = value
		notify_property_list_changed()
## Used for damage over time abilities as well as stuns and other timed abilities (in seconds)
var ability_duration: float:
	set(value):
		ability_duration = value
		notify_property_list_changed()
## Used for abilities that have a cooldown (in seconds)
var ability_cooldown: float:
	set(value):
		ability_cooldown = value
		notify_property_list_changed() 
## int number = 1-100% chance to activate, if left at 0 it will always activate
var ability_chance: int:
	set(value):
		ability_chance = value
		notify_property_list_changed() 
var ability_minion_to_spawn: Resource:
	set(value):
		ability_minion_to_spawn = value
		notify_property_list_changed()
var ability_hits_to_activate: int:
	set(value):
		ability_hits_to_activate = value
		notify_property_list_changed()
## Used for abilities that have a certain HP or Range threshold
var ability_threshold: float:
	set(value):
		ability_threshold = value
		notify_property_list_changed()
		
const on_hit_types = "DOT,Disarm,Ice,Ricochet,Mark,DMG,True DMG,Buff,Stun,AOE,ARP"
const on_kill_types = "Buff,Explode,Summon,Gold"
const on_buff_types = "Buff"
const on_aura_types = "DMG,Disarm,Ice,Buff"
const on_death_types = "Summon,Explode,Buff,DOT"
const on_flat_types = "Tower Tank,Siedge,Big Hunter,Anti-Range,Range+,ARP"

func _get_property_list():
	var properties = []
	if !Engine.is_editor_hint():
		return properties
	var property_usage = PROPERTY_USAGE_NO_EDITOR
	var property_string: String = ""
	match ability_activation:
		Game.activation.ON_HIT: 
			property_string = on_hit_types
		Game.activation.ON_KILL: 
			property_string = on_kill_types
		Game.activation.BUFF: 
			property_string = on_buff_types
		Game.activation.FLAT: 
			property_string = on_flat_types
		Game.activation.AURA: 
			property_string = on_aura_types
		Game.activation.ON_DEATH: 
			property_string = on_death_types
	properties.append({
		"name": "ability_type",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": property_string
	})
	var enum_string_array: Array = property_string.split(",")
	var properties_to_add: Array = []
	match ability_type:
		"DOT":
			properties.append({
				"name": "ability_dot_type",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": dot_types
			})
			if ability_activation == Game.activation.ON_DEATH:
				properties_to_add = ["ability_amount","ability_radius"]
			else:
				properties_to_add = ["ability_amount"]
		"Buff":
			properties.append({
				"name": "ability_buff_type",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": buff_types
			})
			if ability_activation == Game.activation.AURA:
				properties_to_add = ["ability_amount","ability_radius","ability_cooldown"]
			elif ability_activation == Game.activation.ON_DEATH:
				properties_to_add = ["ability_amount","ability_radius"]
			else:
				properties_to_add = ["ability_amount","ability_duration","ability_cooldown"]
		"Disarm":
			if ability_activation == Game.activation.AURA:
				properties_to_add = ["ability_amount", "ability_radius", "ability_duration", "ability_cooldown"]
			else:
				properties_to_add = ["ability_amount", "ability_duration", "ability_cooldown"]
		"Ice":
			if ability_activation == Game.activation.AURA:
				properties_to_add = ["ability_amount", "ability_radius", "ability_duration","ability_cooldown"]
			else:
				properties_to_add = ["ability_amount", "ability_duration"]
		"Mark", "ARP", "Gold", "Tower Tank", "Siedge":
			properties_to_add = ["ability_amount"]
		"Anti-Range", "Big Hunter", "Range+":
			properties_to_add = ["ability_amount", "ability_threshold"]
		"DMG", "True DMG":
			if ability_activation == Game.activation.AURA:
				properties_to_add = ["ability_amount","ability_radius","ability_cooldown"]
			else:
				properties_to_add = ["ability_amount", "ability_hits_to_activate"]
		"Stun":
			properties_to_add = ["ability_chance", "ability_duration", "ability_cooldown"]
		"AOE":
			properties_to_add = ["ability_amount", "ability_radius"]
		"Explode":
			properties_to_add = ["ability_amount", "ability_chance", "ability_radius"]
		"Summon":
			if ability_activation == Game.activation.ON_KILL:
				properties_to_add = ["ability_minion_to_spawn", "ability_chance", "ability_cooldown"]
			elif ability_activation == Game.activation.ON_DEATH:
				properties_to_add = ["ability_minion_to_spawn"]
	for _property in properties_to_add:
		var type = typeof(get(_property))
		var hint = 0
		var hint_string = ""
		if _property == "ability_minion_to_spawn":
			type = TYPE_OBJECT
			hint = PROPERTY_HINT_RESOURCE_TYPE
			hint_string = "Resource"
		if _property == "ability_amount":
			match ability_type:
				"Ice", "Disarm", "ARP", "Tower Tank", "Siedge", "Anti-Range", "Big Hunter", "Range+":
					hint = PROPERTY_HINT_RANGE
					hint_string = "0,1,0.01"
		properties.append({
			"name": str(_property),
			"type": type,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": hint,
			"hint_string": hint_string
		})
	return properties
