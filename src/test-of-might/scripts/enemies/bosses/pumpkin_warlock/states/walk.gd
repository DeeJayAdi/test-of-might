extends BossState

func enter():
	boss.play_anim("walk")

func update(delta: float):
	if not boss.target:
		state_machine.change_state("Idle")
		return

	boss.play_anim("walk")
	
	if boss.is_player_in_melee_range:
		boss.velocity = Vector2.ZERO
		if boss.can_attack:
			state_machine.change_state("Attack")
		else:
			state_machine.change_state("Idle")
		return

	# var dir = (boss.target.global_position - boss.global_position).normalized()
	# boss.velocity = dir * boss.walk_speed
	# boss.move_and_slide()
	#use nav agent to move towards player
	var nav_agent = boss.get_node("NavigationAgent2D")
	nav_agent.target_position = boss.target.position
	boss.velocity = nav_agent.get_next_path_position() - boss.position
	boss.velocity = boss.velocity.normalized() * boss.walk_speed
	boss.move_and_slide()
	
	
	if boss.can_attack and boss.is_player_detected:
		state_machine.change_state("Attack")

	elif boss.can_summon and boss.is_player_detected:
		state_machine.change_state("Summon")

func exit():
	pass
