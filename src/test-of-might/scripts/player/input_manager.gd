class_name InputManager extends Node2D

var player: Player = null
var dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	await owner.ready
	player = get_parent() as Player

func process_input(delta: float) -> void:
	dir = Input.get_vector("left", "right", "up", "down")
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		if Input.is_action_pressed("sprint"):
			player.velocity = dir * player.stats_comp.speed * player.stats_comp.run_multiplier
		else:
			player.velocity = dir * player.stats_comp.speed
	else:
		player.velocity = Vector2.ZERO

	if player.state_manager.get_current_state_name() == "Hurt":
		player.velocity *= 0.5

	if Input.is_action_just_pressed("attack"):
		player.combat_comp.perform_attack()

	elif Input.is_action_just_pressed("heavy_attack"):
		player.combat_comp.perform_heavy_attack()

	if Input.is_action_just_pressed("Interaction"):
		if player.interactables_in_range.is_empty():
			return
		var closest = player.get_closest_interactable()
		if closest:
			closest.interact()

	if Input.is_action_pressed("use_skill"):
		if player.stats_comp.active_skill:
			player.stats_comp.active_skill.activate(player)
		else:
			print("Brak przypisanej umiejętności!")

	if Input.is_action_just_pressed("swap_weapon"):
		player.swap_weapons()
	if Input.is_action_pressed("skill_1") and player.stats_comp.skills.skill_1:
		if player.stats_comp.skills.skill_1.can_use(player):
			NotificationManager.show_notification("Used skill: %s" % player.stats_comp.skills.skill_1.skill_name, 2.0)
			player.stats_comp.skills.skill_1.activate(player)
	if Input.is_action_pressed("skill_2") and player.stats_comp.skills.skill_2:
		if player.stats_comp.skills.skill_2.can_use(player):
			NotificationManager.show_notification("Used skill: %s" % player.stats_comp.skills.skill_2.skill_name, 2.0)
			player.stats_comp.skills.skill_2.activate(player)
	if Input.is_action_pressed("skill_3") and player.stats_comp.skills.skill_3:
		if player.stats_comp.skills.skill_3.can_use(player):
			NotificationManager.show_notification("Used skill: %s" % player.stats_comp.skills.skill_3.skill_name, 2.0)
			player.stats_comp.skills.skill_3.activate(player)
	if Input.is_action_pressed("skill_4") and player.stats_comp.skills.skill_4:
		if player.stats_comp.skills.skill_4.can_use(player):
			NotificationManager.show_notification("Used skill: %s" % player.stats_comp.skills.skill_4.skill_name, 2.0)
			player.stats_comp.skills.skill_4.activate(player)
		
