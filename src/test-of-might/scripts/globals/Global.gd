extends Node

var next_scene_path: String

func SwitchScene(scene_path: String):
	next_scene_path = scene_path
	get_tree().change_scene_to_file("res://scenes/loading_screen/loadingScreen.tscn")
