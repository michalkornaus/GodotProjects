extends Resource

@export var card_name: String
@export var image: Texture2D

@export var race: Game.mob_race
@export var tier: Game.card_tier

@export var description: String
@export var cost: int
@export var health: int
@export var attack_damage: int
@export var armor: int
@export var attack_speed: float
@export var attack_range: float
@export_range(0,1, 0.01) var armor_penetration: float

@export var type: Game.mob_class
@export var sub_type: Game.mob_sub_class

@export var model: PackedScene

@export var special_ability_stats: Array[MobSpecialAbility] 

func _init(p_name = "", p_image=null, p_race = 0,p_tier = 0, p_desc = "", p_cost = 0, p_health = 0, p_pen = 0, \
p_attack_dmg = 0, p_armor = 0, p_speed = 0.0, p_range = 0.0, p_type = 0, p_sub_type = 0, p_model = null, p_ability: Array[MobSpecialAbility] = []):
	card_name = p_name
	image = p_image
	race = p_race
	tier = p_tier
	description = p_desc
	cost = p_cost
	health = p_health
	attack_damage = p_attack_dmg
	armor = p_armor
	attack_speed = p_speed
	attack_range = p_race
	type = p_type
	sub_type = p_sub_type
	model = p_model
	special_ability_stats = p_ability
	armor_penetration = p_pen
