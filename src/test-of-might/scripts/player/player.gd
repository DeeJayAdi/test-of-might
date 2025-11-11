extends CharacterBody2D
@onready var health_bar: TextureProgressBar = $UI/HP/Zdrowie/TextureProgressBar
@onready var inventory_scene = preload("res://scenes/ui/inventory.tscn")
@onready var ui_layer: CanvasLayer = $UI
var inventory_instance: Control = null
var inventory_open: bool = false
var dark_overlay: ColorRect = null


signal health_changed(current_health, max_health)
signal died

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEATH }

@export var max_health: int = 100
@export var speed: float = 200.0
@export var run_multiplier: float = 1.5 
@export var attack_radius: float = 30.0
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.9
@export var crit_chance: float = 0.15  # 15% szansy
@export var crit_multiplier: float = 2.0
@export var heavy_attack_damage: int = 75
@export var heavy_attack_radius: float = 45.0
@export var heavy_attack_cooldown: float = 1.2
@export var settings_scene_path: String = "res://scenes/menu/settings.tscn"
#@export var combat_style_mouse_based: bool = true

var attack_locked_direction: String = ""
var attack_locked_direction_mouse: String = ""
var can_attack: bool = true
var current_health: int
var current_state: State = State.IDLE
var _step = true
var rng = RandomNumberGenerator.new()
var facing_direction: String = "Down"
var interactables_in_range = []
var is_moving: bool = false
var settings_instance: Node = null
var settings_open: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var walls_map: Node = null

func _ready():
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	

	if get_parent() and get_parent().has_node("Walls_Floors"):
		walls_map = get_parent().get_node("Walls_Floors")
	elif get_tree().get_root().has_node("Walls_Floors"):
		walls_map = get_tree().get_root().get_node("Walls_Floors")
		
	health_changed.connect(_on_health_changed)
		
func _on_health_changed(new_health, max_health_value):
	# Ustawia aktualną wartość paska na nowe zdrowie gracza
	health_bar.value = new_health
	
	# Na wypadek, gdyby maksymalne zdrowie też się zmieniło
	health_bar.max_value = max_health_value

func _physics_process(_delta: float):
	if inventory_open:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if current_state == State.DEATH:
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation()
		return
		
	if current_state == State.HURT:
		# Allow limited movement while hurt
		var dir = Input.get_vector("left", "right", "up", "down")
		if dir != Vector2.ZERO:
			velocity = dir.normalized() * speed * 0.5  # 50% speed when hurt
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		play_animation()
		return

	get_input_and_update_state()
	
	play_animation()

	# Jeśli mamy referencję do TileMapLayer (Walls_Floors) — wykonaj prostą blokadę ruchu
	if walls_map and walls_map.has_method("world_to_map"):
		var next_pos = global_position + velocity * get_physics_process_delta_time()
		var cell = walls_map.world_to_map(next_pos)
		# get_cellv może zwracać -1 gdy brak kafelka
		var tile = walls_map.get_cellv(cell)
		if tile != -1:
			# Kafelek istnieje -> zablokuj ruch
			velocity = Vector2.ZERO

	move_and_slide()


func get_input_and_update_state():

	if inventory_open or settings_open:
		velocity = Vector2.ZERO
		current_state = State.IDLE
		return
	
	var dir = Input.get_vector("left", "right", "up", "down")

	if dir != Vector2.ZERO:
		is_moving = true
		if not PreviousScene.combat_style_mouse_based:
			update_facing_direction(dir)
	else:
		is_moving = false

	# --- NEW: update facing to mouse if mouse-based combat ---
	if PreviousScene.combat_style_mouse_based and current_state != State.ATTACK:
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		if abs(mouse_dir.x) > abs(mouse_dir.y):
			facing_direction = "Right" if mouse_dir.x > 0 else "Left"
		else:
			facing_direction = "Down" if mouse_dir.y > 0 else "Up"

	if current_state not in [State.HURT, State.DEATH]:
		if Input.is_action_just_pressed("attack") and can_attack:
			current_state = State.ATTACK
			perform_attack()
			
		if Input.is_action_just_pressed("heavy_attack") and can_attack:
			current_state = State.ATTACK
			perform_attack(true)

	if current_state != State.ATTACK:
		if is_moving:
			if Input.is_action_pressed("sprint"):
				velocity = dir.normalized() * speed * run_multiplier
				current_state = State.RUN
			else:
				velocity = dir.normalized() * speed
				current_state = State.WALK
		else:
			velocity = Vector2.ZERO
			current_state = State.IDLE
	# Poprawiono błąd niewidzialnej spacji (U+00A0)
	elif is_moving:
		if Input.is_action_pressed("sprint"):
			velocity = dir.normalized() * speed * run_multiplier
		else:
			velocity = dir.normalized() * speed
	else:
		velocity = Vector2.ZERO


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
			# Obsługa 3 różnych animacji ataku
			if is_moving and Input.is_action_pressed("sprint"):
				anim_name_prefix = "Attack_Run"
			elif is_moving:
				anim_name_prefix = "Attack_Walk"
			else:
				anim_name_prefix = "Attack"
		State.HURT:
			anim_name_prefix = "Hurt"
		State.DEATH:
			anim_name_prefix = "Death"
			
	# Decide which direction to use for the animation:
	# - If mouse-based combat: always use current facing_direction (mouse sets it at attack time)
	# - If movement-based combat and we are attacking: use attack_locked_direction (if set)
	var anim_direction = facing_direction
	if current_state == State.ATTACK and not PreviousScene.combat_style_mouse_based and attack_locked_direction != "":
		anim_direction = attack_locked_direction

	# łączenie prefiksu z kierunkiem, np. "Walk_Up"
	var final_anim_name = anim_name_prefix + "_" + anim_direction
	var current_anim_name = animated_sprite.animation
	
	if current_anim_name != final_anim_name:
		
		if not animated_sprite.sprite_frames.has_animation(final_anim_name):
			print("BŁĄD: Nie znaleziono animacji: ", final_anim_name)
			return
		# kontynuacja animacji od tej samej pozycji dla animacji ataku
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
	# Clear locked attack direction when attack animation finishes
	if current_state == State.ATTACK:
		attack_locked_direction = ""

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
	
	if current_state == State.ATTACK:
		attack_locked_direction = ""
		attack_locked_direction_mouse = ""  # NEW: reset mouse-based lock
		
	animated_sprite.speed_scale = 1.0



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
	


# --- Prosta detekcja trafienia przeciwników podczas ataku ---
func get_attack_offset() -> Vector2:
	if PreviousScene.combat_style_mouse_based:
		var mouse_pos = get_global_mouse_position()
		var dir_to_mouse = (mouse_pos - global_position).normalized()
		return dir_to_mouse * 24
	else:
		match (attack_locked_direction if attack_locked_direction != "" else facing_direction):
			"Right":
				return Vector2(24, 0)
			"Left":
				return Vector2(-24, 0)
			"Up":
				return Vector2(0, -24)
			"Down":
				return Vector2(0, 24)
			_:
				return Vector2.ZERO

func perform_attack(is_heavy := false):
	if not can_attack:
		return
	can_attack = false

	var radius = heavy_attack_radius if is_heavy else attack_radius
	var dmg_base = heavy_attack_damage if is_heavy else attack_damage
	var cooldown = heavy_attack_cooldown if is_heavy else attack_cooldown

	var dir_to_target: Vector2

	if PreviousScene.combat_style_mouse_based:
		var mouse_pos = get_global_mouse_position()
		dir_to_target = (mouse_pos - global_position).normalized()
		
		# Determine facing direction for animation
		if abs(dir_to_target.x) > abs(dir_to_target.y):
			facing_direction = "Right" if dir_to_target.x > 0 else "Left"
		else:
			facing_direction = "Down" if dir_to_target.y > 0 else "Up"

		# --- NEW: Lock attack direction so it doesn’t change mid-animation ---
		attack_locked_direction_mouse = facing_direction

	else:
		attack_locked_direction = facing_direction
		match facing_direction:
			"Right": dir_to_target = Vector2.RIGHT
			"Left": dir_to_target = Vector2.LEFT
			"Up": dir_to_target = Vector2.UP
			"Down": dir_to_target = Vector2.DOWN
			_: dir_to_target = Vector2.DOWN

	# Play attack animation
	var anim_dir = ""
	if PreviousScene.combat_style_mouse_based:
		anim_dir = attack_locked_direction_mouse if attack_locked_direction_mouse != "" else facing_direction
	else:
		anim_dir = attack_locked_direction if attack_locked_direction != "" else facing_direction
	var anim_speed_scale = 0.5 if is_heavy else 1.0
	
	if is_moving:
		if Input.is_action_pressed("sprint"):
			animated_sprite.play("Attack_Run_" + anim_dir)
		else:
			animated_sprite.play("Attack_Walk_" + anim_dir)
	else:
		animated_sprite.play("Attack_" + anim_dir)
		
	# Set animation speed (heavy attacks play slower)
	animated_sprite.speed_scale = anim_speed_scale

	# Compute attack hit position
	var attack_pos = global_position + dir_to_target * radius

	var attack_args = {
		"radius": radius,
		"dmg_base": dmg_base,
		"attack_pos": attack_pos
	}
	get_tree().create_timer(0.1).timeout.connect(_apply_attack_damage.bind(attack_args))

	if is_heavy and $sfxAttack:
		$sfxAttack.play()
	elif $sfxAttack:
		$sfxAttack.volume_db = rng.randf_range(-10.0, 0.0)
		$sfxAttack.pitch_scale = rng.randf_range(0.9, 1.1)
		$sfxAttack.play()

	get_tree().create_timer(cooldown).timeout.connect(_reset_attack_cooldown)



func _on_frame_changed():
	_step = not _step
	if not _step: return
	if $AnimatedSprite2D.animation.begins_with("Walk") or $AnimatedSprite2D.animation.begins_with("Run"):
		$sfxWalk.volume_db = rng.randf_range(-20.0, -10.0)
		$sfxWalk.pitch_scale = rng.randf_range(0.7, 1.3)
		$sfxWalk.play(0.0)

# NOWA FUNKCJA: Wykonuje obrażenia po opóźnieniu
# (To jest twój kod z 'perform_attack', przeniesiony tutaj)
func _apply_attack_damage(args: Dictionary):
	# Rozpakowujemy zmienne, które przekazaliśmy
	var radius = args["radius"]
	var dmg_base = args["dmg_base"]
	var attack_pos = args["attack_pos"]

	# hitbox (TWÓJ KOD - BEZ ZMIAN)
	var shape = CircleShape2D.new()
	shape.radius = radius

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape_rid = shape.get_rid()
	params.transform = Transform2D(0, attack_pos)

	var space = get_world_2d().direct_space_state
	var results = space.intersect_shape(params, 32)

	for r in results:
		var collider = r.collider
		if collider == self:
			continue
		if collider and collider.has_method("take_damage"):
			# oblicz obrażenia z krytykiem (TWÓJ KOD - BEZ ZMIAN)
			var damage = dmg_base
			if rng.randf() < crit_chance:
				damage = int(damage * crit_multiplier)
				print("Trafienie krytyczne! Obrazenia:", damage)
			collider.take_damage(damage)

func _reset_attack_cooldown():
	can_attack = true

#INTERAKCJE
func _unhandled_input(_event):
	if Input.is_action_just_pressed("Interaction"):
		if interactables_in_range.is_empty():
			return
		var closest = get_closest_interactable()
		if closest:
			closest.interact()
func get_closest_interactable():
	var closest_obj = null
	var min_dist_sq = INF 
	for obj in interactables_in_range:
		if not is_instance_valid(obj):
			continue
		var dist_sq = self.global_position.distance_squared_to(obj.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_obj = obj
	return closest_obj
	
	
################################################


func _process(_delta):
	if Input.is_action_just_pressed("inventory"):
		_toggle_inventory()
	
	#if Input.is_action_just_pressed("Settings"):  # ESC key
		#if settings_open:
			#_close_settings_scene()
		#else:
			#var temp: String = get_tree().current_scene.scene_file_path
			#PreviousScene.previous_scene_path = temp
			#_open_settings_scene()

func _toggle_inventory():
	if inventory_open:
		_close_inventory()
	else:
		_open_inventory()

func _open_inventory():
	if inventory_instance == null:
		inventory_instance = inventory_scene.instantiate()
		get_tree().get_root().add_child(inventory_instance)

	# Hide HUD
	ui_layer.visible = false

	# Make sure inventory (and its canvas layer) are visible
	inventory_instance.visible = true
	var inv_canvas_layer = inventory_instance.get_node_or_null("CanvasLayer")
	if inv_canvas_layer:
		inv_canvas_layer.visible = true

	# --- DARK OVERLAY CREATION ---
	if dark_overlay == null:
		dark_overlay = ColorRect.new()
		dark_overlay.color = Color(0, 0, 0, 0.5)  # semi-transparent black
		dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dark_overlay.size = get_viewport_rect().size
		get_tree().get_root().add_child(dark_overlay)
		dark_overlay.move_to_front() # put overlay above world
	# move inventory above overlay
	inventory_instance.move_to_front()

	# Pause the game world, but keep UI active
	get_tree().paused = true
	inventory_instance.process_mode = Node.PROCESS_MODE_ALWAYS

	inventory_open = true


func _close_inventory():
	# Remove or hide inventory
	if inventory_instance:
		var inv_canvas_layer = inventory_instance.get_node_or_null("CanvasLayer")
		if inv_canvas_layer:
			inv_canvas_layer.visible = false
		inventory_instance.visible = false

	# Remove overlay
	if dark_overlay:
		dark_overlay.queue_free()
		dark_overlay = null

	# Show UI again
	ui_layer.visible = true

	# Unpause game
	get_tree().paused = false

	inventory_open = false

###########################################################

#func _open_settings_scene() -> void:
	#if settings_open:
		#return
#
	#get_tree().paused = true  # Pause the game world
	#ui_layer.visible = false
	#get_tree().paused = true
	## Load and instance the settings scene
	#var new_scene = load(settings_scene_path)
	#settings_instance = new_scene.instantiate()
	#get_tree().root.add_child(settings_instance)
	#
	## Ensure it still processes even while the game is paused
	#settings_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	#settings_open = true
#
#
#func _close_settings_scene() -> void:
	#if not settings_open:
		#return
#
	## Free the settings scene
	#if settings_instance and is_instance_valid(settings_instance):
		#settings_instance.queue_free()
		#settings_instance = null
	#
	#ui_layer.visible = true
	#get_tree().paused = false  # Resume the world
	#settings_open = false
