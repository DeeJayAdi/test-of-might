extends Control

var sceneLink = "noLevel"

func _on_tutorial_btn_pressed() -> void:
	sceneLink = "res://maps/level_tutorial/Tutorial.tscn"

func _on_level_1_btn_pressed() -> void:
	sceneLink = "res://maps/level1/Dungeon.tscn"

func _on_level_2_btn_pressed() -> void:
	sceneLink = "res://maps/cave/cave.tscn"

func _on_level_3_btn_pressed() -> void:
	sceneLink = "res://maps/level1/Dungeon.tscn"

func _on_level_4_btn_pressed() -> void:
	sceneLink = "res://maps/level1/Dungeon.tscn"

func _on_start_game_btn_pressed() -> void:
	if sceneLink == "noLevel":
		$VBoxContainer2/ErrorLabel.text = "Choose level to continue"
		return
		
	$VBoxContainer2/ErrorLabel.text = ""
	get_tree().change_scene_to_file(sceneLink)
	if Engine.has_singleton("PersistentMusic") and is_instance_valid(PersistentMusic):
		PersistentMusic.queue_free()


func _play_Sound():
	$sfxHover.play()


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Main_Menu.tscn")
