extends BossState

func enter():

	boss.attack_timer.stop()
	boss.roam_timer.stop()
	boss.hide_timer.stop()
	boss.health_component.is_invincible = true

	boss.set_collision_layer_value(1, false)
	boss.set_collision_mask_value(1, false)
	
	boss.play_anim("death")
	boss.sound_effects_component.play_sound_effect("death")

	await boss.anim_player.animation_finished
	
	await get_tree().create_timer(2.0).timeout
	
	boss.queue_free()

func update(_delta):
	pass

func exit():
	pass
