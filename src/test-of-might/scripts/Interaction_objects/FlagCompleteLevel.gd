extends Node2D

@onready var prompt_label = $Label
@onready var interaction_area = $InteractionArea

func _ready():
	prompt_label.visible = false
	var global = get_node("/root/Global")
	global.boss_killed.connect(show_flag)
	hide()

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
	var currentScene = get_parent().get_parent()
	
	if currentScene.scene_file_path == "res://maps/level1/Dungeon.tscn":
		print("Przechodze na mape cave.tscn")
		Global.SwitchScene("res://maps/cave/cave.tscn")
	
	elif currentScene.scene_file_path == "res://maps/cave/cave.tscn":
		print("Przechodze na mape village.tscn")
		Global.SwitchScene(preload("res://maps/village/village.tscn").resource_path)
	
	elif currentScene.scene_file_path == "res://maps/village/village.tscn":
		print("Przechodze na mape graveyard.tscn")
		Global.SwitchScene(preload("res://maps/graveyard/graveyard.tscn").resource_path)
	
	elif currentScene.scene_file_path == "res://maps/graveyard/graveyard.tscn":
		print("Przechodze na menu glowne")
		Global.SwitchScene("res://scenes/menu/Main_Menu.tscn")
	
	else:
		print("Next level scene is not set.")

func show_flag():
	print("show_flag called")
	show()
