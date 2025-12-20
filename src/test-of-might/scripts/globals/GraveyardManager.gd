extends Node

@export var flag_to_show: Node2D
@export var enemies_node: Node2D

var enemies_to_kill: int = 0

func _ready():
	if not enemies_node:
		print("GraveyardManager: enemies_node is not set!")
		return

	var enemies = enemies_node.get_children()
	enemies_to_kill = enemies.size()
	
	if enemies_to_kill == 0:
		if flag_to_show:
			flag_to_show.show()
		return

	for enemy in enemies:
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
		else:
			print("GraveyardManager: Enemy %s does not have a 'died' signal." % enemy.name)
			enemies_to_kill -= 1 # Decrement count if enemy can't be tracked

func _on_enemy_died():
	enemies_to_kill -= 1
	if enemies_to_kill <= 0:
		if flag_to_show:
			flag_to_show.show()
		else:
			print("GraveyardManager: flag_to_show is not set!")
