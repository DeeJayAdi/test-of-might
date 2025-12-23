extends Node

var projectile_scene: PackedScene = preload("res://scenes/enemies/bosses/PumpkinWarlock/FireBall.tscn")
var summon_scene: PackedScene = preload("res://scenes/enemies/bosses/PumpkinWarlock/Bat.tscn")

@export var melee_damage: int = 33
@export var range_damage: int = 33
@export var melee_range: float = 40.0
@export var summon_count_min: int = 2
@export var summon_count_max: int = 4

var boss: banshee

func _ready():
	boss = owner

func attack_melee(target_position: Vector2):
	var hit_area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	
	shape.radius = melee_range
	collision_shape.shape = shape
	hit_area.add_child(collision_shape)

	# --- DEBUG ---
	# var debug_poly = Polygon2D.new()
	# var points = PackedVector2Array()
	# for i in range(32):
	# 	var angle = i * TAU / 32
	# 	points.append(Vector2(cos(angle), sin(angle)) * melee_range)
	# debug_poly.polygon = points
	# debug_poly.color = Color(1, 0, 0, 0.5)
	# hit_area.add_child(debug_poly)
	# -------------

	get_tree().current_scene.add_child(hit_area)
	
	var direction = (target_position - boss.global_position).normalized()
	
	hit_area.global_position = boss.global_position + (direction * (melee_range * 2.0))
	hit_area.rotation = direction.angle()
	
	hit_area.collision_layer = 0
	hit_area.collision_mask = 2
	hit_area.monitorable = false
	hit_area.monitoring = true
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var bodies = hit_area.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("player") or body.is_in_group("Player"):
			if body.has_method("take_damage"):
				body.take_damage(melee_damage)
			elif body.has_node("HealthComponent"):
				body.get_node("HealthComponent").take_damage(melee_damage)
	
	await get_tree().create_timer(0.5).timeout
	hit_area.queue_free()
	
	
	
func scream():
	#deal damage according to distance
	var player = get_tree().get_nodes_in_group("player")[0] if get_tree().has_group("player") else null
	if player:
		var distance = boss.global_position.distance_to(player.global_position)
		var max_distance = 300.0
		if distance <= max_distance:
			var distance_ratio = distance / max_distance
			var damage = int(range_damage * (1.0 - (distance_ratio * distance_ratio)))
			if damage > 0:
				if player.has_method("take_damage"):
					player.take_damage(damage)
				elif player.has_node("HealthComponent"):
					player.get_node("HealthComponent").take_damage(damage)
