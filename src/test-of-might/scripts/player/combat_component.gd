class_name CombatComponent extends Node2D

@onready var player: Player = get_parent() as Player
@onready var stats_comp: StatsComponent = player.get_node("StatsComponent") as StatsComponent
@onready var state_manager: StateManager = player.get_node("StateManager") as StateManager
@onready var sfx_comp: SFXComponent = player.get_node("SfxComponent") as SFXComponent

var can_attack: bool = true
var attack_locked_direction: String = ""
var attack_locked_direction_mouse: String = ""
var upgrades : Array[BaseBulletStrategy] = []

func _ready() -> void:
	pass

var default_bullet_scene = preload("res://scenes/objects/bullet.tscn")

func _physics_process(delta: float) -> void:
	var weapon = player.inventory.get_current_weapon()
	if weapon and weapon.subtype == "ranged":
		rotate_weapon_towards_mouse()
	player.update_weapon_visibility()


func rotate_weapon_towards_mouse():
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - global_position).normalized()
	var player_offset = Vector2(0, -20)
	
	var horizontal_radius = 16.0 
	var vertical_radius = 32.0


	var real_angle = dir_to_mouse.angle()
	
	var ellipse_pos = Vector2(
		horizontal_radius * cos(real_angle),
		vertical_radius * sin(real_angle)
	)
	
	player.ranged_weapon.position = ellipse_pos + player_offset

	var visual_angle = dir_to_mouse.angle() - PI / 4
	player.ranged_weapon.global_rotation = visual_angle

func perform_attack(is_heavy: bool = false):
	if not can_attack:
		return
	
	var weapon = player.inventory.get_current_weapon()
	if weapon and weapon.subtype == "ranged":
		perform_ranged_attack(weapon)
		return

	can_attack = false
	var dmg_base = UpdateStats.get_total_damage()
	var radius = UpdateStats.get_total_range()
	var cooldown = UpdateStats.get_total_cooldown(stats_comp.attack_cooldown)
	var facing_direction = player.facing_direction
	
	#get effects
	var eff_name = ""
	var eff_power = 0.0
	var eff_duration = 0.0
	
	if weapon:
		eff_name = weapon.get("effect_name") if "effect_name" in weapon else ""
		eff_power = weapon.get("effect_power") if "effect_power" in weapon else 0.0
		eff_duration = weapon.get("effect_duration") if "effect_duration" in weapon else 0.0
		
	if is_heavy:
		radius = stats_comp.heavy_attack_radius 
		dmg_base = dmg_base * 1.5 # Or dmg_base * 2
		cooldown = stats_comp.heavy_attack_cooldown

	var dir_to_target: Vector2

	if PreviousScene.combat_style_mouse_based:
		var mouse_pos = get_global_mouse_position()
		dir_to_target = (mouse_pos - global_position).normalized()
		
		# Determine facing direction for animation
		if abs(dir_to_target.x) > abs(dir_to_target.y):
			facing_direction = "Right" if dir_to_target.x > 0 else "Left"
		else:
			facing_direction = "Down" if dir_to_target.y > 0 else "Up"

		attack_locked_direction_mouse = facing_direction

	else:
		attack_locked_direction = facing_direction
		match facing_direction:
			"Right": dir_to_target = Vector2.RIGHT
			"Left": dir_to_target = Vector2.LEFT
			"Up": dir_to_target = Vector2.UP
			"Down": dir_to_target = Vector2.DOWN
			_: dir_to_target = Vector2.DOWN


	var anim_dir = ""
	if PreviousScene.combat_style_mouse_based:
		anim_dir = attack_locked_direction_mouse if attack_locked_direction_mouse != "" else facing_direction
	else:
		anim_dir = attack_locked_direction if attack_locked_direction != "" else facing_direction
	var anim_speed_scale = 0.5 if is_heavy else 1.0
	
	state_manager.change_state("Attack")

	# Heavy attack is slower
	player.animation_manager.set_animation_speed_scale(anim_speed_scale)

	# Compute attack hit position
	var attack_pos = global_position + dir_to_target * radius

	var attack_args = {
		"radius": radius,
		"dmg_base": dmg_base,
		"attack_pos": attack_pos,
		"effect_name": eff_name,
		"effect_power": eff_power,
		"effect_duration": eff_duration
	}
	get_tree().create_timer(0.1).timeout.connect(_apply_attack_damage.bind(attack_args))

	sfx_comp.play_attack()

	get_tree().create_timer(cooldown).timeout.connect(_reset_attack_cooldown)


func perform_ranged_attack(weapon = null):
	if not can_attack:
		return
	can_attack = false
	var bullet_scene_to_spawn = default_bullet_scene
	
	if weapon and weapon.get("animation") != null:
		bullet_scene_to_spawn = weapon.animation
	
	var bullet = bullet_scene_to_spawn.instantiate() as Bullet
	for upgrade in upgrades:
		upgrade.apply_upgrade(bullet)
		
	var muzzle = player.ranged_weapon.get_node("Marker2D") as Marker2D
	bullet.global_position = muzzle.global_position

	bullet.rotation = muzzle.global_rotation + PI / 4
	bullet.damage = calculate_attack_damage()
	
	if weapon:
		if "effect_name" in weapon: bullet.effect_name = weapon.effect_name
		if "effect_power" in weapon: bullet.effect_power = weapon.effect_power
		if "effect_duration" in weapon: bullet.effect_duration = weapon.effect_duration
	
	get_tree().get_root().add_child(bullet)

	var cooldown = stats_comp.attack_cooldown
	get_tree().create_timer(cooldown).timeout.connect(_reset_attack_cooldown)
	

func perform_heavy_attack():
	perform_attack(true)


func calculate_attack_damage():
	var damage = stats_comp.attack_damage
	if player.rng.randf() < stats_comp.crit_chance:
		damage = int(damage * stats_comp.crit_multiplier)
	damage = int(damage * stats_comp.damage_multiplier)
			
	return damage

func _apply_attack_damage(args: Dictionary):
	var radius = args["radius"]
	var dmg_base = args["dmg_base"]
	var attack_pos = args["attack_pos"]
	
	var eff_name = args["effect_name"]
	var eff_power = args["effect_power"]
	var eff_duration = args["effect_duration"]

	var shape = CircleShape2D.new()
	shape.radius = radius

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape.get_rid()
	params.transform = Transform2D(0, attack_pos)

	var space = get_world_2d().direct_space_state
	var results = space.intersect_shape(params, 32)

	for r in results:
		var collider = r.collider
		if collider == player:
			continue
		if collider and collider.has_method("take_damage"):
			var damage = dmg_base
			if player.rng.randf() < stats_comp.crit_chance:
				damage = int(damage * stats_comp.crit_multiplier)
				print("Trafienie krytyczne! Obrazenia:", damage)
			
			# Zastosuj mnożnik obrażeń z umiejętności
			damage = int(damage * stats_comp.damage_multiplier)
			
			collider.take_damage(damage)
			
			if eff_name != "":
				EffectManager.apply_effect(collider, eff_name, eff_power, eff_duration)
	
	
func _reset_attack_cooldown():
	can_attack = true




func get_attack_offset() -> Vector2:
	var facing_direction = player.get_facing_direction()
	if PreviousScene.combat_style_mouse_based:
		var mouse_pos = get_global_mouse_position()
		var dir_to_mouse = (mouse_pos - global_position).normalized()
		return dir_to_mouse * 24

	else:
		match (attack_locked_direction if attack_locked_direction != "" else facing_direction):
			"Right":
				return Vector2(24, 0)
			"Left":
				return Vector2(-24, 0)
			"Up":
				return Vector2(0, -24)
			"Down":
				return Vector2(0, 24)
			_:
				return Vector2.ZERO
