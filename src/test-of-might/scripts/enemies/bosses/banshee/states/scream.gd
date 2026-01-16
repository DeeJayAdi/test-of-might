# attack
extends BossState

var locked_target_pos: Vector2 

func enter():
	if not boss.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		boss.anim_sprite.animation_finished.connect(_on_animation_finished)
	boss.can_scream = false

		
	boss.play_anim("scream")
	boss.sfx_comp.play_sound_effect("Scream")
	boss.scream_timer.start(boss.scream_cooldown)
	

func _on_animation_finished():
	var current_anim = boss.anim_sprite.animation
	
	if "scream" in current_anim:
		boss.combat_comp.scream()
		
	state_machine.change_state("idle")

func exit():
	if boss.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		boss.anim_sprite.animation_finished.disconnect(_on_animation_finished)
