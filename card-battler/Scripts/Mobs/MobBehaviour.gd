extends "res://Scripts/Mobs/MobMovement.gd"
# Generic mobs info
var mob_name: String
@export var mob_health: int = 75
var current_health: int:
	get:
		return current_health
	set(value):
		current_health = value
		health_bar.set_value(current_health)

signal health_changed(amount, dmg_type)

var barrier_hp: int:
	get:
		return barrier_hp
	set(value):
		if value > 0:
			special_icons.add_buff("Barrier")
		else:
			special_icons.remove_buff("Barrier")
		emit_signal("barrier_changed", barrier_hp, value)
		barrier_hp = value
		barrier_bar.set_value(barrier_hp)
signal barrier_changed(old_value, new_value)

@export var mob_attack: float = 5.0
@export var mob_armor: int = 5
@export var attack_speed: float = 1.25
@export var info_text_scene: PackedScene
@onready var gold_label: Label3D = $GoldLabel
@onready var health_bar: ProgressBar = $HealthBar/SubViewport/Panel/ProgressBar
@onready var barrier_bar: ProgressBar = $HealthBar/SubViewport/Panel/ProgressBarBarrier
@onready var fog_volume: FogVolume = $FogVolume
var armor_penetration: float = 0
var teamName: String
var teamIndex: int

var minion_class: Game.mob_class
var minion_sub_class: Game.mob_sub_class
var mob_tier: int = -1
var card_value: float
var path: String

var enemies_to_attack: Array[Node3D]
var detected_enemies_array: Array[Node3D]
var detected_friends_array: Array[Node3D]
var opponent_to_attack: Node3D

@export var projectile_arrow: PackedScene
var path_curve: Curve3D

# Animation variables
var attack_anim: String
var idle_anim: String
var walk_anim: String
var death_anim: String

# Special Abilities
var mark_damage: int = 0
var marked: bool = false

var special_abilities: Array[MobSpecialAbility] = []
@onready var special_icons: Control = $HealthBar/SubViewport/Panel/SpecialIcons

# DOT variables
var dot_fire: bool = false
var dot_acid: bool = false
var dot_bleed: bool = false
var dot_curse: bool = false
var dot_fire_tick: int = 0
var dot_acid_tick: int = 0
var dot_bleed_tick: int = 0
var dot_curse_tick: int = 0
var dot_fire_damage_intake: int = 0
var dot_acid_damage_intake: int = 0
var dot_bleed_damage_intake: int = 0
var dot_curse_damage_intake: int = 0
var heal_reduction: float = 0

func _ready():
	super()
	current_health = mob_health
	health_bar.set_max(mob_health)
	health_bar.set_value(current_health)
	barrier_bar.set_max(mob_health)
	barrier_bar.set_value(barrier_hp)
	$HealthBar/SubViewport/TierIcon.set_up_icon(mob_tier, minion_sub_class, 40,  true)
	$HealthBar/SubViewport/TierIcon.visible = true
	health_bar.create_lines(mob_health)
	var ls = LabelSettings.new()
	#modify label color depending on mob's tier
	match mob_tier:
		-1: 	#BASE tier
			ls.font_color = Color.WHITE
		0: 		#COMMON tier
			ls.font_color = Game.common_color
		1: 		#RARE tier
			ls.font_color = Game.rare_color
		2: 		#EPIC tier
			ls.font_color = Game.epic_color
		3: 		#LEGENDARY tier
			ls.font_color = Game.legendary_color
		_: 		#Default case
			ls.font_color = Color.WHITE
	ls.outline_size = 6
	ls.outline_color = Color.BLACK
	ls.font_size = 30
	var style = health_bar.get_theme_stylebox("fill")
	style.bg_color = Game.player_stats[teamIndex].color
	if teamName == "player1":
		gold_label.queue_free()
		var fog_size = $DetectionArea3D/CollisionShape3D.shape.radius * 2.5
		fog_volume.size = Vector3(fog_size, 5, fog_size)
	else:
		fog_volume.queue_free()
	var lane_string = "minions_"+path
	var get_minions_count = Game.player_stats[teamIndex].get(lane_string)
	Game.player_stats[teamIndex].set(lane_string, get_minions_count + 1)
	for animation: String in anim_player.get_animation_list():
		match animation:
			"Attack":
				attack_anim = "Attack"
			"Idle":
				idle_anim = "Idle"
			"Walk":
				walk_anim = "Walk"
			"Death":
				death_anim = "Death"
	for special in special_abilities:
		if special.ability_cooldown > 0:
			special.ability_cooldown_timer = Timer.new()
			special.ability_cooldown_timer.one_shot = true
			special.ability_cooldown_timer.timeout.connect(_on_ability_timer_timeout.bind(special)) 
			add_child(special.ability_cooldown_timer)
			if special.ability_activation == Game.activation.BUFF or special.ability_activation == Game.activation.AURA:
				special.ability_on_cooldown = true
				special.ability_cooldown_timer.wait_time = special.ability_cooldown
				special.ability_cooldown_timer.start()
				
func initialize(card, team: String, main_path: String, model: PackedScene):
	if card != null:
		mob_name = card.card_name
		minion_class = card.type
		minion_sub_class = card.sub_type
		mob_health = card.health
		mob_attack = card.attack_damage
		mob_armor = card.armor
		attack_speed = card.attack_speed
		armor_penetration = card.armor_penetration
		card_value = card.cost
		mob_tier = card.tier
		$HitArea3D/CollisionShape.shape.radius = card.attack_range
		if !card.special_ability_stats.is_empty():
			special_abilities = card.special_ability_stats
	else:
		mob_name = "Default mob"
		minion_class = Game.mob_class.MELEE
		armor_penetration = 0
		$HitArea3D/CollisionShape.shape.radius = 1.5
	teamName = team
	teamIndex = int(team.right(1)) - 1
	add_to_group(teamName)
	path = main_path
	path_curve = $Path3D.curve
	if minion_class == Game.mob_class.RANGED:
		$DetectionArea3D/CollisionShape3D.shape.radius = 8.5
	elif minion_class == Game.mob_class.MAGE:
		$DetectionArea3D/CollisionShape3D.shape.radius = 7.5
	elif minion_class == Game.mob_class.MELEE:
		$DetectionArea3D/CollisionShape3D.shape.radius = 6.0
	if model != null:
		var model_node = model.instantiate()
		var _rootnode: Node3D = model_node.get_node("RootNode")
		if _rootnode.get_parent():
			_rootnode.get_parent().remove_child(_rootnode)
		add_child(_rootnode)
		var _anim: AnimationPlayer = model_node.get_node("AnimationPlayer")
		if _anim.get_parent():
			_anim.get_parent().remove_child(_anim)
		add_child(_anim)
		_anim.animation_finished.connect(self._on_animation_player_animation_finished)
		
func change_health(amount, dmg_type):
	self.current_health += amount
	emit_signal("health_changed", amount, dmg_type)
		
func _on_health_changed(amount, dmg_type):
	if amount == 0:
		return
	var new_label_3D = info_text_scene.instantiate()
	new_label_3D.position = Vector3(randf_range(-0.3, 0.3), new_label_3D.position.y, randf_range(-0.3, 0.3))
	new_label_3D.font_size = 60 + (0.6 * abs(amount))
	new_label_3D.wait_time = 0.5 + (0.01 * abs(amount))
	if amount > 0:
		new_label_3D.modulate = Color.GREEN
		new_label_3D.text = "+" + str(amount)
	elif amount < 0:
		var color: Color
		match dmg_type:
			"Physical": color = Color.RED
			"Mark": color = Color.DARK_RED
			"Fire": color = Color.ORANGE_RED
			"Acid": color = Color.DARK_GREEN
			"Bleed": color = Color.DARK_RED
			"Curse": color = Color.BLUE_VIOLET
			"Magic": color = Color.DARK_VIOLET
			"Ice": color = Color.DEEP_SKY_BLUE
		new_label_3D.modulate = color
		new_label_3D.text = "-" + str(abs(amount))
	add_child(new_label_3D)

func _on_barrier_changed(old_value, new_value):
	var diff = old_value - new_value
	if diff > 0:
		var new_label_3D = info_text_scene.instantiate()
		new_label_3D.font_size = 60 + (0.6 * abs(diff))
		new_label_3D.modulate = Color(0, 0.5, 0.75)
		new_label_3D.text = "-" + str(diff)
		new_label_3D.wait_time = 0.5 + (0.005 * abs(diff))
		add_child(new_label_3D)
	elif diff < 0:
		var new_label_3D = info_text_scene.instantiate()
		new_label_3D.font_size = 60 + (0.6 * abs(diff))
		new_label_3D.modulate = Color.DEEP_SKY_BLUE
		new_label_3D.text = "+" + str(abs(diff))
		new_label_3D.wait_time = 0.5 + (0.005 * abs(diff))
		add_child(new_label_3D)

func take_damage(amount, attacker, valid_for_abilities, penetration, dmg_type):
	if !is_instance_valid(self) || !is_instance_valid(attacker):
		return
	if amount == null:
		return
	if barrier_hp > 0:
		if barrier_hp >= amount:
			barrier_hp -= amount
		else:
			amount -= barrier_hp
			barrier_hp = 0
	if attacker != self:
		for special in special_abilities:
			if attacker.is_in_group("mob"):
				if special.ability_type == "Anti-Range" and attacker.minion_class == Game.mob_class.RANGED:
					amount = amount * (1 - special.ability_amount)
			if attacker.is_in_group("building"):
				if special.ability_type == "Tower Tank" and attacker.is_in_group("building"):
					amount = amount * (1 - special.ability_amount)

	if attacker.is_in_group("mob") && attacker != self:
		for attacker_special in attacker.special_abilities:
			if attacker_special.ability_type == "Range+" and position.distance_to(attacker.position) > 5:
				amount += amount * attacker_special.ability_amount
			if attacker_special.ability_type == "Big Hunter" and attacker_special.ability_threshold > current_health:
				amount += amount * attacker_special.ability_amount

	self.change_health(-int(amount * get_reduction(penetration)), dmg_type)
	
	if marked:
		self.change_health(-mark_damage, "Mark")
		
	if attacker.is_in_group("mob") and valid_for_abilities == 1:
		for attacker_special in attacker.special_abilities:
			if attacker_special.ability_activation == Game.activation.ON_HIT:
				if attacker_special.ability_hits_to_activate != 0:
					attacker_special.ability_hits += 1
				if attacker_special.ability_hits >= attacker_special.ability_hits_to_activate:
					var ability_used = true
					match attacker_special.ability_type:
						"DOT":
							match attacker_special.ability_dot_type:
								"Fire":
									if dot_fire == false or dot_fire_damage_intake < attacker_special.ability_amount:
										dot_fire = false
										dot_fire_damage_intake = attacker_special.ability_amount
										dot_fire_tick = 0
										DamageOverTime("Fire")
									else:
										ability_used = false
								"Acid":
									if dot_acid == false:
										dot_acid_damage_intake = attacker_special.ability_amount
										DamageOverTime("Acid")
									else:
										dot_acid_damage_intake += attacker_special.ability_amount
										dot_acid_tick = 0
										
								"Bleed":
									if dot_bleed == false:
										dot_bleed_damage_intake = attacker_special.ability_amount
										DamageOverTime("Bleed")
									else:
										dot_bleed_damage_intake += attacker_special.ability_amount
										dot_bleed_tick = 0
								"Curse":
									if dot_curse == false or dot_curse_damage_intake < attacker_special.ability_amount:
										dot_curse = false
										dot_curse_damage_intake = attacker_special.ability_amount
										dot_curse_tick = 0
										DamageOverTime("Curse")
									else:
										ability_used = false
						"Ice":
							Debuff(attacker_special)
						"Ricochet":
							var friend = closest_friend([self], 15)
							if friend != null:
								spawn_projectile(friend)
								friend.take_damage(amount * 0.5, attacker, 0, 0, "Physical")
						"Mark":
							if marked == true:
								if attacker_special.ability_amount > mark_damage:
									Debuff(attacker_special)
								else:
									ability_used = false
							else :
								Debuff(attacker_special)
						"DMG":
							take_damage(attacker_special.ability_amount, attacker, 0, 0, "Physical")
						"True DMG":
							take_damage(attacker_special.ability_amount, attacker, 0, 1, "Physical")
						"Heal":
							attacker.Heal(attacker_special.ability_amount, attacker_special.ability_duration)
						"Stun":
							if attacker_special.ability_on_cooldown == false:
								if randi_range(1, 100) < attacker_special.ability_chance:
									Stun(attacker_special.ability_duration)
									attacker_special.ability_on_cooldown = true
									attacker_special.ability_cooldown_timer.start(attacker.ability_cooldown)
								else:
									ability_used = false
						"Disarm":
							if attacker_special.ability_on_cooldown == false:
								Debuff(attacker_special)
								attacker_special.ability_on_cooldown = true
								attacker_special.ability_cooldown_timer.start(attacker_special.ability_cooldown)
						"AOE":
							var exclude_array = []
							while closest_friend(exclude_array, attacker_special.ability_radius) != null:
								var friend = closest_friend(exclude_array, attacker_special.ability_radius)
								friend.take_damage(attacker_special.ability_amount, attacker, 0, 0, "Magic")
								if friend != null:
									exclude_array.append(friend)

					if attacker_special.ability_hits_to_activate != 0 and ability_used:
						attacker_special.ability_hits = 0
## DEATH
	if self.current_health <= 0:
		attacker.change_target(self)
## On kill abilities
		if attacker.is_in_group("mob") and valid_for_abilities == 1:
			for attacker_special in attacker.special_abilities:
				if attacker_special.ability_activation == Game.activation.ON_KILL:
					if attacker_special.ability_on_cooldown == false:
						match attacker_special.ability_type:
							"Buff":
								match attacker_special.ability_buff_type:
									"Attack Damage":
										attacker.Buff(attacker_special)
										attacker_special.ability_on_cooldown = true
										attacker_special.ability_cooldown_timer.start(attacker_special.ability_cooldown)
									"Attack Speed":
										attacker.Buff(attacker_special)
										attacker_special.ability_on_cooldown = true
										attacker_special.ability_cooldown_timer.start(attacker_special.ability_cooldown)
									"Heal":
										attacker.Heal(attacker_special.ability_amount, attacker_special.ability_duration)
							"Explode":
								var exclude_array = []
								while closest_friend(exclude_array, attacker_special.ability_radius) != null:
									var enemy = closest_friend(exclude_array, attacker_special.ability_radius)
									enemy.take_damage(attacker_special.ability_amount, attacker, 0, 0, "Fire")
									if enemy != null:
										exclude_array.append(enemy)
							"Gold":
								if attacker.teamName == "red":
									Game.player2_gold += attacker_special.ability_amount
								elif attacker.teamName == "blue":
									Game.player1_gold += attacker_special.ability_amount
								attacker.gold_label.modulate = Color.GOLD
								attacker.gold_label.text = "+" + str(attacker_special.ability_amount) + "G"
								attacker.gold_label.font_size = 65 + (0.6 * attacker_special.ability_amount)
								attacker.gold_label.visible = true
								attacker.gold_label.hide_timer(0.5)
							"Summon":
								if randi_range(1, 100) < attacker_special.ability_chance:
									summon_mob(attacker_special)
	# On death abilities
			for special in special_abilities:
				if special.ability_activation == Game.activation.ON_DEATH:
					match special.ability_type:
						"Summon":
							summon_mob(special)
						"Explode":
							var exclude_array = []
							while closest_enemy(exclude_array, special.ability_radius) != null:
								var enemy = closest_enemy(exclude_array, special.ability_radius)	
								enemy.take_damage(special.ability_amount, self, 0, 0, "Fire")
								if enemy != null:
									exclude_array.append(enemy)
						"Buff":
							var exclude_array = []
							while closest_friend(exclude_array, special.ability_radius) != null:
								var friend = closest_friend(exclude_array, special.ability_radius)
								exclude_array.append(friend)
								friend.Buff(special)
						"DOT":
							var exclude_array = []
							while closest_enemy(exclude_array, special.ability_radius) != null:
								var enemy = closest_enemy(exclude_array, special.ability_radius)
								if enemy != null:
									exclude_array.append(enemy)
									match special.ability_dot_type:
										"Fire":
											enemy.dot_fire_damage_intake = special.ability_amount
											enemy.dot_fire_tick = 0
											enemy.DamageOverTime("Fire")
										"Acid":
											if dot_acid == false:
												enemy.dot_acid_damage_intake = special.ability_amount
												enemy.DamageOverTime("Acid")
											else:
												enemy.dot_acid_damage_intake += special.ability_amount
												enemy.dot_acid_tick = 0		
										"Bleed":
											if dot_bleed == false:
												enemy.dot_bleed_damage_intake = special.ability_amount
												enemy.DamageOverTime("Bleed")
											else:
												enemy.dot_bleed_damage_intake += special.ability_amount
												enemy.dot_bleed_tick = 0
										"Curse":
											enemy.dot_curse_damage_intake = special.ability_amount
											enemy.dot_curse_tick = 0
											enemy.DamageOverTime("Curse")
		if dot_curse:
			var next_curse_target = closest_friend([], 10)
			if next_curse_target != null:
				if next_curse_target.dot_curse == false or next_curse_target.dot_curse_damage_intake < dot_curse_damage_intake:
					next_curse_target.dot_curse = false
					next_curse_target.dot_curse_damage_intake = dot_curse_damage_intake
					next_curse_target.dot_curse_tick = 0
					next_curse_target.DamageOverTime("Curse")
		var gold_amount: int = (Game.base_mob_value + (card_value * 0.1))
		if attacker.is_in_group("building"): 
			gold_amount = floor(gold_amount/2)
		var lane_string = "minions_"+path
		var get_minions_count = Game.player_stats[teamIndex].get(lane_string)
		Game.player_stats[teamIndex].set(lane_string, get_minions_count - 1)
		Game.player_stats[teamIndex].minions_lost += 1
		Game.player_stats[attacker.teamIndex].gold += gold_amount
		Game.player_stats[attacker.teamIndex].minions_killed += 1
		if teamName != "player1": #Execude code for p2, p3 and p4 minions killed
			## Setup gold label
			gold_label.modulate = Color.GOLD
			gold_label.text = "+" + str(gold_amount) + "G"
			gold_label.font_size = 65 + (0.6 * gold_amount)
			gold_label.visible = true
			gold_label.destroy_timer(0.5)
			gold_label.reparent(get_node("/root/GameNode"), true)
		queue_free()
		
func summon_mob(special_ability_stats: MobSpecialAbility):
	var target_positions : Array
	var bot_card = special_ability_stats.ability_minion_to_spawn
	var model : PackedScene
	var spawn_manager = get_tree().get_first_node_in_group("SpawnManager")
	if bot_card != null:
		if bot_card.model != null:
			model = bot_card.model
		match bot_card.race:
			0, 6, 7:
				model = spawn_manager.minion_models[7]
			1:
				model = spawn_manager.minion_models[6]
			2, 3:
				model = spawn_manager.minion_models[1]
			4:
				model = spawn_manager.minion_models[5]
			5:
				model = spawn_manager.minion_models[3]
			8:
				model = spawn_manager.minion_models[2]
	else:
		model = spawn_manager.minion_models[0]
	var bot: CharacterBody3D
	bot = spawn_manager.minionScene.instantiate()
	bot.initialize(bot_card, self.teamName, self.path, model)
	var bot_new_pos = self.position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	bot.position = bot_new_pos
	bot.rotation = self.rotation
	bot.currentTarget = self.currentTarget
	bot.targetArray = self.targetArray
	get_parent().add_child(bot)

func _process(delta):
	super(delta)
	if !is_stunned:
		if opponent_to_attack != null:
			# looking at the current enemy to atack
			var look_pos = Vector3(opponent_to_attack.global_position.x, position.y, opponent_to_attack.global_position.z)
			var look_dir = position.direction_to(look_pos)
			rotation.y = lerp_angle(rotation.y, atan2(-look_dir.x, -look_dir.z), delta * rotate_speed)	
		if is_attacking:
			anim_player.speed_scale = attack_speed
			if anim_player.current_animation != attack_anim:
				anim_player.play(attack_anim)
				#spawn an arrow from mob position to enemy when the mob is ranged
				if minion_class == Game.mob_class.RANGED || minion_class == Game.mob_class.MAGE:
					spawn_projectile(opponent_to_attack)
		else:
			anim_player.speed_scale = 1 
			if velocity.length() > 0:
				anim_player.play(walk_anim)
			else:
				anim_player.play(idle_anim)
				
func spawn_projectile(target):
	var projectile: PathFollow3D
	projectile = projectile_arrow.instantiate()
	
	var local_pos: Vector3 = to_local(target.global_position) + Vector3(0, 1, 0)
	path_curve.set_point_position(1, local_pos)
	path_curve.set_point_in(1, Vector3(0, 2, 0))
	
	projectile.target_node = target
	projectile.position = path_curve.get_point_position(0)
	$Path3D.add_child(projectile)
	projectile.init(Game.player_stats[teamIndex].color)
	
func change_target(body: Node3D):
	opponent_to_attack = null
	detected_enemies_array.erase(body)
	set_target()

func set_target():
	if detected_enemies_array.size() == 0:
		look_ahead = 2.5
		is_chasing = false
		opponent_to_attack = null
		set_movement_target(targetArray[currentTarget])
	else:
		look_ahead = 7.5
		is_chasing = true
		opponent_to_attack = closest_target()
		set_movement_target(opponent_to_attack.global_position)

func _on_area_3d_body_entered(body):
	if body == self:
		return
	if !body.is_in_group(teamName) && (body.is_in_group("mob") || body.is_in_group("building")): 
		# Detected enemy when not in same player group
		if detected_enemies_array.find(body) == -1:
			detected_enemies_array.append(body)
			set_target()
	elif body.is_in_group(teamName) && body.is_in_group("mob"):
		if detected_friends_array.find(body) == -1:
			detected_friends_array.append(body)
			
func _on_area_3d_body_exited(body):
	if detected_friends_array.find(body) != -1:
		detected_friends_array.erase(body)
	if detected_enemies_array.find(body) != -1:
		if detected_enemies_array.size() > 0:
			detected_enemies_array.erase(body)
			if body == opponent_to_attack:
				set_target()

func _on_nav_path_timer_timeout():
	if !is_attacking:
		if navigation_agent.is_navigation_finished() && opponent_to_attack == null: return
		if !navigation_agent.is_target_reached():
			if opponent_to_attack != null:
				set_movement_target(opponent_to_attack.global_position)
			else:
				set_movement_target(navigation_agent.target_position)

func _on_hit_area_3d_body_entered(body):
	if body == self:
		return
	if !body.is_in_group(teamName) && (body.is_in_group("mob") || body.is_in_group("building")):
		enemies_to_attack.append(body)
		is_chasing = false
		is_attacking = true

func _on_hit_area_3d_body_exited(body):
	enemies_to_attack.erase(body)
	if enemies_to_attack.size() == 0:
		is_attacking = false

func _on_animation_player_animation_finished(anim_name):
	if anim_name == attack_anim:
		if enemies_to_attack.size() > 0:
			enemies_to_attack[0].take_damage(mob_attack, self, 1, armor_penetration, "Physical")

func _on_navigation_agent_3d_link_reached(details: Dictionary):
	if details.owner.is_in_group("teleport"):
		_link_end_point = details.link_exit_position
		_is_travelling_links = true
		look_ahead = 0.25

### SPECIAL ABILITIES

func Stun(duration):
	self.is_stunned = true
	special_icons.add_debuff("Stun")
	await get_tree().create_timer(duration).timeout
	special_icons.remove_debuff("Stun")
	self.is_stunned = false

func DamageOverTime(type: String):
	match type:
		"Fire":
			dot_fire = true
			special_icons.add_debuff("Fire")
			await get_tree().create_timer(1).timeout
			while dot_fire_tick < 3 and dot_fire:
				self.take_damage(dot_fire_damage_intake, self, 0, 0, "Fire")
				dot_fire_tick += 1
				await get_tree().create_timer(1).timeout
			dot_fire_tick = 0
			special_icons.remove_debuff("Fire")
			dot_fire = false
		"Acid":
			dot_acid = true
			mob_armor -= 10
			special_icons.add_debuff("Poison")
			await get_tree().create_timer(1).timeout
			while dot_acid_tick < 5:
				self.take_damage(dot_acid_damage_intake, self, 0, 0, "Acid")
				dot_acid_tick += 1
				await get_tree().create_timer(1).timeout
			dot_acid_tick = 0
			mob_armor += 10
			special_icons.remove_debuff("Poison")
			dot_acid = false
		"Bleed":
			dot_bleed = true
			heal_reduction = 0.5
			special_icons.add_debuff("Bleed")
			await get_tree().create_timer(1).timeout
			while dot_bleed_tick < 3:
				self.take_damage(dot_bleed_damage_intake, self, 0, 0, "Bleed")
				dot_bleed_tick += 1
				await get_tree().create_timer(1).timeout
			dot_bleed_tick = 0
			heal_reduction = 0
			special_icons.remove_debuff("Bleed")
			dot_bleed = false
		"Curse":
			dot_curse = true
			special_icons.add_debuff("Curse")
			await get_tree().create_timer(1).timeout
			while dot_curse_tick < 5 and dot_curse:
				self.take_damage(dot_curse_damage_intake, self, 0, 0, "Curse")
				dot_curse_tick += 1
				await get_tree().create_timer(1).timeout
			dot_curse_tick = 0
			special_icons.remove_debuff("Curse")
			dot_curse = false

func Heal(amount, ticks):
	var heal_tick = 0
	if heal_reduction > 0:
		amount = amount * heal_reduction
	if current_health < mob_health:
		if ticks == 0:
			self.change_health(check_hp_to_heal(amount), "Heal")
		else:
			while heal_tick < ticks:
				self.change_health(check_hp_to_heal(amount/ticks), "Heal")
				await get_tree().create_timer(1).timeout
				heal_tick += 1

func Debuff(debuffer_ability_stats: MobSpecialAbility):
	match debuffer_ability_stats.ability_type:
		"Ice":
			var original_attack_speed = attack_speed
			special_icons.add_debuff("Ice")
			attack_speed -= attack_speed * debuffer_ability_stats.ability_amount
			var duration = debuffer_ability_stats.ability_duration
			self.change_health(-10, "Ice")
			await get_tree().create_timer(duration).timeout
			special_icons.remove_debuff("Ice")
			attack_speed = original_attack_speed
		"Disarm":
			var original_attack = mob_attack
			special_icons.add_debuff("Disarm")
			mob_attack = mob_attack * (1 - debuffer_ability_stats.ability_amount)
			await get_tree().create_timer(debuffer_ability_stats.ability_duration).timeout
			special_icons.remove_debuff("Disarm")
			mob_attack = original_attack
		"ARP":
			var original_armor = mob_armor
			special_icons.add_debuff("ARP")
			mob_armor = mob_armor * (1 - debuffer_ability_stats.ability_amount)
			await get_tree().create_timer(debuffer_ability_stats.ability_duration).timeout
			special_icons.remove_debuff("ARP")
			mob_armor = original_armor
		"Mark":
			mark_damage = debuffer_ability_stats.ability_amount
			marked = true
			special_icons.add_debuff("Mark")
			await get_tree().create_timer(10).timeout
			special_icons.remove_debuff("Mark")
			mark_damage = 0
			marked = false

func Buff(buffer_ability_stats: MobSpecialAbility):
	buffer_ability_stats.ability_on_cooldown = true
	if !is_instance_valid(buffer_ability_stats):
		return
	buffer_ability_stats.ability_cooldown_timer.start(buffer_ability_stats.ability_cooldown)
	match buffer_ability_stats.ability_buff_type:
		"Attack Damage":
			var original_attack = mob_attack
			special_icons.add_buff("AD")
			if buffer_ability_stats.ability_amount > 1:
				mob_attack += buffer_ability_stats.ability_amount
			else:
				mob_attack += mob_attack * buffer_ability_stats.ability_amount
			await get_tree().create_timer(buffer_ability_stats.ability_duration).timeout
			special_icons.remove_buff("AD")
			mob_attack = original_attack
		"Attack Speed":
			var original_attack_speed = attack_speed
			special_icons.add_buff("AS")
			if buffer_ability_stats.ability_amount > 1:
				attack_speed += attack_speed * float(buffer_ability_stats.ability_amount/100.0)
			else:
				attack_speed += attack_speed * buffer_ability_stats.ability_amount
			await get_tree().create_timer(buffer_ability_stats.ability_duration).timeout
			special_icons.remove_buff("AS")
			attack_speed = original_attack_speed
		"Armor":
			var original_armor = mob_armor
			special_icons.add_buff("Armor")
			mob_armor += buffer_ability_stats.ability_amount
			await get_tree().create_timer(buffer_ability_stats.ability_duration).timeout
			special_icons.remove_buff("Armor")
			mob_armor = original_armor
		"Movement Speed":
			var original_speed = movement_speed
			special_icons.add_buff("MS")
			movement_speed += movement_speed * buffer_ability_stats.ability_amount
			await get_tree().create_timer(buffer_ability_stats.ability_duration).timeout
			special_icons.remove_buff("MS")
			movement_speed = original_speed
		"Barrier":
			var barrier_value = buffer_ability_stats.ability_amount
			barrier_hp += check_barrier_to_add(barrier_value)
			if buffer_ability_stats.ability_duration > 0:
				await get_tree().create_timer(buffer_ability_stats.ability_duration).timeout
				barrier_hp -= check_barrier_to_add(barrier_value)
		"Heal":
			Heal(buffer_ability_stats.ability_amount, buffer_ability_stats.ability_duration)

## Make the timer to activate a specific ability in multi abilities
func _on_ability_timer_timeout(special):
	special.ability_on_cooldown = false
	if special.ability_activation == Game.activation.AURA:
		var exclude_array = []
		match special.ability_type:
			"DMG":
				while closest_enemy(exclude_array, special.ability_radius) != null:
					var enemy = closest_enemy(exclude_array, special.ability_radius)
					enemy.take_damage(special.ability_amount, self, 0, 1, "Physical")
					if enemy != null:
						exclude_array.append(enemy)
			"Disarm":
				while closest_enemy(exclude_array, special.ability_radius) != null:
					var enemy = closest_enemy(exclude_array, special.ability_radius)
					enemy.Debuff("Disarm", self)
					exclude_array.append(enemy)
			"Ice":
				while closest_enemy(exclude_array, special.ability_radius) != null:
					var enemy = closest_enemy(exclude_array, special.ability_radius)
					enemy.Debuff("Ice", self)
					exclude_array.append(enemy)
			"Buff":
				match special.ability_buff_type:
					"Armor":
						while closest_friend(exclude_array, special.ability_radius) != null:
							var friend = closest_friend(exclude_array, special.ability_radius)
							friend.Buff(special)
							exclude_array.append(friend)
					"Attack Damage":
						while closest_friend(exclude_array, special.ability_radius) != null:
							var friend = closest_friend(exclude_array, special.ability_radius)
							friend.Buff(special)
							exclude_array.append(friend)
					"Attack Speed":
						while closest_friend(exclude_array, special.ability_radius) != null:
							var friend = closest_friend(exclude_array, special.ability_radius)
							friend.Buff(special)
							exclude_array.append(friend)
					"Movement Speed":
						while closest_friend(exclude_array, special.ability_radius) != null:
							var friend = closest_friend(exclude_array, special.ability_radius)
							friend.Buff(special)
							exclude_array.append(friend)
	if special.ability_activation == Game.activation.BUFF:
		if detected_friends_array.size() > 0:
			if special.ability_buff_type == "Heal":
				var lowest_hp = 1
				var minion_to_heal: CharacterBody3D
				for friend in detected_friends_array:
					if friend.current_health < friend.mob_health:
						if (friend.current_health / friend.mob_health) < lowest_hp:
							lowest_hp = (friend.current_health / friend.mob_health)
							minion_to_heal = friend
				if minion_to_heal != null:
					minion_to_heal.Heal(special.ability_amount, special.ability_duration)
			else:
				var minion_to_buff: CharacterBody3D
				minion_to_buff = detected_friends_array[randi_range(0, detected_friends_array.size() - 1)]
				minion_to_buff.Buff(special)
	special.ability_on_cooldown = true
	special.ability_cooldown_timer.start(special.ability_cooldown)		

## Calculations
func check_hp_to_heal(amount):
	if current_health + amount > mob_health:
		return mob_health - current_health
	else:
		return amount

func check_barrier_to_add(amount):
	if barrier_hp + amount > (mob_health / 2):
		return (mob_health / 2) - barrier_hp
	else:
		return amount

func get_reduction(penetration):
	var mob_armor_calculate = mob_armor * (1 - penetration)
	var armor_divide = 100
	if mob_armor_calculate == 0:
		return 1
	elif mob_armor_calculate <= 10:
		armor_divide *= 0.6
	elif mob_armor_calculate <= 20:
		armor_divide *= 0.5
	elif mob_armor_calculate <= 30:
		armor_divide *= 0.4
	elif mob_armor_calculate > 30:
		armor_divide *= 0.3
	var damage_reduction = armor_divide / (armor_divide + mob_armor_calculate)
	return damage_reduction
	
func closest_friend(exclude: Array, max_distance: float):
	var body: Node3D
	var dist: float = INF
	for friend in detected_friends_array:
		if exclude.find(friend) == -1:
			var new_dist = position.distance_to(friend.global_position)
			if new_dist < dist && new_dist < max_distance:
				dist = new_dist
				body = friend
	return body

func closest_enemy(exclude: Array, max_distance: float):
	var body: Node3D
	var dist: float = INF   
	for enemy in detected_enemies_array:
		if exclude.find(enemy) == -1:
			var new_dist = position.distance_to(enemy.global_position)
			if new_dist < dist && new_dist < max_distance:
				dist = new_dist
				body = enemy
	return body

func closest_target():
	var body: Node3D
	var dist: float = INF
	for opponent in detected_enemies_array:
		var new_dist = position.distance_to(opponent.global_position)
		if new_dist < dist:
			dist = new_dist
			body = opponent
	return body
