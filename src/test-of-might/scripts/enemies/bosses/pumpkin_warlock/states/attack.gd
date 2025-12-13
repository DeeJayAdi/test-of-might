# attack
extends BossState

var locked_target_pos: Vector2 

func enter():
	if not boss.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		boss.anim_sprite.animation_finished.connect(_on_animation_finished)
	boss.can_attack = false
	
	#wybieranie pozycji celu przed animacją dla melee
	if boss.is_player_in_melee_range:
		if boss.target:
			locked_target_pos = boss.target.global_position
		else:
			locked_target_pos = boss.global_position + Vector2.RIGHT.rotated(boss.rotation) * 50
		
		boss.play_anim("melee")
		boss.sfx_comp.play_sound_effect("melee")
	else:
		boss.play_anim("cast")
		boss.sfx_comp.play_sound_effect("cast")
	
	boss.attack_timer.start(boss.attack_cooldown)

func _on_animation_finished():
	var current_anim = boss.anim_sprite.animation
	
	if "melee" in current_anim:
		boss.combat_comp.attack_melee(locked_target_pos)
		
	if "cast" in current_anim:
		boss.combat_comp.shoot(boss.target)
		
	state_machine.change_state("idle")

func exit():
	if boss.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		boss.anim_sprite.animation_finished.disconnect(_on_animation_finished)
