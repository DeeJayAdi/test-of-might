@tool
extends BaseSkill
class_name FastSlash

@export var damage_multiplier: float = 0.7
@export var attack_radius: float = 35.0

func activate(player):
	if not can_use(player):
		return

	print("Aktywowano '%s'!" % skill_name)

	# TODO: Add animation player.animated_sprite.play("FastSlash_anim")

	var shape = CircleShape2D.new()
	shape.radius = attack_radius

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape.get_rid()
	params.transform = Transform2D(0, player.global_position)
	params.collision_mask = 4 # Warstwa 3 dla wrogów
	params.collide_with_bodies = true
	params.collide_with_areas = false

	var space = player.get_world_2d().direct_space_state
	var results = space.intersect_shape(params)

	var closest_enemy = null
	var min_dist_sq = INF

	for r in results:
		var collider = r.collider
		if collider.is_in_group("enemies"):
			var dist_sq = player.global_position.distance_squared_to(collider.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest_enemy = collider
	
	if closest_enemy:
		var damage = int(player.stats_comp.attack_damage * damage_multiplier)
		closest_enemy.take_damage(damage)
		print("Zadano %s obrażeń wrogowi %s" % [damage, closest_enemy.name])

	super.start_cooldown(player)
