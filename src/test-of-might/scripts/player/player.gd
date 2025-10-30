extends CharacterBody2D

signal health_changed(current_health, max_health)
signal died

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEATH }

@export var max_health: int = 100
@export var speed: float = 200.0
@export var run_multiplier: float = 1.5 

var current_health: int
var current_state: State = State.IDLE

var facing_direction: String = "Down"

var is_moving: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float):
	if current_state == State.DEATH:
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation()
		return
		
	if current_state == State.HURT:
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation()
		return

	get_input_and_update_state()
	
	play_animation()

	move_and_slide()


func get_input_and_update_state():
	# Sprawdź atak
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK

	# Pobierz kierunek ruchu
	var dir = Input.get_vector("left", "right", "up", "down")

	if dir != Vector2.ZERO:
		is_moving = true
		# Aktualizuj kierunek patrzenia
		update_facing_direction(dir)
		
		# Ustaw prędkość
		if Input.is_action_pressed("sprint"):
			velocity = dir.normalized() * speed * run_multiplier
			# Ustaw stan na RUN tylko jeśli *nie* jesteśmy w trakcie ataku
			if current_state != State.ATTACK:
				current_state = State.RUN
		else:
			velocity = dir.normalized() * speed
			if current_state != State.ATTACK:
				current_state = State.WALK
	else:
		# Brak ruchu
		is_moving = false
		velocity = Vector2.ZERO
		if current_state != State.ATTACK:
			current_state = State.IDLE

# Funkcja pomocnicza do aktualizacji 'facing_direction' na podstawie wektora
func update_facing_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			facing_direction = "Right"
		else:
			facing_direction = "Left"
	else:
		if dir.y > 0:
			facing_direction = "Down"
		else:
			facing_direction = "Up"

# Główna funkcja logiki animacji
func play_animation():
	var anim_name_prefix: String = "" # np. "Walk", "Idle", "Attack_Run"
	
	match current_state:
		State.IDLE:
			anim_name_prefix = "Idle"
		State.WALK:
			anim_name_prefix = "Walk"
		State.RUN:
			anim_name_prefix = "Run"
		State.ATTACK:
			# Obsługa dwóch różnych animacji ataku
			if is_moving:
				anim_name_prefix = "Attack_Run"
			else:
				anim_name_prefix = "Attack"
		State.HURT:
			anim_name_prefix = "Hurt"
		State.DEATH:
			anim_name_prefix = "Death"
			
	# łączenie prefiksu z kierunkiem, np. "Walk_Up"
	var final_anim_name = anim_name_prefix + "_" + facing_direction
	var current_anim_name = animated_sprite.animation
	
	if current_anim_name != final_anim_name:
		
		if not animated_sprite.sprite_frames.has_animation(final_anim_name):
			print("BŁĄD: Nie znaleziono animacji: ", final_anim_name)
			return
			#kontynuacja animacji od tej samej pozycji dla animacji ataku
		if current_anim_name.begins_with("Attack") and final_anim_name.begins_with("Attack"):
			
			var current_frame_index = animated_sprite.frame
			var current_frame_count = animated_sprite.sprite_frames.get_frame_count(current_anim_name)
			
			if current_frame_count > 0:
				var progress_percent = float(current_frame_index) / float(current_frame_count)
			
				var new_frame_count = animated_sprite.sprite_frames.get_frame_count(final_anim_name)
				var new_frame_index = int(progress_percent * new_frame_count)
				animated_sprite.play(final_anim_name)
				animated_sprite.frame = new_frame_index
			
			else:
				animated_sprite.play(final_anim_name)
		
		else:
			#pozostałe animacje zaczynają się od początku
			animated_sprite.play(final_anim_name)
		

func _on_animation_finished():
	if current_state == State.HURT:
		current_state = State.IDLE
		
	if current_state == State.ATTACK:
		if is_moving:
			if Input.is_action_pressed("sprint"):
				current_state = State.RUN
			else:
				current_state = State.WALK
		else:
			current_state = State.IDLE
			
	if current_state == State.DEATH:
		queue_free()


func take_damage(amount: int):
	if current_state == State.DEATH:
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	print("Otrzymano obrażenia, aktualne ZD: ", current_health)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()
	else:
		current_state = State.HURT

func heal(amount: int):
	if current_state == State.DEATH or current_health == max_health:
		return
		
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func die():
	if current_state == State.DEATH:
		return
		
	print("Gracz umarł!")
	current_state = State.DEATH
	died.emit()
	
