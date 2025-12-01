extends PlayerState
class_name StateIdle

func enter():
	# W Idle czyścimy prędkość
	player.velocity = Vector2.ZERO

func update(_delta: float):
	# Sprawdzamy input z input_managera
	if player.input_manager.dir != Vector2.ZERO:
		state_manager.change_state("Walk")
		return
	player.animation_manager.play_animation("Idle")

func exit():
	pass
