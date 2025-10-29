extends CharacterBody2D
enum State {IDLE, CHASE, ATTACK}

var current_state = State.IDLE
var player = null
@export var detect_radius: int = 300
@export var speed: int = 150

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
				var facing_direction = (player.global_position - global_position).normalized()
				$NavigationAgent2D.target_position = player.global_position
				var direction = to_local($NavigationAgent2D.get_next_path_position()).normalized()
				velocity = direction * speed
				if facing_direction.x > 0:
					$AnimatedSprite2D.flip_h = false
				elif facing_direction.x < 0:
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
		
func _on_animation_finished():
	if current_state == State.ATTACK:
		if $AttackRange.get_overlapping_bodies().has(player):
				current_state = State.ATTACK
		else:
			current_state = State.CHASE
