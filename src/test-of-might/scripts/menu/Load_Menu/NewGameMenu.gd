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
	print("Wybrano slot %s dla NOWEJ GRY." % slot_id)

	SaveManager.current_slot = slot_id
	
	SaveManager.loaded_data = {} 
	
	get_tree().change_scene_to_file(map_menu_scene) 

func _on_back_button_pressed():
	get_tree().change_scene_to_file(main_menu_scene)
