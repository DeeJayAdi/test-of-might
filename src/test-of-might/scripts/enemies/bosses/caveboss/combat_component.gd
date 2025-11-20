extends Node

var projectile_scene: PackedScene = preload("res://scenes/enemies/bosses/CaveBoss/PoisonShot.tscn")

@export var melee_damage: int = 33
@export var range_damage: int = 33

var boss: CaveBoss

func _ready():
	boss = owner

func attack_melee(_target: Node2D):
	var bodies = boss.get_node("MeleeArea").get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(melee_damage)
			elif body.has_node("HealthComponent"):
				body.get_node("HealthComponent").take_damage(melee_damage)

func shoot(target: Node2D):
	if not target or not projectile_scene:
		return

	var projectile = projectile_scene.instantiate()
	
	if boss.projectile_spawn:
		projectile.global_position = boss.projectile_spawn.global_position
	else:
		projectile.global_position = boss.global_position
	
	var direction = (target.global_position - projectile.global_position).normalized()
	
	projectile.velocity = direction * projectile.speed
	projectile.damage = range_damage
	projectile.rotation = direction.angle()
	
	projectile.add_collision_exception_with(boss)
	get_tree().current_scene.add_child(projectile)
