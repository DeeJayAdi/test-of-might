# roam.gd
extends BossState

func enter():
	boss.can_roam = false
	perform_roam_sequence()

func perform_roam_sequence():
	boss.health_component.is_invincible = true
	boss.play_anim("hide")
	boss.sound_effects_component.play_sound_effect("Dig")
	
	await boss.anim_player.animation_finished
	
	boss.visible = false
	boss.set_collision_layer_value(1, false)
	boss.set_collision_mask_value(1, false)
	
	await get_tree().create_timer(boss.hide_time).timeout
	
	boss.global_position = boss.get_random_roam_position()
	
	boss.visible = true
	boss.play_anim("comeout")
	boss.sound_effects_component.play_sound_effect("Dig")
	
	await boss.anim_player.animation_finished
	
	boss.set_collision_layer_value(1, true)
	boss.set_collision_mask_value(1, true)
	boss.health_component.is_invincible = false
	boss.roam_timer.start(boss.roam_cooldown)
	
	state_machine.change_state("idle")

func exit():
	boss.visible = true
	boss.set_collision_layer_value(1, true)
	boss.health_component.is_invincible = false
