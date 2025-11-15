extends Node2D

@export var default_animation_name: String = "nazwa_twojej_animacji" 
var is_animated: bool = true 
@onready var prompt_label = $Label
@onready var interaction_area = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D 


func _ready():
	prompt_label.visible = false
	animated_sprite.play(default_animation_name)
	is_animated = true

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		prompt_label.visible = true
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.append(self)
func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		prompt_label.visible = false
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.erase(self)
func interact():
	
	if is_animated:
		animated_sprite.stop()
		print("interakcja_flaga")
		is_animated = false
	else:
		animated_sprite.play(default_animation_name)
		is_animated = true
		
# Zwraca słownik ze stanem flagi
func save():
	return {
		"is_animated": is_animated
	}
