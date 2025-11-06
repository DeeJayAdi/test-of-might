extends Control


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map_menu/map_menu.tscn")

func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://maps/level1/Dungeon.tscn")
	PersistentMusic.queue_free()


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Audio_Settings.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _play_Sound():
	$sfxHover.play()
