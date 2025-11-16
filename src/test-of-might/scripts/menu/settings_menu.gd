extends Control

func change_scene_to_node(node):
	var tree = get_tree()
	var cur_scene = tree.get_current_scene()
	tree.get_root().add_child(node)
	tree.set_current_scene(node)


func _on_video_pressed() -> void:
	pass # Replace with function body.


func _on_audio_pressed() -> void:
	var simultaneous_scene = preload("res://scenes/menu/Audio_Settings.tscn").instantiate()
	change_scene_to_node(simultaneous_scene)
	queue_free()
	return

func _on_gameplay_pressed() -> void:
	var simultaneous_scene = preload("res://scenes/menu/Gameplay_Settings.tscn").instantiate()
	change_scene_to_node(simultaneous_scene)
	queue_free()


func _on_accessibility_pressed() -> void:
	pass # Replace with function body.


func _on_advanced_pressed() -> void:
	pass # Replace with function body.


func _on_close_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Main_Menu.tscn")
