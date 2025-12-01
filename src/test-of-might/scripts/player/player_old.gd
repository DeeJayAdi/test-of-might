extends CharacterBody2D
@onready var health_bar: TextureProgressBar = $UI/HP/Zdrowie/TextureProgressBar
@onready var inventory_scene = preload("res://scenes/ui/inventory.tscn")
@onready var ui_layer: CanvasLayer = $UI
@onready var pause_menu = $PauseMenu 
var inventory_instance: Control = null


signal health_changed(current_health, max_health)
signal died
signal xp_changed(current_xp, xp_to_next_level)
signal level_up(new_level)

enum State { IDLE, WALK, RUN, ATTACK, HURT, DEATH }
enum AttackMode { MELEE, RANGED }

# -- System Poziomów i Umiejętności --
@export var character_class: String = "swordsman"
@export var skill_1: Resource
@export var skill_2: Resource
@export var skill_3: Resource
@export var skill_4: Resource

var skills: Dictionary = {}
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100
var damage_multiplier: float = 1.0 # Mnożnik obrażeń dla umiejętności
# ------------------------------------

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
@export var gold: int = 100 
signal gold_changed(current_gold)


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
var _is_teleport_pending: bool = false
var _teleport_to_position: Vector2 = Vector2.ZERO
var attack_mode: AttackMode = AttackMode.MELEE
var settings_instance: Node = null
var settings_open: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var walls_map: Node = null

func _ready():
	level_up.connect(_on_level_up)
	skills = {
		"skill_1": skill_1,
		"skill_2": skill_2,
		"skill_3": skill_3,
		"skill_4": skill_4
	}

	if inventory_instance == null:
		inventory_instance = inventory_scene.instantiate()	
		var inventory_script_node = inventory_instance.get_node_or_null("CanvasLayer/ColorRect/Inventory") 
		
		if inventory_script_node and inventory_script_node.has_method("set_player_node"):
			inventory_script_node.set_player_node(self)
		else:
			print_debug("ERROR: Could not find inventory script on Panel node to set player reference.")
			
		inventory_instance.visible = false 
		get_tree().get_root().add_child(inventory_instance) 
		
	# --- End of modification ---
	
	var data = SaveManager.get_data_for_node(self)
	if data:
		print("Wczytuję dane gracza...")
		current_health = data.get("current_health", max_health)
		level = data.get("level", 1)
		current_xp = data.get("current_xp", 0)
		xp_to_next_level = data.get("xp_to_next_level", 100)
		character_class = data.get("character_class", "swordsman")
		
		_teleport_to_position = Vector2(data["global_pos_x"], data["global_pos_y"])
		_is_teleport_pending = true
		
		# Zaktualizuj UI po wczytaniu
		level_up.emit.call_deferred(level)
		xp_changed.emit.call_deferred(current_xp, xp_to_next_level)
		
	else:
		current_health = max_health
		level = 1
		current_xp = 0
		xp_to_next_level = 100


	health_bar.max_value = max_health
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	rng.randomize()
	process_mode = Node.PROCESS_MODE_INHERIT
	
	if get_parent() and get_parent().has_node("Walls_Floors"):
		walls_map = get_parent().get_node("Walls_Floors")
	elif get_tree().get_root().has_node("Walls_Floors"):
		walls_map = get_tree().get_root().get_node("Walls_Floors")
		
	health_changed.connect(_on_health_changed)
		
func _on_level_up(new_level):
	$UI.get_node("LvL/LVL+Pasek/TEXT_LVL").text = str(new_level)
		
func _on_health_changed(new_health, max_health_value):
	health_bar.value = new_health
	health_bar.max_value = max_health_value

func _physics_process(_delta: float):
	if get_tree().paused:
		return
		
	if inventory_instance and inventory_instance.visible:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if current_state == State.DEATH:
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation()
		return
		
	if current_state == State.HURT:
		var dir = Input.get_vector("left", "right", "up", "down")
		if dir != Vector2.ZERO:
			velocity = dir.normalized() * speed * 0.5  
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		play_animation()
		return

	get_input_and_update_state()
	
	play_animation()

	if walls_map and walls_map.has_method("world_to_map"):
		var next_pos = global_position + velocity * get_physics_process_delta_time()
		var cell = walls_map.world_to_map(next_pos)
		var tile = walls_map.get_cellv(cell)
		if tile != -1:
			velocity = Vector2.ZERO

	if attack_mode == AttackMode.RANGED:
		rotate_weapon_towards_mouse()

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


func get_input_and_update_state():

	if (inventory_instance and inventory_instance.visible) or settings_open:
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

	if current_state not in [State.HURT, State.DEATH]:
		if Input.is_action_just_pressed("attack") and can_attack:
			if attack_mode == AttackMode.RANGED:
				perform_ranged_attack()
				return
			current_state = State.ATTACK
			perform_attack()
		elif Input.is_action_just_pressed("heavy_attack") and can_attack:
			current_state = State.ATTACK
			perform_attack(true)
	
	if Input.is_action_just_pressed("swap_weapon"):
		switch_attack_mode()

	if PreviousScene.combat_style_mouse_based and current_state != State.ATTACK:
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		if abs(mouse_dir.x) > abs(mouse_dir.y):
			facing_direction = "Right" if mouse_dir.x > 0 else "Left"
		else:
			facing_direction = "Down" if mouse_dir.y > 0 else "Up"

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
	elif is_moving:
		if Input.is_action_pressed("sprint"):
			velocity = dir.normalized() * speed * run_multiplier
		else:
			velocity = dir.normalized() * speed
	else:
		velocity = Vector2.ZERO

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

func play_animation():
	var anim_name_prefix: String = ""
	var anim_direction: String = facing_direction

	match current_state:
		State.IDLE:
			anim_name_prefix = "Idle"
		State.WALK:
			anim_name_prefix = "Walk"
		State.RUN:
			anim_name_prefix = "Run"
		State.ATTACK:
			var locked_dir = attack_locked_direction_mouse if PreviousScene.combat_style_mouse_based else attack_locked_direction
			if locked_dir != "":
				anim_direction = locked_dir

			if not animated_sprite.is_playing() or not animated_sprite.animation.begins_with("Attack"):
				if is_moving and Input.is_action_pressed("sprint"):
					anim_name_prefix = "Attack_Run"
				elif is_moving:
					anim_name_prefix = "Attack_Walk"
				else:
					anim_name_prefix = "Attack"
				var final_anim_name = anim_name_prefix + "_" + anim_direction
				if animated_sprite.sprite_frames.has_animation(final_anim_name):
					animated_sprite.play(final_anim_name)
				return
			else:
				return
		State.HURT:
			anim_name_prefix = "Hurt"
		State.DEATH:
			anim_name_prefix = "Death"

	var final_anim_name = anim_name_prefix + "_" + anim_direction
	var current_anim_name = animated_sprite.animation

	if current_anim_name != final_anim_name:
		if not animated_sprite.sprite_frames.has_animation(final_anim_name):
			print("Missing animation:", final_anim_name)
			return
		animated_sprite.play(final_anim_name)

func _on_animation_finished():
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
	$sfxHurt.volume_db = rng.randf_range(-10.0, 5.0)
	$sfxHurt.pitch_scale = rng.randf_range(0.8, 1.2)
	$sfxHurt.play()
	current_health -= amount
		
	var def = UpdateStats.get_total_defense()

	var final_damage = max(0, amount - def)

	current_health -= final_damage
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
	
func heal_over_time(amount_per_second: int, duration: float) -> void:
	if current_state == State.DEATH or current_health == max_health:
		return
	var seconds_passed := 0
	while seconds_passed < int(ceil(duration)):
		if current_state == State.DEATH:
			return
		heal(amount_per_second)
		seconds_passed += 1
		await get_tree().create_timer(1.0).timeout

func die():
	if current_state == State.DEATH:
		return
		
	print("Gracz umarł!")
	current_state = State.DEATH
	died.emit()

# --- System Poziomów ---
func add_xp(amount: int):
	if current_state == State.DEATH:
		return
	current_xp += amount
	print("Zdobyto %s XP. Aktualne XP: %s/%s" % [amount, current_xp, xp_to_next_level])
	xp_changed.emit(current_xp, xp_to_next_level)
	_check_for_level_up()

func _check_for_level_up():
	while current_xp >= xp_to_next_level:
		level += 1
		current_xp -= xp_to_next_level
		xp_to_next_level = _calculate_xp_for_next_level()
		
		# --- Zwiększ statystyki przy awansie ---
		max_health += 10
		current_health = max_health # Pełne uleczenie przy awansie
		attack_damage += 2
		# ------------------------------------
		
		print("AWANS! Osiągnięto poziom %s!" % level)
		NotificationManager.show_notification("Level up! Reached level %s" % level, 4.0)
		if level == 2 and skill_2:
			NotificationManager.show_notification("New skill unlocked: %s" % skill_2.skill_name, 4.0)
		if level == 3 and skill_3:
			NotificationManager.show_notification("New skill unlocked: %s" % skill_3.skill_name, 4.0)
		if level == 4 and skill_4:
			NotificationManager.show_notification("New skill unlocked: %s" % skill_4.skill_name, 4.0)

		level_up.emit(level)
		health_changed.emit(current_health, max_health)
		xp_changed.emit(current_xp, xp_to_next_level)

func _calculate_xp_for_next_level() -> int:
	# Prosty wzór na potrzebne XP, można go skomplikować
	return int(100 * pow(1.2, level - 1))
# -------------------------


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

	var dmg_base = UpdateStats.get_total_damage()
	var radius = UpdateStats.get_total_range()
	var cooldown = UpdateStats.get_total_cooldown(attack_cooldown)
	
	if is_heavy:
		radius = heavy_attack_radius 
		dmg_base = dmg_base * 1.5 # Or dmg_base * 2
		cooldown = heavy_attack_cooldown

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


func _apply_attack_damage(args: Dictionary):
	var radius = args["radius"]
	var dmg_base = args["dmg_base"]
	var attack_pos = args["attack_pos"]

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
			var damage = dmg_base
			if rng.randf() < crit_chance:
				damage = int(damage * crit_multiplier)
				print("Trafienie krytyczne! Obrazenia:", damage)
			
			# Zastosuj mnożnik obrażeń z umiejętności
			damage = int(damage * damage_multiplier)
			
			collider.take_damage(damage)

func _reset_attack_cooldown():
	can_attack = true

#INTERAKJE
func _unhandled_input(_event):
	# --- Logika Umiejętności ---
	if get_tree().paused or (inventory_instance and inventory_instance.visible):
		return

	if _event.is_action_pressed("skill_1") and skills.skill_1:
		if skills.skill_1.can_use(self):
			NotificationManager.show_notification("Used skill: %s" % skills.skill_1.skill_name, 2.0)
			skills.skill_1.activate(self)
	if _event.is_action_pressed("skill_2") and skills.skill_2:
		if skills.skill_2.can_use(self):
			NotificationManager.show_notification("Used skill: %s" % skills.skill_2.skill_name, 2.0)
			skills.skill_2.activate(self)
	if _event.is_action_pressed("skill_3") and skills.skill_3:
		if skills.skill_3.can_use(self):
			NotificationManager.show_notification("Used skill: %s" % skills.skill_3.skill_name, 2.0)
			skills.skill_3.activate(self)
	if _event.is_action_pressed("skill_4") and skills.skill_4:
		if skills.skill_4.can_use(self):
			NotificationManager.show_notification("Used skill: %s" % skills.skill_4.skill_name, 2.0)
			skills.skill_4.activate(self)
	# --------------------------

	if Input.is_action_just_pressed("ui_cancel"):
		# Odwróć stan pauzy
		var is_paused = not get_tree().paused
		get_tree().paused = is_paused
		pause_menu.visible = is_paused # Pokaż/ukryj menu
		
		# Zakończ funkcję, aby nie sprawdzać 'Interaction' w tej samej klatce
		return
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

# --- REMOVED: All inventory functions are gone from here ---
# REMOVED: _process()
# REMOVED: _toggle_inventory()
# REMOVED: _open_inventory()
# REMOVED: _close_inventory()

################################
#logika walki dystansowej

var upgrades : Array[BaseBulletStrategy] = []

func add_bullet_upgrade(upgrade: BaseBulletStrategy):
	upgrades.append(upgrade)


func switch_attack_mode():
	if attack_mode == AttackMode.MELEE:
		attack_mode = AttackMode.RANGED
		$RangedWeapon.visible = true
	else:
		attack_mode = AttackMode.MELEE
		$RangedWeapon.visible = false

func perform_ranged_attack():
	if not can_attack:
		return
	can_attack = false

	var bullet = preload("res://scenes/objects/bullet.tscn").instantiate() as Bullet
	for upgrade in upgrades:
		upgrade.apply_upgrade(bullet)

	var muzzle = $RangedWeapon/Marker2D
	
	bullet.global_position = muzzle.global_position

	bullet.rotation = muzzle.global_rotation + PI / 4

	get_parent().add_child(bullet)

	var cooldown = attack_cooldown
	get_tree().create_timer(cooldown).timeout.connect(_reset_attack_cooldown)


func rotate_weapon_towards_mouse():
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - global_position).normalized()
	var player_offset = Vector2(0, -20)
	
	var horizontal_radius = 16.0 
	var vertical_radius = 32.0


	var real_angle = dir_to_mouse.angle()
	
	var ellipse_pos = Vector2(
		horizontal_radius * cos(real_angle),
		vertical_radius * sin(real_angle)
	)
	
	$RangedWeapon.position = ellipse_pos + player_offset

	var visual_angle = dir_to_mouse.angle() - PI / 4
	$RangedWeapon.global_rotation = visual_angle
###########################################################
func save():
	return {
		"global_pos_x": global_position.x,
		"global_pos_y": global_position.y,
		"current_health": current_health,
		"level": level,
		"current_xp": current_xp,
		"xp_to_next_level": xp_to_next_level,
		"character_class": character_class
	}
#sklep
func update_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)
	print("Złoto: ", gold)
