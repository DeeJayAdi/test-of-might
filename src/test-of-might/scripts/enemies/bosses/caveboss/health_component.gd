extends Node

signal on_health_changed(current_health, max_health)
signal died

@export var max_health: int = 1000
var current_health: int

func ready():
	current_health = max_health


func take_damage(damage: int):
	if current_health <= 0:
		return
	current_health = clamp(current_health - damage, 0, max_health)
	on_health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()
		
func heal(ammount: int):
	if current_health <= 0 or current_health == max_health:
		return
	current_health = clamp(current_health+ammount, 0, max_health)
	on_health_changed.emit(current_health,max_health)
