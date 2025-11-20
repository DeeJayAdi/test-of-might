#main boss script
class_name CaveBoss extends CharacterBody2D

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

@export var attack_cooldown: float = 2
@export var roam_cooldown: float = 10.5
@export var hide_time: float = 3


var is_player_detected: bool = false
var is_player_in_melee_range: bool = false
var can_attack: bool = true
var can_roam: bool = true
var target: Node = null

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
		state_manager.change_state("hurt")


func _on_death():
	state_manager.change_state("death")

func take_damage(damage: int):
	health_component.take_damage(damage)

func get_random_roam_position() -> Vector2:
	if target:
		var random_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		return target.global_position + random_offset
	return global_position

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		target = body
		is_player_detected = true
		
func _on_meele_area_body_entered(body):
	if body.is_in_group("player"):
		is_player_in_melee_range = true
		
func _on_detection_area_body_exit(body):
	if body.is_in_group("player"):
		target = null
		is_player_detected = false
		
func _on_meele_area_body_exit(body):
	if body.is_in_group("player"):
		is_player_in_melee_range = false

func _on_attack_timer_timeout():
	can_attack = true
	
func _on_roam_timer_timeout():
	can_roam = true
