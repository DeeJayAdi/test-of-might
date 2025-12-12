class_name pumpkin_warlock extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HpBar
@onready var detection_area: Area2D = $DetectionArea
@onready var melee_area: Area2D = $MeleeArea
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var state_manager: Node = $StateManager
@onready var health_comp: Node = $HealthComponent
@onready var combat_comp: Node = $CombatComponent
@onready var sfx_comp: Node2D = $SfxComponent
@onready var attack_timer: Timer = $AttackTimer

@export var boss_navigation_region: NavigationRegion2D
@export var attack_cooldown: float = 2
@export var loot_table: LootTable 
@export var walk_speed: float = 50

signal died

var target: Node = null
var is_player_detected: bool = false
var is_player_in_melee_range: bool = false
var can_attack = false
var stagger = false
var can_summon = false

func _ready() -> void:
	if SaveManager.is_enemy_dead(self):
		queue_free()
		return
	if health_bar:
		health_bar.max_value = health_comp.max_health
		health_bar.value = health_comp.max_health
		
	health_comp.on_health_changed.connect(_on_health_changed)
	health_comp.died.connect(_on_death)


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
	SaveManager.register_enemy_death(self)
	if has_node("/root/PersistentMusic"):
		PersistentMusic.switch_to_exploration()

	print("Zabito bossa! Odblokowano poziom 3.")
	var global = get_node("/root/Global")
	if not global.is_level_unlocked("level3"):
		global.unlock_level("level3")
		global.save_unlocked_levels()
		NotificationManager.show_notification("New level unlocked: Level 3", 5.0)
		
		SaveManager.save_game()
	print("Zapisuję stan gry...")
	SaveManager.save_game()


func take_damage(damage: int, p_stagger: bool = true):
	self.stagger = p_stagger
	
	health_comp.take_damage(damage)


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
	if anim_sprite.sprite_frames.has_animation(full_name):
		anim_sprite.play(full_name)
	else:
		anim_sprite.play(anim_name)


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
	
func _on_summon_timer_timeout():
	can_summon = true
