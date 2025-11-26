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
	
	spawn_drop()
	boss.queue_free()

func update(_delta):
	pass

func exit():
	pass
	
func spawn_drop():
	#logika dropu itemu z bossa
	if boss.pickable_item_scene == null or boss.item_to_drop == null:
		return
	var pickable = boss.pickable_item_scene.instantiate() as PickableItem
	pickable.setup(boss.item_to_drop)
	pickable.global_position = boss.global_position
	
	#dodanie itemu do mapy
	boss.get_parent().call_deferred("add_child", pickable)
