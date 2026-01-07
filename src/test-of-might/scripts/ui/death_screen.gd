extends Control

@onready var restart_button: Button = $CenterContainer/RestartButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if SaveManager.has_save_file():
		restart_button.text = "Load from previous save"
	else:
		restart_button.hide()

func _on_RestartButton_pressed():
	get_tree().paused = false
	if SaveManager.has_save_file():
		SaveManager.load_game()
	else:
		# If there's no save file, go to the main menu
		get_tree().change_scene_to_file("res://scenes/menu/Main_Menu.tscn")

func _on_MainMenuButton_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/Main_Menu.tscn")
