extends Node
class_name CombatComponent

# Referencje
@export var player: CharacterBody2D
@export var equipment: EquipmentComponent
@onready var audio_attack = $"../sfxAttack" # Dostosuj ścieżkę jeśli trzeba

# Bazowe statystyki (używane gdy brak broni lub jako baza)
@export var base_damage: int = 25
@export var base_cooldown: float = 0.9
@export var base_range: float = 30.0
@export var crit_chance: float = 0.15
@export var crit_multiplier: float = 2.0

# Stan walki
var can_attack: bool = true
var upgrades : Array = [] # Do systemu pocisków

func perform_attack(direction_vector: Vector2):
	if not can_attack: return
	
	can_attack = false
	
	# Pobierz dane z broni lub bazowe
	var weapon = equipment.get_current_weapon()
	var damage = weapon.damage if weapon else base_damage
	var cooldown = weapon.cooldown if weapon else base_cooldown
	var range_val = weapon.range_radius if weapon else base_range
	var is_ranged = (weapon and weapon.SubType == "ranged") 
	
	# Dźwięk
	if audio_attack:
		audio_attack.pitch_scale = randf_range(0.9, 1.1)
		audio_attack.play()
	
	if is_ranged:
		_shoot_projectile(weapon, direction_vector)
	else:
		# Melee - z opóźnieniem na animację
		var attack_pos = player.global_position + direction_vector * range_val
		get_tree().create_timer(0.1).timeout.connect(
			func(): _apply_melee_damage(attack_pos, range_val, damage)
		)

	# Cooldown
	get_tree().create_timer(cooldown).timeout.connect(func(): can_attack = true)

func perform_heavy_attack(direction_vector: Vector2):
	if not can_attack: return
	can_attack = false
	
	# Hardcodowane wartości z oryginału dla heavy attack
	var damage = 75
	var radius = 45.0
	var cooldown = 1.2
	
	var attack_pos = player.global_position + direction_vector * radius
	get_tree().create_timer(0.1).timeout.connect(
			func(): _apply_melee_damage(attack_pos, radius, damage)
	)
	get_tree().create_timer(cooldown).timeout.connect(func(): can_attack = true)

func _apply_melee_damage(attack_pos: Vector2, radius: float, damage: int):
	# Fizyczne zapytanie o kolizje (ShapeCast)
	var shape = CircleShape2D.new()
	shape.radius = radius
	
	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape.get_rid()
	params.transform = Transform2D(0, attack_pos)
	# params.collision_mask = ... # Warto ustawić maskę na wrogów!
	
	var space = player.get_world_2d().direct_space_state
	var results = space.intersect_shape(params, 32)
	
	for r in results:
		var collider = r.collider
		if collider == player: continue
		
		if collider.has_method("take_damage"):
			var final_dmg = damage
			# Krytyki
			if randf() < crit_chance:
				final_dmg = int(damage * crit_multiplier)
				print("KRYTYK!")
			
			# Tu dodaj mnożniki z UpdateStats jeśli masz
			
			collider.take_damage(final_dmg)

func _shoot_projectile(weapon_res, direction: Vector2):
	if not weapon_res.projectile_scene: return
	
	var bullet = weapon_res.projectile_scene.instantiate()
	# Aplikowanie ulepszeń do pocisków
	for upgrade in upgrades:
		if upgrade.has_method("apply_upgrade"):
			upgrade.apply_upgrade(bullet)
			
	bullet.global_position = player.global_position # Lub Marker2D
	bullet.rotation = direction.angle()
	bullet.damage = weapon_res.damage
	
	player.get_parent().add_child(bullet)
