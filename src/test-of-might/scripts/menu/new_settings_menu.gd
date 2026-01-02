extends Control

@export var main_menu_path: String = "res://scenes/menu/Main_Menu.tscn"

@onready var music_bus_id: int = AudioServer.get_bus_index("Music")
@onready var sfx_bus_id: int = AudioServer.get_bus_index("SFX")
@onready var music_slider: HSlider = $CanvasLayer/Panel/ColorRect/VBoxContainer/Controls/Audio/Music_HSlider
@onready var sfx_slider: HSlider = $CanvasLayer/Panel/ColorRect/VBoxContainer/Controls/Audio/SFX_HSlider
@onready var check_button: CheckButton = $CanvasLayer/Panel/ColorRect/VBoxContainer/Controls/Gameplay/CheckButton
@onready var gameplay_content: MarginContainer = $CanvasLayer/Panel/ColorRect/VBoxContainer/Controls/Gameplay
@onready var audio_content: GridContainer = $CanvasLayer/Panel/ColorRect/VBoxContainer/Controls/Audio

var is_opened_from_pause_menu: bool = false

func _ready() -> void:
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_id))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_id))
	
	process_mode = Node.PROCESS_MODE_ALWAYS

	if FileAccess.file_exists("user://audio_settings.save"):
		_load_audio_settings()
	
	check_button.button_pressed = PreviousScene.combat_style_mouse_based
	
	gameplay_content.visible = false
	audio_content.visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_settings_pressed()


func _on_music_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_id, linear_to_db(value))
	AudioServer.set_bus_mute(music_bus_id, value < 0.05)

	if Engine.has_singleton("PersistentMusic"):
		var mgr = PersistentMusic
		if mgr.has_node("AudioStreamPlayer"):
			mgr.music_player.volume_db = linear_to_db(value)

	_save_audio_settings()


func _on_sfx_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_id, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus_id, value < 0.05)

	_save_audio_settings()


func _save_audio_settings() -> void:
	var file = FileAccess.open("user://audio_settings.save", FileAccess.WRITE)
	file.store_var({
		"music": music_slider.value,
		"sfx": sfx_slider.value
	})
	file.close()

func _load_audio_settings() -> void:
	var file = FileAccess.open("user://audio_settings.save", FileAccess.READ)
	var data = file.get_var()
	file.close()
	if data.has("music"):
		music_slider.value = data["music"]
		_on_music_h_slider_value_changed(data["music"])
	if data.has("sfx"):
		sfx_slider.value = data["sfx"]
		_on_sfx_h_slider_value_changed(data["sfx"])


func _on_check_button_toggled(toggled_on: bool) -> void:
	PreviousScene.combat_style_mouse_based = toggled_on
	print("Combat style (mouse-based):", toggled_on)


func _on_gameplay_pressed() -> void:
	gameplay_content.visible = true
	audio_content.visible = false


func _on_audio_pressed() -> void:
	gameplay_content.visible = false
	audio_content.visible = true


func _on_close_settings_pressed():
	if is_opened_from_pause_menu:
		queue_free()
	else:
		get_tree().change_scene_to_file(main_menu_path)
