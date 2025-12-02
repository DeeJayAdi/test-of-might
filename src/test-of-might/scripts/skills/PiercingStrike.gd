@tool
extends BaseSkill
class_name PiercingStrike

@export var damage_multiplier: float = 1.5
@export var strike_length: float = 150.0
@export var strike_width: float = 20.0

func activate(player):
	if not can_use(player):
		return

	print("Aktywowano '%s'!" % skill_name)

	# TODO: Add animation player.animated_sprite.play("PiercingStrike_anim")

	var dir = player.get_global_mouse_position() - player.global_position
	if dir.length() == 0:
		dir = Vector2.DOWN # Domyślny kierunek, jeśli myszka jest na graczu

	var shape = RectangleShape2D.new()
	shape.extents = Vector2(strike_length / 2, strike_width / 2)

	var transform = Transform2D(dir.angle(), player.global_position + dir.normalized() * strike_length / 2)

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape.get_rid()
	params.transform = transform
	params.collision_mask = 4 # Warstwa 3 dla wrogów

	var space = player.get_world_2d().direct_space_state
	var results = space.intersect_shape(params, 32)

	for r in results:
		var collider = r.collider
		if collider and collider != player and collider.is_in_group("enemies") and collider.has_method("take_damage"):
			var damage = int(player.attack_damage * damage_multiplier)
			collider.take_damage(damage)
			print("Zadano %s obrażeń wrogowi %s" % [damage, collider.name])

	super.start_cooldown()
