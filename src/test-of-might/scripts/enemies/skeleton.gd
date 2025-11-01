extends CharacterBody2D
enum State {IDLE, CHASE, ATTACK}

var current_state = State.IDLE
var player = null
@export var detect_radius: int = 300
@export var speed: int = 150
@export var max_health: int = 50
@export var attack_damage: int = 10
var current_health: int

func _ready():
	$DetectionArea/CollisionShape2D.shape.radius = detect_radius

	# Dodajemy do grupy 'enemies' aby ułatwić selekcję
	add_to_group("enemies")

	current_health = max_health

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
			# Atak: na koniec animacji sprawdzamy, czy gracz jest w zasięgu i zadajemy obrażenia
			
			
			

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


func take_damage(amount: int):
	# Prost aobsługa otrzymania obrażeń
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	print("Skeleton otrzymał obrażenia:", amount, " pozostało:", current_health)

	if current_health <= 0:
		# zagraj animację śmierci
		$AnimatedSprite2D.play("die")
		# na koniec animacji zostanie usunięty (w _on_animation_finished)
		current_state = State.IDLE
	else:
		# zagraj animację obrażeń i zatrzymaj się
		$AnimatedSprite2D.play("hurt")
		current_state = State.IDLE
		
func _on_animation_finished():
	# Jeśli animacja ataku się skończyła, zadaj obrażenia jeśli cel jest w zasięgu
	if current_state == State.ATTACK:
		var overlapping = $AttackRange.get_overlapping_bodies()
		if player and overlapping.has(player):
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
		# Po ataku przejdź z powrotem do ścigania jeśli cel wciąż jest widoczny
		if player and $DetectionArea.get_overlapping_bodies().has(player):
			current_state = State.CHASE
		else:
			current_state = State.IDLE

	# Obsługa końca animacji przy obrażeniach/śmierci
	if $AnimatedSprite2D.animation == "die":
		queue_free()
