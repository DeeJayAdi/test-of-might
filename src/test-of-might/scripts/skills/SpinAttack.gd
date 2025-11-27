@tool
extends BaseSkill
class_name SpinAttack

@export var damage_multiplier: float = 1.2
@export var attack_radius: float = 60.0

func activate(player):
	if not can_use(player):
		return

	print("Aktywowano '%s'!" % skill_name)

	var shape = CircleShape2D.new()
	shape.radius = attack_radius

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape.get_rid()
	params.transform = Transform2D(0, player.global_position)
	params.collision_mask = player.get_collision_layer() # Check against the same layer as the player

	var space = player.get_world_2d().direct_space_state
	var results = space.intersect_shape(params, 32)

	for r in results:
		var collider = r.collider
		if collider and collider != player and collider.is_in_group("enemies") and collider.has_method("take_damage"):
			var damage = int(player.attack_damage * damage_multiplier)
			collider.take_damage(damage)
			print("Zadano %s obrażeń wrogowi %s" % [damage, collider.name])

	super.start_cooldown()
