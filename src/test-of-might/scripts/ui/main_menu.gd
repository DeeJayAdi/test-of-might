extends Control


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/Dungeon.tscn")


func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/Dungeon.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Audio_Settings.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _play_Sound():
	$sfxHover.play()
