extends CharacterBody2D

var speed = 100
var player = null
var health = 100

func _ready():
	# Find the player by its group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func take_damage(damage):
	health -= damage
	if health <= 0:
		queue_free()
