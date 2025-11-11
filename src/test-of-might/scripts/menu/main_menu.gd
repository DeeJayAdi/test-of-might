extends Control


func _on_new_game_pressed() -> void:
	var temp: String = get_tree().current_scene.scene_file_path
	PreviousScene.previous_scene_path = temp
	get_tree().change_scene_to_file("res://scenes/map_menu/map_menu.tscn")

func _on_load_pressed() -> void:
	var temp: String = get_tree().current_scene.scene_file_path
	PreviousScene.previous_scene_path = temp
	get_tree().change_scene_to_file("res://maps/cave/cave.tscn")
	PersistentMusic.queue_free()


func _on_settings_pressed() -> void:
	var temp: String = get_tree().current_scene.scene_file_path
	PreviousScene.previous_scene_path = temp
	get_tree().change_scene_to_file("res://scenes/menu/settings.tscn")


func _on_exit_pressed() -> void:
	var temp: String = get_tree().current_scene.scene_file_path
	PreviousScene.previous_scene_path = temp
	get_tree().quit()


func _play_Sound():
	$sfxHover.play()
