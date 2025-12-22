# hurt.gd
extends BossState

func enter():
	if boss.stagger:
		boss.play_anim("hit")
		boss.sfx_comp.play_sound_effect("Hurt")

		await boss.anim_sprite.animation_finished
	
	if state_machine.current_state == self:
		state_machine.change_state("idle")

func exit():
	pass
