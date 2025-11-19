#attack
extends BossState


func enter():
	if not boss.anim_player.animation_finished.is_connected(_on_animation_finished):
		boss.anim_player.animation_finished.connect(_on_animation_finished)
	boss.can_attack = false
	if boss.is_player_in_melee_range:
		boss.play_anim("attack1")
	else:
		boss.play_anim("attack2")
	boss.attack_timer.start(boss.attack_cooldown)


func _on_animation_finished():
	var current_anim = boss.anim_player.animation
	if "attack1" in current_anim:
		boss.combat_component.attack_melee(boss.target)
	if "attack2" in current_anim:
		boss.combat_component.shoot(boss.target)
	state_machine.change_state("idle")


func shoot(target: Node):
	pass
	
func exit():
	if boss.anim_player.animation_finished.is_connected(_on_animation_finished):
		boss.anim_player.animation_finished.disconnect(_on_animation_finished)
