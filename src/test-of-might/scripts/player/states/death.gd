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
		get_tree().change_scene_to_file("res://scenes/death_screen/death_screen.tscn")

func exit():
	if player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.disconnect_animation_finished(self._on_animation_finished)
