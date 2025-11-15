# Plik: res://scripts/menu/LoadSaveMenu.gd
extends Control

# Ścieżka do pierwszej sceny gry (jeśli slot jest pusty)
@export var new_game_scene: String = "res://maps/cave/cave.tscn" 
# Ścieżka do menu głównego
@export var main_menu_scene: String = "res://scenes/menu/Main_Menu.tscn"

@onready var container = $HBoxContainer
@onready var back_button = $Return # Zgodnie z twoim zrzutem "Return"

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Przejdź przez wszystkie karty-sloty w kontenerze
	for i in container.get_child_count():
		var slot_card = container.get_child(i)
		if slot_card.has_method("update_info"):
			var slot_id = i + 1
			
			# --- POPRAWKA BŁĘDU JEST TUTAJ ---
			# Przekaż 'true', aby poinformować kartę, 
			# że jest w trybie "Wczytaj Grę".
			slot_card.update_info(slot_id, true)
			# --- KONIEC POPRAWKI ---
				
			slot_card.slot_selected.connect(_on_slot_selected)

# Ta funkcja zostanie wywołana przez DOWOLNĄ kartę, która zostanie kliknięta
func _on_slot_selected(slot_id: int):
	print("Wybrano slot %s" % slot_id)
	
	# Ustaw aktywny slot w SaveManagerze
	SaveManager.current_slot = slot_id
	
	if SaveManager.has_save_file(slot_id):
		SaveManager.load_game() # Wczytaj grę
	else:
		# Slot jest pusty, zacznij nową grę
		print("Slot %s jest pusty. Uruchamiam nową grę..." % slot_id)
		SaveManager.loaded_data = {} 
		get_tree().change_scene_to_file(new_game_scene)

func _on_back_button_pressed():
	get_tree().change_scene_to_file(main_menu_scene)
