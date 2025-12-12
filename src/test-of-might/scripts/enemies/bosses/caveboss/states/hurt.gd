# hurt.gd
extends BossState

func enter():
	if boss.stagger:
		boss.play_anim("hurt")
		boss.sound_effects_component.play_sound_effect("Hurt")

		await boss.anim_player.animation_finished
	
	if state_machine.current_state == self:
		state_machine.change_state("idle")

func exit():
	pass
