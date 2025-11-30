extends PlayerState
class_name StateAttack

func enter():
	if not player.animation_manager.is_animation_finished_connected(self._on_animation_finished):
		player.animation_manager.connect_animation_finished(self._on_animation_finished, 0)
	# check velocity
	if player.velocity != Vector2.ZERO and Input.is_action_pressed("sprint"):
		player.animation_manager.play_animation("Attack_Run")
	elif player.velocity != Vector2.ZERO:
		player.animation_manager.play_animation("Attack_Walk")
	else:
		player.animation_manager.play_animation("Attack")

func update(delta: float):
	pass 
func exit():
	player.animation_manager.disconnect_animation_finished(self._on_animation_finished)

func _on_animation_finished() -> void:
	# Upewnij się, że sprawdzasz właściwą nazwę animacji (w AnimationManager dodajesz suffixy _Right itp.)
	if player.animation_manager.animated_sprite.animation.begins_with("Attack"):
		state_manager.change_state("Idle")
