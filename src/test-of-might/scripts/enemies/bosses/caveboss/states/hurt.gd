# hurt.gd
extends BossState

func enter():
	boss.play_anim("hurt")

	await boss.anim_player.animation_finished
	
	if state_machine.current_state == self:
		state_machine.change_state("idle")

func exit():
	pass
