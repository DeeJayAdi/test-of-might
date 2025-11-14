extends Control 

signal slot_selected(slot_id)
@onready var slot_name_label = $VBoxContainer/SlotName
@onready var icon = $VBoxContainer/Icon
@onready var class_label = $VBoxContainer/MarginContainer/VBoxContainer/Class
@onready var level_label = $VBoxContainer/MarginContainer/VBoxContainer/Level
@onready var map_label = $VBoxContainer/MarginContainer/VBoxContainer/Map
@onready var last_saved_label = $VBoxContainer/MarginContainer/VBoxContainer/Last_Saved
@onready var load_button = $VBoxContainer/Load 

var slot_id: int = 0

func _ready():
	load_button.pressed.connect(_on_load_button_pressed)
func update_info(id: int, is_load_mode: bool):
	slot_id = id
	slot_name_label.text = "Save %s" % slot_id
	load_button.disabled = false

	var slot_data_preview = SaveManager.get_slot_preview_data(slot_id)

	if slot_data_preview.is_empty():
		class_label.text = "Class: --"
		level_label.text = "Level: --"
		map_label.text = "Map: --"
		last_saved_label.text = "Last Saved: --"
		load_button.text = "Nowa Gra" 
		icon.texture = null
		if is_load_mode:
			load_button.disabled = true
			load_button.text = "None"
		
	else:
		var player_class = slot_data_preview.get("player_class", "Null")
		class_label.text = "Class: %s" % player_class
		level_label.text = "Level: %s" % slot_data_preview.get("player_level", 1)
		map_label.text = "Map: %s" % slot_data_preview.get("scene_name", "Null")
		last_saved_label.text = "Last Saved: %s" % slot_data_preview.get("save_date", "Null")
		if is_load_mode:
			load_button.text = "Load"
		else:
			load_button.text = "New Game" 

		var class_icon_map = {
			"Mage": "MageMan.png",
			"Warrior": "PalMan.png", 
			"Ranger": "RangerMan.png"
		}
		var icon_file = class_icon_map.get(player_class, "")
		var icon_path = "res://assets/sprites/player/portrait/%s" % icon_file 

		if icon_file != "" and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		else:
			icon.texture = null

func _on_load_button_pressed():
	emit_signal("slot_selected", slot_id)
