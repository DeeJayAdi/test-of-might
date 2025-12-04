extends CharacterBody2D

enum State {IDLE, CHASE, ATTACK, HURT, DEATH}

var current_state = State.IDLE
var player = null
@export var detect_radius: int = 300
@export var speed: int = 150
@export var max_health: int = 200
var can_attack: bool = true
@export var attack_cooldown: float = 1.0
@export var crit_chance: float = 0.1  
@export var crit_multiplier: float = 2.0
@export var attack_damage: int = 10
@export var xp_reward: int = 50
@export var pickable_item_scene: PackedScene 
@export var item_to_drop: ItemData
var current_health: int
var rng = RandomNumberGenerator.new()
var current_attack_animation: String = "attack1"


func _ready():
	$DetectionArea/CollisionShape2D.shape.radius = detect_radius
	# Dodajemy do grupy 'enemies' aby ułatwić selekcję
	add_to_group("enemies")
	rng.randomize()
	current_health = max_health
	$HpBar.max_value = max_health
	$HpBar.value = current_health

func reset_attack_cooldown():
	can_attack = true

func _physics_process(delta: float):
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			# Jeśli stoimy, ale gracz jest wykryty, zacznij go gonić
			if player and $DetectionArea.get_overlapping_bodies().has(player):
				current_state = State.CHASE

		State.CHASE:
			if player != null:
				# Sprawdź, czy gracz jest w zasięgu ataku
				if $AttackRange.get_overlapping_bodies().has(player):
					# --- Jest w zasięgu ---
					if can_attack:
						# 1. Może atakować -> ATAKUJ
						current_state = State.ATTACK
						
						# Rzut na krytyka
						if rng.randf() < crit_chance:
							# Użyj animacji krytycznej
							current_attack_animation = "attack2" 
						else:
							# Użyj animacji normalnej
							current_attack_animation = "attack1"

						velocity = Vector2.ZERO
						var dir = (player.global_position - global_position).normalized()
						if dir.x > 0: $AnimatedSprite2D.flip_h = false
						elif dir.x < 0: $AnimatedSprite2D.flip_h = true
					else:
						current_state = State.IDLE
						velocity = Vector2.ZERO
				else:
					# --- Jest poza zasięgiem -> GOŃ ---
					$NavigationAgent2D.target_position = player.global_position
					if $NavigationAgent2D.is_target_reachable():
						var direction = to_local($NavigationAgent2D.get_next_path_position()).normalized()
						velocity = direction * speed
						if direction.x > 0:
							$AnimatedSprite2D.flip_h = false
						elif direction.x < 0:
							$AnimatedSprite2D.flip_h = true
					else:
						velocity = Vector2.ZERO
						current_state = State.IDLE
			else:
				current_state = State.IDLE

		State.ATTACK:
			# Ten stan tylko odtwarza animację. Logika jest w _on_animation_finished
			velocity = Vector2.ZERO
		
		State.HURT:
			velocity = Vector2.ZERO
		
		State.DEATH:
			velocity = Vector2.ZERO
	play_animation()
	move_and_slide()



func play_animation():
	match current_state:
		State.IDLE:
			$AnimatedSprite2D.play("idle")
		State.CHASE:
			$AnimatedSprite2D.play("walk")
		State.ATTACK:
			# --- POPRAWKA TUTAJ ---
			# Musisz odtworzyć animację, którą wylosowaliśmy (attack1 lub attack2)
			$AnimatedSprite2D.play(current_attack_animation)
			# --- KONIEC POPRAWKI ---
		State.HURT:
			$AnimatedSprite2D.play("hurt")
		State.DEATH:
			$AnimatedSprite2D.play("die")



func _on_DetectionArea_body_entered(body):
	if current_state == State.DEATH:
		return
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE


func _on_DetectionArea_body_exited(body):
	if current_state == State.DEATH:
		return
	if body.is_in_group("player"):
		player = null
		current_state = State.IDLE


func _on_AttackRange_body_entered(body):
	if current_state == State.DEATH or current_state == State.ATTACK:	
		return
	if body == player and can_attack:
		current_state = State.ATTACK



func take_damage(amount: int):
	if current_state == State.DEATH:
		return
		
	# Prosta obsługa otrzymania obrażeń
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	print("Skeleton otrzymał obrażenia:", amount, " pozostało:", current_health)

	if current_health <= 0:
		current_state = State.DEATH
		if not $sfxDie.playing:
			$sfxDie.volume_db = rng.randf_range(-10.0, 0.0)
			$sfxDie.pitch_scale = rng.randf_range(0.9, 1.1)
			$sfxDie.play()
	else:
		current_state = State.HURT
		if not $sfxHurt.playing:
			$sfxHurt.volume_db = rng.randf_range(-10.0, 0.0)
			$sfxHurt.pitch_scale = rng.randf_range(0.9, 1.1)
			$sfxHurt.play()
	$HpBar.value = current_health

func _on_animation_finished():
	if current_state == State.ATTACK:
		# Sprawdzamy 'can_attack', aby upewnić się, że to "prawdziwy"
		# atak, a nie wywołanie z zapętlonej animacji.
		if can_attack:
			# 1. Rozpocznij cooldown
			can_attack = false
			get_tree().create_timer(attack_cooldown).timeout.connect(reset_attack_cooldown)

			# 2. Zadaj obrażenia (Twoja logika)
			var overlapping = $AttackRange.get_overlapping_bodies()
			if player and overlapping.has(player):
				if player.has_method("take_damage"):
					
					# Oblicz obrażenia (z uwzględnieniem krytyka)
					var damage_to_deal = attack_damage
					# Sprawdź, jaka animacja właśnie się skończyła
					if current_attack_animation == "attack2":
						damage_to_deal = int(attack_damage * crit_multiplier)
						print("Szkielet zadał cios krytyczny!")
					
					player.take_damage(damage_to_deal)

		# 3. NATYCHMIAST zmień stan. To zatrzyma pętlę animacji.
		# Maszyna stanów w _physics_process zdecyduje, co dalej.
		current_state = State.CHASE

	
	elif current_state == State.HURT:
		if player and $DetectionArea.get_overlapping_bodies().has(player):
			current_state = State.CHASE
		else:
			current_state = State.IDLE

	elif current_state == State.DEATH:
		# Przyznaj XP graczowi, jeśli istnieje
		if player and player.stats_comp.has_method("add_xp"):
			player.stats_comp.add_xp(xp_reward)
		spawn_drop()
		queue_free()


func _on_frame_changed():
	var frame = $AnimatedSprite2D.frame

	match current_state:
		State.CHASE:
			if not $sfxWalk.playing:
				$sfxWalk.volume_db = rng.randf_range(-10.0, 0.0)
				$sfxWalk.pitch_scale = rng.randf_range(0.9, 1.1)
				$sfxWalk.play()
		State.HURT:
			$sfxWalk.stop()
		State.DEATH:
			$sfxWalk.stop()
			
func spawn_drop():
	if pickable_item_scene == null or item_to_drop == null:
		return
	var pickable = pickable_item_scene.instantiate() as PickableItem
	pickable.setup(item_to_drop)
	pickable.global_position = global_position
	
	#dodanie itemu do mapy
	get_parent().call_deferred("add_child", pickable)
