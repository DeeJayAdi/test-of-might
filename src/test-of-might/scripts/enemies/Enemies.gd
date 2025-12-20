extends CharacterBody2D

signal died

enum State {IDLE, WANDER, CHASE, ATTACK, HURT, DEATH}

var current_state = State.IDLE
var player = null
var last_direction: Vector2 = Vector2.DOWN 
var start_position: Vector2 # NOWE: Żeby mob nie odszedł na drugi koniec mapy

# --- STATYSTYKI ---
@export var detect_radius: int = 200 
@export var speed: int = 100         
@export var wander_speed: int = 50   
@export var max_health: int = 150
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.5
@export var xp_reward: int = 30
@export var crit_chance: float = 0.0 
@export var loot_table: LootTable 

var current_health: int
var can_attack: bool = true
var rng = RandomNumberGenerator.new()

# Zmienna pomocnicza do nazw animacji
var anim_suffix: String = "_down" 

func _ready():
	if SaveManager.is_enemy_dead(self):
		queue_free()
		return
	
	start_position = global_position # NOWE: Zapamiętujemy gdzie się zrespił
	
	$DetectionArea/CollisionShape2D.shape.radius = detect_radius
	add_to_group("enemies")
	rng.randomize()
	current_health = max_health
	$HpBar.max_value = max_health
	$HpBar.value = current_health
	
	if not $AnimatedSprite2D.animation_finished.is_connected(_on_animation_finished):
		$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
		
	# NOWE: Upewniamy się, że WanderTimer działa
	if has_node("WanderTimer"):
		$WanderTimer.start()

func _physics_process(delta: float):
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			if player: current_state = State.CHASE

		# --- NOWY STAN: SPACER ---
		State.WANDER:
			if player:
				current_state = State.CHASE # Jak zobaczy gracza, przerywa spacer
			else:
				# Idź do punktu patrolowego
				if $NavigationAgent2D.is_target_reachable():
					var next_path_pos = $NavigationAgent2D.get_next_path_position()
					var direction = to_local(next_path_pos).normalized()
					velocity = direction * wander_speed # Używamy wolniejszej prędkości
					update_direction(direction)
					
					# Jeśli dotarł do celu, stój
					if $NavigationAgent2D.is_navigation_finished():
						current_state = State.IDLE
				else:
					current_state = State.IDLE
					
			

		State.CHASE:
			if player != null:
				if $AttackRange.get_overlapping_bodies().has(player):
					if can_attack:
						current_state = State.ATTACK
					else:
						velocity = Vector2.ZERO
						update_direction(player.global_position - global_position)
						# Tu usuwamy zmianę na IDLE, żeby nie przerywał walki
						# current_state = State.IDLE 
				else:
					$NavigationAgent2D.target_position = player.global_position
					if $NavigationAgent2D.is_target_reachable():
						var next_path_pos = $NavigationAgent2D.get_next_path_position()
						var direction = to_local(next_path_pos).normalized()
						velocity = direction * speed # Szybka prędkość
						update_direction(direction)
					else:
						velocity = Vector2.ZERO
			else:
				current_state = State.IDLE

		State.ATTACK:
			velocity = Vector2.ZERO
		
		State.HURT:
			velocity = Vector2.ZERO
		
		State.DEATH:
			velocity = Vector2.ZERO

	play_animation()
	move_and_slide()
	handle_audio()

# --- NOWE: LOGIKA LOSOWANIA RUCHU ---
func _on_wander_timer_timeout():
	# Decyzje podejmujemy tylko jak mobek się nudzi (IDLE) lub już spaceruje (WANDER)
	if current_state == State.IDLE or current_state == State.WANDER:
		# Losujemy: 50% szans na stanie, 50% na spacer
		if rng.randi() % 2 == 0:
			current_state = State.IDLE
		else:
			# Wylosuj punkt w pobliżu miejsca startu (nie ucieknie za daleko)
			var random_dir = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
			var wander_distance = rng.randf_range(50, 200) # Idzie max 200px od punktu
			var target_pos = start_position + (random_dir * wander_distance)
			
			$NavigationAgent2D.target_position = target_pos
			current_state = State.WANDER

func update_direction(dir: Vector2):
	if dir.length() == 0:
		return
	last_direction = dir
	
	if abs(dir.x) > abs(dir.y):
		anim_suffix = "_side"
		$AnimatedSprite2D.flip_h = (dir.x < 0)
	else:
		$AnimatedSprite2D.flip_h = false
		if dir.y > 0: anim_suffix = "_down"
		else: anim_suffix = "_up"

func play_animation():
	var anim_name = ""
	
	match current_state:
		State.IDLE:
			anim_name = "idle" + anim_suffix
		
		# --- ROZDZIELENIE WALK I RUN ---
		State.WANDER:
			# Tu używamy animacji WALK (chodzenie)
			anim_name = "walk" + anim_suffix # lub "run" jeśli tak nazwałeś folder, ale wolniej
			
		State.CHASE:
			if velocity.length() > 0:
				# Tu używamy animacji RUN (bieganie)
				anim_name = "run" + anim_suffix 
			else:
				anim_name = "idle" + anim_suffix
		# -------------------------------
				
		State.ATTACK:
			anim_name = "attack" + anim_suffix
		State.HURT:
			anim_name = "hurt" + anim_suffix
		State.DEATH:
			anim_name = "death" + anim_suffix
	
	if $AnimatedSprite2D.sprite_frames.has_animation(anim_name):
		if $AnimatedSprite2D.animation != anim_name:
			$AnimatedSprite2D.play(anim_name)

# --- Reszta funkcji bez zmian ---
func _on_animation_finished():
	if current_state == State.ATTACK:
		if player and $AttackRange.get_overlapping_bodies().has(player):
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
		can_attack = false
		get_tree().create_timer(attack_cooldown).timeout.connect(func(): can_attack = true)
		current_state = State.CHASE
	elif current_state == State.HURT:
		current_state = State.CHASE
	elif current_state == State.DEATH:
		finish_death()

func take_damage(amount: int, stagger: bool = true):
	if current_state == State.DEATH: return
	current_health -= amount
	$HpBar.value = current_health
	if $sfxHurt and not $sfxHurt.playing: $sfxHurt.play()
	if current_health <= 0: die()
	elif stagger: current_state = State.HURT

func die():
	current_state = State.DEATH
	died.emit()
	$HpBar.visible = false
	if $sfxDie: $sfxDie.play()

func finish_death():
	if player and player.stats_comp.has_method("add_xp"): player.stats_comp.add_xp(xp_reward)
	DropSpawner.spawn_loot(loot_table, global_position)
	SaveManager.register_enemy_death(self)

	var current_enemy_path = str(self.get_path())
	var graveyard_vampires = [
		"/root/Graveyard/Vampires_Bosses/VampireLvl3",
		"/root/Graveyard/Vampires_Bosses/VampireLvl1-1",
		"/root/Graveyard/Vampires_Bosses/VampireLvl1-2",
		"/root/Graveyard/Vampires_Bosses/VampireLvl2-1",
		"/root/Graveyard/Vampires_Bosses/VampireLvl2-2"
	]

	if current_enemy_path in graveyard_vampires:
		if SaveManager.are_graveyard_vampires_defeated() and not SaveManager.graveyard_vampires_defeat_notified:
			SaveManager.graveyard_vampires_defeat_notified = true
			NotificationManager.show_notification("New map unlocked: Level 4!")
			
			var global = get_node("/root/Global")
			global.boss_killed.emit()

	if has_node("/root/PersistentMusic"): PersistentMusic.switch_to_exploration()
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		if has_node("/root/PersistentMusic"): PersistentMusic.switch_to_battle()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		if has_node("/root/PersistentMusic"): PersistentMusic.switch_to_exploration()
		
func handle_audio():
	# Jeśli mob się rusza (ma prędkość) i nie jest martwy
	if velocity.length() > 0 and current_state != State.DEATH:
		# Sprawdzamy "if not playing", żeby nie resetować dźwięku co klatkę
		if not $sfxWalk.playing:
			$sfxWalk.pitch_scale = rng.randf_range(0.9, 1.1) # Lekka losowość tonu
			$sfxWalk.play()
	else:
		# Jeśli stoi w miejscu, zatrzymaj dźwięk
		if $sfxWalk.playing:
			$sfxWalk.stop()
