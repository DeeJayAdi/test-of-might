extends CharacterBody2D
enum State {IDLE, WALK, ATTACK}

var current_state = State.IDLE

func _physics_process(delta: float):
	match current_state:
		State.IDLE:
			$AnimatedSprite2D.play('idle')
			velocity = Vector2.ZERO
	move_and_slide()
