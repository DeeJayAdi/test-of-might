extends Control

@export var map_menu_scene: String = "res://scenes/map_menu/map_menu.tscn" 
@export var main_menu_scene: String = "res://scenes/menu/Main_Menu.tscn"

@onready var container = $HBoxContainer
@onready var back_button = $Return 

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	for i in container.get_child_count():
		var slot_card = container.get_child(i)
		if slot_card.has_method("update_info"):
			var slot_id = i + 1

			slot_card.update_info(slot_id, false)
				
			slot_card.slot_selected.connect(_on_slot_selected)

func _on_slot_selected(slot_id: int):
	print("Wybrano slot %s." % slot_id)
	SaveManager.current_slot = slot_id
	
	# Sprawdzamy czy na tym slocie już ktoś grał
	if SaveManager.has_save_file(slot_id):
		print("Slot zajęty - wczytuję dane ręcznie i idę do map...")

		# 1. Ustawiamy flagi na NOWY RUN
		SaveManager.respawn_enemies_on_load = true
		SaveManager.reset_position_on_load = true
		
		# 2. Otwieramy plik zapisu "ręcznie" (zamiast używać load_game)
		var path = "user://save_slot_%d.json" % slot_id
		var file = FileAccess.open(path, FileAccess.READ)
		
		if file:
			var content = file.get_as_text()
			file.close()
			
			var parsed = JSON.parse_string(content)
			if parsed:
				var data = parsed.result if parsed.has("result") else parsed
				
				# --- KLUCZOWE: Wrzucamy dane do pamięci SaveManagera ---
				SaveManager.saved_scene_path = data["scene_path"]
				SaveManager.loaded_data = data["nodes"]
				
				# Wczytujemy też odblokowane poziomy, żebyś miał je w Menu Map
				if data.has("global_data"):
					SaveManager.unlocked_levels = data["global_data"].get("unlocked_levels", ["level_tutorial"])
				# -------------------------------------------------------

				# 3. Skoro dane są w pamięci, idziemy do MENU MAP (zamiast do jaskini)
				get_tree().change_scene_to_file(map_menu_scene)
		
	else:
		# --- SCENARIUSZ: CZYSTA NOWA GRA ---
		print("Slot pusty - tworzę nową postać...")

		SaveManager.loaded_data = {} 
		SaveManager.reset_cutscenes()
		
		if SaveManager.has_method("reset_game_state"):
			SaveManager.reset_game_state()

		SaveManager.save_game()
		
		get_tree().change_scene_to_file(map_menu_scene)

func _on_back_button_pressed():
	get_tree().change_scene_to_file(main_menu_scene)
