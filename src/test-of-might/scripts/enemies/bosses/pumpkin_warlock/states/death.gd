extends BossState

func enter():

	boss.attack_timer.stop()
	boss.summon_timer.stop()
	boss.health_comp.is_invincible = true
	boss.set_collision_layer_value(1, false)
	boss.set_collision_mask_value(1, false)
	boss.play_anim("death")
	boss.sfx_comp.play_sound_effect("death")
	await boss.anim_sprite.animation_finished
	await get_tree().create_timer(2.0).timeout
	
	spawn_drop()
	boss.queue_free()

func update(_delta):
	pass

func exit():
	pass
	
func spawn_drop():
	#logika dropu itemu z bossa
	if boss.get("loot_table"):
		DropSpawner.spawn_loot(boss.loot_table, boss.global_position)
	else:
		print_debug("Warning: Boss has no loot_table assigned!")
