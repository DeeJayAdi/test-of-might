#idle
extends BossState

func enter():
	boss.play_anim("idle")
	
func update(delta: float):
	if boss.is_player_detected and boss.can_attack:
		state_machine.change_state("Attack")
	if boss.can_roam and boss.is_player_detected:
		state_machine.change_state("Roam")

func exit():
	pass;
