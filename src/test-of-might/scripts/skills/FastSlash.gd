@tool
extends BaseSkill
class_name FastSlash

@export var damage_multiplier: float = 0.7
@export var attack_radius: float = 35.0

func activate(player):
	if not can_use(player):
		return

	print("Aktywowano '%s'!" % skill_name)

	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var min_dist_sq = INF

	for enemy in enemies:
		if player.global_position.distance_squared_to(enemy.global_position) < min_dist_sq:
			closest_enemy = enemy
			min_dist_sq = player.global_position.distance_squared_to(enemy.global_position)

	if closest_enemy and player.global_position.distance_to(closest_enemy.global_position) < attack_radius:
		var damage = int(player.attack_damage * damage_multiplier)
		closest_enemy.take_damage(damage)
		print("Zadano %s obrażeń wrogowi %s" % [damage, closest_enemy.name])

	super.start_cooldown()
