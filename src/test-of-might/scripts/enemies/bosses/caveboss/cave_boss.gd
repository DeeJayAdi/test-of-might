extends CharacterBody2D
enum State { IDLE, MOVING, ATTACK, HURT, DEATH }

@onready var input_handler: Node = $InputHandler
@onready var state_manager: Node = $InputHandler
@onready var combat_component: Node = $CombatComponent
@onready var health_component: Node = $HealthComponent
@onready var health_bar: Node = $HpBar

@export var attack_cooldown: float = 1.5
@export var roam_cooldown: float = 12.5

var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	health_component.on_health_changed.connect()
	

func _physics_process(delta: float):
	pass;
