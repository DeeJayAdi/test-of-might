class_name StateDeath extends PlayerState



func enter():
	if not player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.connect_animation_finished(self._on_animation_finished, 0)
	player.velocity = Vector2.ZERO
	player.animation_manager.play_animation("Death")

func update(_delta: float):
	pass

func _on_animation_finished():
	if player.animation_manager.animated_sprite.animation.begins_with("Death"):
		if player.ui_manager and player.ui_manager.has_method("show_game_over_screen"):
			player.ui_manager.show_game_over_screen()
			
		player.queue_free()

func exit():
	if player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.disconnect_animation_finished(self._on_animation_finished)
