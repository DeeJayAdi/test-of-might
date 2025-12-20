extends CharacterBody2D

signal died

@export var flag_complete_level: Node2D

var speed = 150
var player = null
var health = 500

func _ready():
	# Find the player by its group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	if SaveManager.is_enemy_dead(self):
		if flag_complete_level:
			flag_complete_level.show()
		queue_free()
		return
		
	if flag_complete_level:
		died.connect(flag_complete_level.show_flag)

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func take_damage(damage):
	health -= damage
	if health <= 0:
		_on_death()

func _on_death():
	emit_signal("died")
	
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
	
	get_tree().create_timer(7.0).timeout.connect(func():
		Global.SwitchScene("res://maps/graveyard/graveyard.tscn")
	)
	
	call_deferred("queue_free")

