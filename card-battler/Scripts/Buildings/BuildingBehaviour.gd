extends Node

enum type {TOWER, BARRACK, NEXUS}
enum lane {TOP, MIDDLE, BOTTOM}
@export var building_type: type
@export var building_damage: int = 20
@export var building_armor: int = 5
@export var building_health: int = 500
@export var building_penetration: float = 0.25
var health_value: int:
	get:
		return health_value
	set(value):
		emit_signal("health_changed", health_value, value)
		health_value = value

signal health_changed(old_value, new_value)

@export var building_tier: int = 0 #TOWER Tiers: 0-3, BARRACK Tiers: 0-4, NEXUS Tiers: 0-4
@export var building_range: float = 5.0
@export var building_lane: lane
var building_speed: float = 0.5
var teamName: String
var teamIndex: int
#Upgradeable AOE variables
var aoe_attack: bool = false
var aoe_dmg_percentage: float = 0.0
#Passive gold for Nexus variables
var passive_gold_enabled: bool = false
var passive_gold_amount: float = 0
var passive_gold_time: float = 0
var gold_started: bool = false

@onready var nexus_model: PackedScene = preload("res://Scenes/Assets/Buildings/Models/Nexus.tscn")
@onready var barrack_model: PackedScene = preload("res://Scenes/Assets/Buildings/Models/Barrack.tscn")
@onready var tower_model: PackedScene = preload("res://Scenes/Assets/Buildings/Models/Tower.tscn")

@onready var attack_cooldown: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar/SubViewport/Panel/ProgressBar
@onready var detection_shape: CollisionShape3D = $DetectionArea/DetectionShape
@onready var stats_label: Label3D = $StatsLabel
@onready var gold_label: Label3D = $GoldLabel
@onready var info_label: Label3D = $InfoLabel
@onready var fog_volume: FogVolume = $FogVolume

@export var projectile_ball: PackedScene

var enemies_to_attack: Array[Node3D]
var enemy_to_attack: Node3D
var is_attacking: bool = false
var can_attack: bool = false
var spawned_projectile: Node3D

var ability_activation = 0
var minion = false

# Called when the node enters the scene tree for the first time.
func _ready():
	health_value = building_health
	health_bar.set_max(building_health)
	health_bar.set_value(health_value)
	health_bar.create_lines(building_health)
	var ls = LabelSettings.new()
	ls.outline_size = 6
	ls.outline_color = Color.BLACK
	ls.font_size = 30
	var style = health_bar.get_theme_stylebox("fill")
	var _model: StaticBody3D 
	match building_type:
		0: _model = tower_model.instantiate()
		1: _model = barrack_model.instantiate()
		2: _model = nexus_model.instantiate()
	var _mesh: MeshInstance3D = _model.get_node("Mesh")
	if _mesh.get_parent():
		_mesh.get_parent().remove_child(_mesh)
	add_child(_mesh)
	var _collision_shape: CollisionShape3D = _model.get_node("CollisionShape3D")
	if _collision_shape.get_parent():
		_collision_shape.get_parent().remove_child(_collision_shape)
	add_child(_collision_shape)
	if is_in_group("player1"):
		teamName = "player1"
		gold_label.queue_free()
		var fog_size = building_range * 2.6 if building_range > 0 else 10
		fog_volume.size = Vector3(fog_size, 5, fog_size)
	else:
		teamName = "player2"
		remove_child(fog_volume)
	teamIndex = int(teamName.right(1)) - 1
	style.bg_color = Game.player_stats[teamIndex].color
	match building_type:
		0: #TOWER
			var mat_dark = _mesh.mesh.surface_get_material(1).duplicate()
			mat_dark.albedo_color = Game.player_stats[teamIndex].building_dark_color
			_mesh.set_surface_override_material(1, mat_dark)
			var mat_light = _mesh.mesh.surface_get_material(3).duplicate()
			mat_light.albedo_color = Game.player_stats[teamIndex].building_light_color
			_mesh.set_surface_override_material(3, mat_light)
		1, 2: #BARRACK & NEXUS
			var mat_light = _mesh.mesh.surface_get_material(0).duplicate()
			mat_light.albedo_color = Game.player_stats[teamIndex].building_light_color
			_mesh.set_surface_override_material(0, mat_light)
			var mat_dark = _mesh.mesh.surface_get_material(1).duplicate()
			mat_dark.albedo_color = Game.player_stats[teamIndex].building_dark_color
			_mesh.set_surface_override_material(1, mat_dark)
	if building_type == type.BARRACK:
		var mat_dark = _mesh.mesh.surface_get_material(1).duplicate()
		mat_dark.albedo_color = Game.player_stats[teamIndex].building_dark_color
		for mesh in _mesh.get_children():
			if mesh.name.begins_with("Bar"):
				mesh.set_surface_override_material(0, mat_dark)
	detection_shape.shape.radius = building_range
	update_stats()

func update_stats():
	stats_label.text = str(type.keys()[building_type]) + " - " + str(lane.keys()[building_lane]) + "\n" +\
	str(building_damage) + "AD" + " - " + str(building_armor) + "ARMOR" + "\n" +\
	str(building_tier) + " Tier"
	health_bar.set_max(building_health)
	health_bar.set_value(health_value)
	$HealthBar/SubViewport/TierIcon.set_up_icon(building_tier, building_type, 36, false)
	$HealthBar/SubViewport/TierIcon.visible = true
	health_bar.create_lines(building_health)
	attack_cooldown.wait_time = building_speed
	detection_shape.shape.radius = building_range

func take_damage(amount, attacker, valid_for_abilities, building_penetration, dmg_type):
	for special in attacker.special_abilities:
		if special.ability_type == "Siedge" and is_in_group("building"):
			amount = amount + amount * special.ability_amount
	self.health_value -= int(amount * check_armor())
	if self.health_value <= 0:
		if building_type == type.TOWER:
			attacker.change_target(self)
			var gold_amount = Game.base_tower_value + (25 * building_tier)
			Game.player_stats[attacker.teamIndex].gold += gold_amount
			Game.player_stats[attacker.teamIndex].towers_destroyed += 1
			if teamName != "player1": #Execute code for p2, p3 and p4 when destroying tower
				## Setup gold label
				gold_label.modulate = Color.GOLD
				gold_label.text = "+" + str(gold_amount) + "G"
				gold_label.font_size = 60 + (0.1 * gold_amount)
				gold_label.visible = true
				gold_label.destroy_timer(1.5)
				gold_label.reparent(get_node("/root/GameNode"), true)
			queue_free()
		elif building_type == type.BARRACK:
			attacker.change_target(self)
			var gold_amount = Game.base_barrack_value + (25 * building_tier)
			Game.player_stats[attacker.teamIndex].gold += gold_amount
			Game.player_stats[attacker.teamIndex].barracks_destroyed += 1
			if teamName != "player1": #Execute code for p2, p3 and p4
				## Setup gold label
				gold_label.modulate = Color.GOLD
				gold_label.text = "+" + str(gold_amount) + "G"
				gold_label.font_size = 60 + (0.1 * gold_amount)
				gold_label.visible = true
				gold_label.destroy_timer(1.5)
				gold_label.reparent(get_node("/root/GameNode"), true)
			queue_free()
		elif building_type == type.NEXUS:
			if teamName == "player2":
				Game.winner = "PLAYER 1"
			if teamName == "player1":
				Game.winner = "PLAYER 2"
			get_tree().change_scene_to_file("res://Scenes/Levels/End Scene.tscn")
	else:
		health_bar.set_value(health_value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if building_type == type.NEXUS:
		if passive_gold_enabled == true:
			if gold_started:
				return
			gold_started = true
			await get_tree().create_timer(passive_gold_time).timeout
			Game.player_stats[teamIndex].gold += passive_gold_amount
			gold_started = false
	if building_damage <= 0:
		return
	if is_attacking:
		if can_attack:
			enemy_to_attack = closest_target()
			can_attack = false
			attack_cooldown.start()
			spawn_projectile()
				
func spawn_projectile():
	var projectile: StaticBody3D
	projectile = projectile_ball.instantiate()
	projectile.start_pos = self.global_position + Vector3(0, 1.5, 0)
	projectile.target_node = enemy_to_attack
	add_child(projectile)
	projectile.init(Game.player_stats[teamIndex].color)
	spawned_projectile = projectile

func change_target(body: Node3D):
	enemies_to_attack.erase(body)

func closest_target():
	if enemy_to_attack == null:
		var body: Node3D
		var dist: float = INF
		for enemy in enemies_to_attack:
			var new_dist = self.position.distance_to(enemy.position)
			if new_dist < dist:
				dist = new_dist
				body = enemy
		return body
	else:
		return enemy_to_attack

func _on_detection_area_body_entered(body):
	if building_damage <= 0:
		return
	if !body.is_in_group(teamName) && body.is_in_group("mob"):
		enemies_to_attack.append(body)
		is_attacking = true

func _on_detection_area_body_exited(body):
		enemies_to_attack.erase(body)
		if enemies_to_attack.size() == 0:
			is_attacking = false
		else:
			enemy_to_attack = closest_target()

func _on_attack_cooldown_timeout():
	if enemy_to_attack != null:
		if is_instance_valid(enemy_to_attack) && is_instance_valid(self):
			enemy_to_attack.take_damage(building_damage, self, 1, 0.25, "Physical")
	can_attack = true

# This solution does not take into account additional armor. We need to get rid of the global variables and make the building_armor to update with upgrading
func check_armor():
	var armor_divide = 100
	if building_armor == 0:
		return 1
	elif building_armor <= 10:
		armor_divide *= 0.6
	elif building_armor <= 20:
		armor_divide *= 0.5
	elif building_armor <= 30:
		armor_divide *= 0.4
	elif building_armor > 30:
		armor_divide *= 0.3
	var damage_reduction = armor_divide / (armor_divide + building_armor)
	return damage_reduction

func _on_health_changed(old_value, new_value):
	var diff = old_value - new_value
	info_label.font_size = 65 + (0.6 * diff)
	if diff > 0:
		info_label.modulate = Color.RED
		info_label.text = "-" + str(diff)
		info_label.visible = true
		await get_tree().create_timer(0.4).timeout
		info_label.text = ""
		info_label.visible = false
	elif diff < 0:
		info_label.modulate = Color.GREEN
		info_label.text = "+" + str(abs(diff))
		info_label.visible = true
		await get_tree().create_timer(0.4).timeout
		info_label.text = ""
		info_label.visible = false
