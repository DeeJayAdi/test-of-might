class_name Hurt extends PlayerState

func enter():
	if not player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.connect_animation_finished(self._on_animation_finished, 0)
	player.velocity = Vector2.ZERO
	player.animation_manager.play_animation("Hurt")
	

func update(_delta: float):
	player.velocity = player.velocity.normalized() * 0.5 * player.stats_comp.speed

func exit():
	if player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.disconnect_animation_finished(self._on_animation_finished)


func _on_animation_finished():
	if player.animation_manager.animated_sprite.animation.begins_with("Hurt"):
		state_manager.change_state("Idle")
