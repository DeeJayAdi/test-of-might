extends CharacterBody2D
class_name Player

# --- KOMPONENTY ---
@onready var stats: StatsComponent = $StatsComponent
@onready var combat: CombatComponent = $CombatComponent
@onready var interaction: InteractionComponent = $InteractionComponent
@onready var equipment: EquipmentComponent = $EquipmentComponent
@onready var ui: UIManager = $UI
@onready var visuals: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var state_machine: Node = $StateManager

# --- RUCH ---
@export var speed: float = 200.0
@export var run_multiplier: float = 1.5 

# Zmienne stanu
var facing_direction: String = "Down"
var is_moving: bool = false
var _teleport_pending: bool = false
var _teleport_pos: Vector2

func _ready():
	# Połączenie sygnałów
	stats.health_changed.connect(ui.update_health_bar)
	stats.xp_changed.connect(ui.update_xp_bar)
	stats.level_up.connect(ui.update_level_text)
	stats.died.connect(_on_death)
	
	# Inicjalizacja komponentów
	combat.player = self # Przekazujemy siebie do komponentu walki
	
	# Wczytywanie danych (uproszczone)
	load_game_data()

func _physics_process(delta):
	if get_tree().paused: return
	
	# Ruch jest obsługiwany tutaj lub w StateManagerze. 
	# Dla uproszczenia zostawiam podstawowy ruch tutaj, ale docelowo przenieś do StateWalk.gd
	handle_movement()
	move_and_slide()
	
	# Teleportacja (z save systemu)
	if _teleport_pending:
		global_position = _teleport_pos
		_teleport_pending = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		ui.handle_back_action()
	elif event.is_action_pressed("open_inventory"): # Np. 'I'
		ui.toggle_inventory()
	elif event.is_action_pressed("Interaction"):
		interaction.interact_closest()
	elif event.is_action_pressed("use_skill"):
		equipment.use_active_skill(self)
		
	# Obsługa ataku przekazana do CombatComponent
	if event.is_action_pressed("attack"):
		var dir = _get_aim_direction()
		play_animation("Attack") # Prosta obsługa animacji
		combat.perform_attack(dir)
		
	if event.is_action_pressed("heavy_attack"):
		var dir = _get_aim_direction()
		play_animation("Attack") 
		combat.perform_heavy_attack(dir)

func handle_movement():
	var dir = Input.get_vector("left", "right", "up", "down")
	is_moving = dir != Vector2.ZERO
	
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed *= run_multiplier
		
	velocity = dir * current_speed
	
	if is_moving:
		update_facing_direction(dir)
		if not visuals.animation.begins_with("Attack"): # Nie przerywaj ataku
			play_animation("Walk" if current_speed == speed else "Run")
	else:
		if not visuals.animation.begins_with("Attack"):
			play_animation("Idle")

func update_facing_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		facing_direction = "Right" if dir.x > 0 else "Left"
	else:
		facing_direction = "Down" if dir.y > 0 else "Up"

func _get_aim_direction() -> Vector2:
	# Tutaj logika Myszka vs Klawiatura (zmienna PreviousScene z oryginału)
	# Dla przykładu myszka:
	return (get_global_mouse_position() - global_position).normalized()

func play_animation(anim_prefix: String):
	var final_anim = anim_prefix + "_" + facing_direction
	if visuals.sprite_frames.has_animation(final_anim):
		visuals.play(final_anim)

func _on_death():
	print("Gracz umarł")
	play_animation("Death")
	set_physics_process(false) # Wyłącz sterowanie

# --- SAVE SYSTEM ---
func save():
	var save_dict = {
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"stats": stats.get_save_data()
	}
	return save_dict

func load_game_data():
	var data = SaveManager.get_data_for_node(self)
	if data:
		_teleport_pos = Vector2(data.get("pos_x", 0), data.get("pos_y", 0))
		_teleport_pending = true
		if data.has("stats"):
			stats.load_save_data(data["stats"])
