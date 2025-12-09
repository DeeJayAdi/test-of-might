extends CharacterBody2D
class_name Player

@onready var health_bar: TextureProgressBar = $UI/HUD/HP/Zdrowie/TextureProgressBar
@onready var inventory_scene = preload("res://scenes/ui/inventory.tscn")
@onready var ui_layer: CanvasLayer = $UI/HUD
@onready var pause_menu = $UI/Windows/PauseMenu
@onready var sfx_comp: SFXComponent = $SfxComponent
@onready var stats_comp: StatsComponent = $StatsComponent
@onready var state_manager: StateManager = $StateManager
@onready var combat_comp: CombatComponent = $CombatComponent
@onready var input_manager: InputManager = $InputManager
@onready var ui_manager: UIManager = $UI
@onready var animation_manager: AnimationManager = $AnimationManager
@onready var inventory: Control = $UI/Windows/Inventory
@onready var ranged_weapon: Node2D = $RangedWeapon
@onready var animated_sprite: AnimatedSprite2D = $AnimationManager/AnimatedSprite2D

@export var settings_scene_path: String = "res://scenes/menu/settings.tscn"

var attack_locked_direction: String = ""
var attack_locked_direction_mouse: String = ""
var facing_direction: String = "Down"
var _step = true
var rng = RandomNumberGenerator.new()
var interactables_in_range = []
var _is_teleport_pending: bool = false
var _teleport_to_position: Vector2 = Vector2.ZERO
var walls_map: Node = null

func _ready():
	var data = SaveManager.get_data_for_node(self)
	if data:
		var current_map_path = get_tree().current_scene.scene_file_path
		
		print("--- DEBUG POZYCJI ---")
		print("Zapisana mapa (z pliku): '", SaveManager.saved_scene_path, "'")
		print("Aktualna mapa (gra):     '", current_map_path, "'")
		if SaveManager.saved_scene_path == current_map_path: 
			var pos_x = data.get("global_pos_x", global_position.x)
			var pos_y = data.get("global_pos_y", global_position.y)
			global_position = Vector2(pos_x, pos_y)
			print("Pozycje zgodne - wczytuję koordynaty.")
		else:
			print("Nowa mapa (lub brak zapisu pozycji dla tej mapy) - używam pozycji startowej.")
			
		if data.has("stats"):
			stats_comp.load_data(data["stats"])
			
		if data.has("inventory") and inventory:
			inventory.load_data(data["inventory"])

	rng.randomize()
	process_mode = Node.PROCESS_MODE_INHERIT
	
	if get_parent() and get_parent().has_node("Walls_Floors"):
		walls_map = get_parent().get_node("Walls_Floors")
	elif get_tree().get_root().has_node("Walls_Floors"):
		walls_map = get_tree().get_root().get_node("Walls_Floors")
		

func _physics_process(_delta: float):
	if get_tree().paused:
		return

	input_manager.process_input(_delta)
	update_facing_direction(input_manager.dir)
	move_and_slide()
	
	if _is_teleport_pending:
		print("Nadpisuję pozycję na: %s" % _teleport_to_position)
		if walls_map and walls_map.has_method("world_to_map") and walls_map.has_method("get_cellv"):
			var cell = walls_map.world_to_map(_teleport_to_position)
			var tile = walls_map.get_cellv(cell)
			if tile != -1:
				var found = false
				for r in range(1, 8):
					for dx in range(-r, r+1):
						for dy in range(-r, r+1):
							var c = cell + Vector2(dx, dy)
							if walls_map.get_cellv(c) == -1:
								var world_pos = walls_map.map_to_world(c)
								if walls_map.has_method("cell_size"):
									world_pos += walls_map.cell_size * 0.5
								_teleport_to_position = world_pos
								found = true
								break
						if found:
							break
					if found:
						break
				if not found:
					print("UWAGA: Nie znaleziono wolnego pola w pobliżu, używam oryginalnej pozycji.")
		global_position = _teleport_to_position
		_is_teleport_pending = false


func update_facing_direction(dir: Vector2):
	if state_manager.get_current_state_name() == "attack":
		return
	if PreviousScene.combat_style_mouse_based:
		update_facing_direction_mouse()
		return
	if dir == Vector2.ZERO:
		return
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

func update_facing_direction_mouse():
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	if abs(mouse_dir.x) > abs(mouse_dir.y):
		facing_direction = "Right" if mouse_dir.x > 0 else "Left"
	else:
		facing_direction = "Down" if mouse_dir.y > 0 else "Up"


func take_damage(amount: int):
	stats_comp.take_damage(amount)

func heal(amount: int):
	stats_comp.heal(amount)
	
func heal_over_time(amount_per_second: int, duration: float) -> void:
	stats_comp.heal_over_time(amount_per_second,duration)

func swap_weapons() -> void:
	if inventory and inventory.has_method("swap_weapon"):
		var success = inventory.swap_weapon()
		if success:
			#if weapon is ranged
			update_weapon_visibility()

func update_weapon_visibility():
	var weapon = inventory.get_current_weapon()
	if weapon and weapon.subtype == "ranged":
		ranged_weapon.visible = true
		ranged_weapon.texture = weapon.icon
	else:
		ranged_weapon.visible = false


func _on_frame_changed():		
	_step = not _step
	if not _step: return
	if animated_sprite.animation.begins_with("Walk") or animated_sprite.animation.begins_with("Run"):
		sfx_comp.play_walk()

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


func save() -> Dictionary:
	var save_dict = {
		"global_pos_x": global_position.x,
		"global_pos_y": global_position.y,
		
		# Delegujemy zapis do komponentów
		"stats": stats_comp.save(),
		"inventory": {}, # Domyślnie puste, zaraz wypełnimy
	}

	
	# Pobieramy dane z inventory (które jest w UI)
	if inventory and inventory.has_method("save"):
		save_dict["inventory"] = inventory.save()
		
	return save_dict
	
func update_gold(amount: int):
	if stats_comp and stats_comp.has_method("update_gold"):
		stats_comp.update_gold(amount)
