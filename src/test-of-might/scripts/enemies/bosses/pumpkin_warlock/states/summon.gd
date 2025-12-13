#summon
extends BossState

func enter():
	if not boss.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		boss.anim_sprite.animation_finished.connect(_on_animation_finished)
	boss.can_summon = false
	boss.play_anim("summon_bat")
	boss.summon_timer.start(boss.summon_cooldown)


func _on_animation_finished():
	boss.combat_comp.summon()
	state_machine.change_state("idle")

	
func exit():
	if boss.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		boss.anim_sprite.animation_finished.disconnect(_on_animation_finished)
