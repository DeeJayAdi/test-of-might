extends BossState

func enter():
	boss.velocity = Vector2.ZERO
	boss.play_anim("idle")
	
func update(delta: float):
	boss.play_anim("idle")
	
	if not boss.is_player_detected:
		return

	if boss.is_player_in_melee_range and boss.can_attack:
		state_machine.change_state("Attack")
	
	elif not boss.is_player_in_melee_range and boss.can_scream:
		state_machine.change_state("Scream")
		
	elif not boss.is_player_in_melee_range:
		state_machine.change_state("Walk")

func exit():
	pass