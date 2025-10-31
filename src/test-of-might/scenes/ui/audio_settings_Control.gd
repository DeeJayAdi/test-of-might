extends Control

@onready var music_bus_id: int = AudioServer.get_bus_index("Music")
@onready var sfx_bus_id: int = AudioServer.get_bus_index("SFX")

@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/GridContainer/Music_HSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/GridContainer/SFX_HSlider

func _ready() -> void:
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_id))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_id))

func _on_music_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_id, linear_to_db(value))
	AudioServer.set_bus_mute(music_bus_id, value < 0.05)


func _on_sfx_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_id, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus_id, value < 0.05)


func _on_close_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Main_Menu.tscn")
