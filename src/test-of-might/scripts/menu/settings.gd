extends Control

@onready var music_bus_id: int = AudioServer.get_bus_index("Music")
@onready var sfx_bus_id: int = AudioServer.get_bus_index("SFX")
var is_opened_from_pause_menu: bool = false

@onready var music_slider: HSlider = $SettingsMenu/ColorRect/VBoxContainer/GridContainer/Music_HSlider
@onready var sfx_slider: HSlider = $SettingsMenu/ColorRect/VBoxContainer/GridContainer/SFX_HSlider

func _ready() -> void:
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_id))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_id))
	
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Optional: restore saved volume levels
	if FileAccess.file_exists("user://audio_settings.save"):
		_load_audio_settings()


func _on_music_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_id, linear_to_db(value))
	AudioServer.set_bus_mute(music_bus_id, value < 0.05)

	# --- Sync MusicManager (if exists) ---
	if Engine.has_singleton("PersistentMusic"):
		var mgr = PersistentMusic
		if mgr.has_node("AudioStreamPlayer"):
			mgr.music_player.volume_db = linear_to_db(value)

	# Optional: save updated volume
	_save_audio_settings()


func _on_sfx_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_id, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus_id, value < 0.05)

	_save_audio_settings()


func _on_close_settings_pressed() -> void:
	if is_opened_from_pause_menu:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/menu/settings.tscn")


# --- Optional helpers for persistence ---
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
