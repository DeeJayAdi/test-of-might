extends PlayerState
class_name Walk

func enter() -> void:
	player.animation_manager.play_animation("Walk")

func update(_delta: float) -> void:
	var dir = player.input_manager.dir
	
	if dir == Vector2.ZERO:
		state_manager.change_state("Idle")
		return
		
	if Input.is_action_pressed("sprint"):
		state_manager.change_state("Sprint")
		return

	player.animation_manager.play_animation("Walk")


func exit() -> void:
	pass
