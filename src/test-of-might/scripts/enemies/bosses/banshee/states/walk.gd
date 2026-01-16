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

	var nav_agent = boss.get_node("NavigationAgent2D")
	nav_agent.target_position = boss.target.position
	
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - boss.position).normalized()
	boss.velocity = dir * boss.walk_speed
	boss.move_and_slide()
	

func exit():
	pass