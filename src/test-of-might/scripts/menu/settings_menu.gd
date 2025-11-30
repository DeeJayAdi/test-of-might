extends Control

var is_opened_from_pause_menu: bool = false
@export var main_menu_path: String = "res://scenes/menu/Main_Menu.tscn"

func change_scene_to_node(node):
	var tree = get_tree()
	var cur_scene = tree.get_current_scene()
	tree.get_root().add_child(node)
	tree.set_current_scene(node)


func _on_video_pressed() -> void:
	pass # Replace with function body.


func _on_audio_pressed() -> void:
	var audio_scene = load("res://scenes/menu/audio_settings.tscn").instantiate()	
	if "is_opened_from_pause_menu" in self and self.is_opened_from_pause_menu:
		audio_scene.is_opened_from_pause_menu = true
		
	add_child(audio_scene)

func _on_gameplay_pressed() -> void:
	var gameplay_scene = load("res://scenes/menu/Gameplay_Settings.tscn").instantiate()	
	if "is_opened_from_pause_menu" in self and self.is_opened_from_pause_menu:
		gameplay_scene.is_opened_from_pause_menu = true
		
	add_child(gameplay_scene)


func _on_accessibility_pressed() -> void:
	pass # Replace with function body.


func _on_advanced_pressed() -> void:
	pass # Replace with function body.


func _on_close_settings_pressed():
	if is_opened_from_pause_menu:
		queue_free() 
	else:
		get_tree().change_scene_to_file(main_menu_path)
