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
	# Odblokuj kolejny poziom po interakcji z flagą
	var global = get_node("/root/Global")
	# Dodaj kolejne poziomy wg uznania
	if not global.is_level_unlocked("level1"):
		global.unlock_level("level1")
		global.save_unlocked_levels()
		NotificationManager.show_notification("New level unlocked: Level 1", 5.0)

	if is_animated:
		animated_sprite.stop()
		print("interakcja_flaga")
		is_animated = false
		await get_tree().create_timer(5).timeout
		get_tree().change_scene_to_file("res://scenes/map_menu/map_menu.tscn")
	else:
		animated_sprite.play(default_animation_name)
		is_animated = true
		await get_tree().create_timer(5).timeout
		get_tree().change_scene_to_file("res://scenes/map_menu/map_menu.tscn")
