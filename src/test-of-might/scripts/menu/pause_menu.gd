extends Control

@export var settings_scene_path: String = "res://scenes/menu/settings.tscn"
@export var main_menu_path: String = "res://scenes/menu/Main_Menu.tscn"
var settings_instance = null

func _ready():
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$VBoxContainer/SaveButton.pressed.connect(_on_save_button_pressed)
	$VBoxContainer/LoadButton.pressed.connect(_on_load_button_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_button_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _on_resume_button_pressed():
	get_tree().paused = false
	self.visible = false


func _on_save_button_pressed():
	SaveManager.save_game()
	print("Gra zapisana!")


func _on_load_button_pressed():
	get_tree().paused = false
	SaveManager.load_game()


func _on_options_button_pressed():
	if settings_instance == null:
		var scene = load(settings_scene_path)
		if scene:
			settings_instance = scene.instantiate()
			settings_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
			add_child(settings_instance)
			
			var close_button = settings_instance.get_node_or_null("Panel/Close_Button") 
			if close_button:
				close_button.pressed.connect(_on_settings_closed)
			else:
				print("OSTRZEŻENIE: Nie znaleziono przycisku 'Panel/Close_Button' w scenie ustawień.")
		else:
			print("BŁĄD: Nie można wczytać sceny ustawień ze ścieżki: %s" % settings_scene_path)

	if settings_instance:
		settings_instance.visible = true
		self.visible = false 


func _on_settings_closed():
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null
	self.visible = true 

func _on_quit_button_pressed():
	get_tree().paused = false

	var callable = Callable(self, "_on_save_then_quit")
	if not SaveManager.is_connected("save_completed", callable):
		SaveManager.connect("save_completed", callable)

	SaveManager.save_game()

	$VBoxContainer/QuitButton.disabled = true
	
func _on_save_then_quit(success: bool) -> void:
	var callable = Callable(self, "_on_save_then_quit")
	if SaveManager.is_connected("save_completed", callable):
		SaveManager.disconnect("save_completed", callable)

	$VBoxContainer/QuitButton.disabled = false

	if success:
		if is_instance_valid(PersistentMusic) and PersistentMusic.has_method("stop"):
			PersistentMusic.stop()
		get_tree().change_scene_to_file(main_menu_path)
	else:
		print("Zapis nie powiódł się — nie wychodzę z gry.")
