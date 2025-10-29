extends CharacterBody2D
enum State {IDLE, CHASE, ATTACK}

var current_state = State.IDLE
var player = null
@export var detect_radius: int = 60
@export var speed: int = 100

func _ready():
	$DetectionArea/CollisionShape2D.shape.radius = detect_radius

func _physics_process(delta: float):
	match current_state:
		State.IDLE:
			$AnimatedSprite2D.play("idle")
			velocity = Vector2.ZERO
		State.CHASE:
			if player != null:
				$AnimatedSprite2D.play("walk")
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * speed
				if direction.x > 0:
					$AnimatedSprite2D.flip_h = false
				elif direction.x < 0:
					$AnimatedSprite2D.flip_h = true
			else:
				current_state = State.IDLE

		State.ATTACK:
			$AnimatedSprite2D.play("attack1")
			var direction = (player.global_position - global_position).normalized()
			if direction.x > 0:
				$AnimatedSprite2D.flip_h = false
			elif direction.x < 0:
				$AnimatedSprite2D.flip_h = true
			velocity = Vector2.ZERO
			# logika zadawania dmg itp
			
			
			

	move_and_slide()


func _on_DetectionArea_body_entered(body):
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE
		
func _on_DetectionArea_body_exited(body):
	if body.is_in_group("player"):
		player = null
		current_state = State.IDLE
		
func _on_AttackRange_body_entered(body):
	if body == player:
		current_state = State.ATTACK
