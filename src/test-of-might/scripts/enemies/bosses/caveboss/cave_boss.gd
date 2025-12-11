#main boss script
class_name CaveBoss extends CharacterBody2D

signal died

@onready var state_manager: Node = $StateManager
@onready var combat_component: Node = $CombatComponent
@onready var health_component: Node = $HealthComponent
@onready var health_bar: ProgressBar = $HpBar
@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var roam_timer: Timer = $RoamTimer
@onready var hide_timer: Timer = $HideTimer
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var sound_effects_component: Node = $SoundEffectsComponent

@export var boss_navigation_region: NavigationRegion2D
@export var attack_cooldown: float = 2
@export var roam_cooldown: float = 10.5
@export var hide_time: float = 3

@export var loot_table: LootTable 


var is_player_detected: bool = false
var is_player_in_melee_range: bool = false
var can_attack: bool = true
var can_roam: bool = true
var target: Node = null
var stagger: bool = false

func _ready() -> void:
	if health_bar:
		health_bar.max_value = health_component.max_health
		health_bar.value = health_component.max_health
		
	health_component.on_health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_death)


func get_facing_direction() -> String:
	if target == null:
		return "down"
	var dir = (target.global_position - global_position).normalized()
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

func play_anim(anim_name: String):
	var full_name = anim_name + "_" + get_facing_direction()
	if anim_player.sprite_frames.has_animation(full_name):
		anim_player.play(full_name)
	else:
		anim_player.play(anim_name)
		
		
func _on_health_changed(_current, _max_hp):
	if health_bar:
		health_bar.value = clamp(_current, 0, _max_hp)
	
	var current_state = state_manager.current_state.name.to_lower()

	if current_state != "roam" and current_state != "death" and current_state != "hurt":
		if state_manager.current_state.name.to_lower() == "attack":
			#reset attack cooldown to allow interrupting attack
			attack_timer.stop()
			can_attack = true
		if self.stagger:
			state_manager.change_state("hurt")


func _on_death():
	died.emit()
	state_manager.change_state("death")
	if has_node("/root/PersistentMusic"):
		PersistentMusic.switch_to_exploration()

	print("Zabito bossa! Odblokowano poziom 2.")
	var global = get_node("/root/Global")
	if not global.is_level_unlocked("level2"):
		global.unlock_level("level2")
		global.save_unlocked_levels()
		NotificationManager.show_notification("New level unlocked: Level 2", 5.0)
		
		SaveManager.save_game()
		# Po 3 sekundach przenieś do menu map
		await get_tree().create_timer(7.0).timeout
		get_tree().change_scene_to_file("res://scenes/map_menu/map_menu.tscn")


func take_damage(damage: int, p_stagger: bool = true):
	self.stagger = p_stagger
	
	health_component.take_damage(damage)

func get_random_roam_position() -> Vector2:
	if not boss_navigation_region:
		push_warning("BRAK NavigationRegion2D przypisanego do Bossa!")
		return global_position

	var nav_poly = boss_navigation_region.navigation_polygon
	if not nav_poly:
		return global_position

	var rect = _get_polygon_bounding_box(nav_poly)
	var random_x = randf_range(rect.position.x, rect.end.x)
	var random_y = randf_range(rect.position.y, rect.end.y)
	var random_point_local = Vector2(random_x, random_y)
	var random_point_global = boss_navigation_region.to_global(random_point_local)
	var map_rid = get_world_2d().navigation_map
	var safe_point = NavigationServer2D.map_get_closest_point(map_rid, random_point_global)
	
	return safe_point

func _get_polygon_bounding_box(poly: NavigationPolygon) -> Rect2:
	var min_vec = Vector2(INF, INF)
	var max_vec = Vector2(-INF, -INF)
	# Sprawdzamy wszystkie wierzchołki zewnętrznego obrysu (outline 0)
	for i in range(poly.get_outline_count()):
		var outline = poly.get_outline(i)
		for point in outline:
			min_vec.x = min(min_vec.x, point.x)
			min_vec.y = min(min_vec.y, point.y)
			max_vec.x = max(max_vec.x, point.x)
			max_vec.y = max(max_vec.y, point.y)
			
	return Rect2(min_vec, max_vec - min_vec)
		

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		target = body
		is_player_detected = true
		if has_node("/root/PersistentMusic"):
			PersistentMusic.switch_to_battle()
		
func _on_meele_area_body_entered(body):
	if body.is_in_group("player"):
		is_player_in_melee_range = true
		
func _on_detection_area_body_exit(body):
	if body.is_in_group("player"):
		target = null
		is_player_detected = false
		if has_node("/root/PersistentMusic"):
			PersistentMusic.switch_to_exploration()
		
func _on_meele_area_body_exit(body):
	if body.is_in_group("player"):
		is_player_in_melee_range = false

func _on_attack_timer_timeout():
	can_attack = true
	
func _on_roam_timer_timeout():
	can_roam = true
