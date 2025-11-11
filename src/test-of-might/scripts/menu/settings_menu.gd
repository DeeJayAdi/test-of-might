extends Control

func _on_video_pressed() -> void:
	pass # Replace with function body.


func _on_audio_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Audio_Settings.tscn")

func _on_gameplay_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Gameplay_Settings.tscn")


func _on_accessibility_pressed() -> void:
	pass # Replace with function body.


func _on_advanced_pressed() -> void:
	pass # Replace with function body.


func _on_close_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Main_Menu.tscn")
