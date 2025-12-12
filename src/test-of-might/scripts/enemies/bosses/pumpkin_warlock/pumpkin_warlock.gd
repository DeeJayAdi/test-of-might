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

@export var boss_navigation_region: NavigationRegion2D
@export var attack_cooldown: float = 2
@export var loot_table: LootTable 

var target: Node = null
var is_player_detected: bool = false
var is_player_in_melee_range: bool = false

func _ready() -> void:
	if SaveManager.is_enemy_dead(self):
		queue_free()
		return
	if health_bar:
		health_bar.max_value = health_comp.max_health
		health_bar.value = health_comp.max_health
		
	health_comp.on_health_changed.connect(_on_health_changed)
	health_comp.died.connect(_on_death)
