#idle
extends BossState

func enter():
	boss.velocity = Vector2.ZERO
	boss.play_anim("idle")
	
func update(delta: float):
	boss.play_anim("idle")
	if boss.is_player_detected and boss.can_attack:
		state_machine.change_state("Attack")
	elif boss.is_player_detected and !boss.is_player_in_melee_range:
		state_machine.change_state("Walk")

func exit():
	pass;
