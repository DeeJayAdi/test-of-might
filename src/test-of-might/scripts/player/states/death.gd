class_name StateDeath extends PlayerState

var death_screen_scene = preload("res://scenes/death_screen/death_screen.tscn")

func enter():
	if not player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.connect_animation_finished(self._on_animation_finished, 0)
	player.velocity = Vector2.ZERO
	player.animation_manager.play_animation("Death")

func update(_delta: float):
	pass

func _on_animation_finished():
	if player.animation_manager.animated_sprite.animation.begins_with("Death"):
		var death_screen = death_screen_scene.instantiate()
		get_tree().root.add_child(death_screen)
		get_tree().paused = true
		
		# Disable processing before queue_free to prevent the error
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.queue_free()

func exit():
	if player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.disconnect_animation_finished(self._on_animation_finished)
