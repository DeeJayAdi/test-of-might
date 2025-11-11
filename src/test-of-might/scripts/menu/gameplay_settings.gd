extends Control

@onready var check_button: CheckButton = $CheckButton

func _ready() -> void:
	# Make the toggle reflect the current global setting
	check_button.button_pressed = PreviousScene.combat_style_mouse_based
	check_button.toggled.connect(_on_check_button_toggled)

func _on_check_button_toggled(toggled_on: bool) -> void:
	# Update the global variable
	PreviousScene.combat_style_mouse_based = toggled_on
	print("Combat style (mouse-based):", toggled_on)

func _on_close_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/settings.tscn")
