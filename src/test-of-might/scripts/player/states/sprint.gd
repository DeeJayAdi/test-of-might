extends PlayerState
class_name Sprint

func enter() -> void:
	player.animation_manager.play_animation("Run")

func update(_delta: float) -> void:
	var dir = player.input_manager.dir
	
	if dir == Vector2.ZERO:
		state_manager.change_state("Idle")
		return
		
	if not Input.is_action_pressed("sprint"):
		state_manager.change_state("Walk")
		return

	# --- NOWOŚĆ: Odśwież animację ---
	player.animation_manager.play_animation("Run")


func exit() -> void:
	pass
