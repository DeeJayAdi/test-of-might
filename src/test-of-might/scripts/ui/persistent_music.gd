extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Optional explicit paths/names (kept as secondary fallback)
var persistent_paths := [
	"res://scenes/ui/Main_Menu.tscn",
	"res://scenes/ui/Audio_Settings.tscn",
]
var persistent_names := [
	"Main_Menu",
	"Audio_Settings",
]

func _ready() -> void:
	# Setup player once
	music_player.bus = "Music"  # exact bus name
	var stream: AudioStream = load("res://Music/Misc/chronicles-of-valor-204107.mp3")
	music_player.stream = stream
	music_player.autoplay = false
	add_child(music_player)

	# Connect to scene change
	get_tree().connect("current_scene_changed", Callable(self, "_on_scene_changed"))
	music_player.finished.connect(_on_music_finished)

	# Wait one frame, then evaluate the initially loaded scene
	await get_tree().process_frame
	_evaluate_scene(get_tree().current_scene)


func _on_scene_changed(new_scene: Node) -> void:
	# Called when root changes; evaluate
	_evaluate_scene(new_scene)


func _evaluate_scene(scene: Node) -> void:
	if scene == null:
		_debug("PersistentMusic: no scene -> stop")
		_stop_music()
		return

	# --- DEBUG INFO ---
	_debug("Checking scene: %s (path=%s)" % [scene.name, scene.scene_file_path])
	_debug("Groups on scene root: %s" % str(scene.get_groups()))

	# 1) Check if any node in tree is in music_settings
	var has_music_group := false
	for n in scene.get_tree().get_nodes_in_group("music_settings"):
		if n.is_inside_tree():
			has_music_group = true
			break

	if has_music_group:
		_debug("PersistentMusic: found node in group 'music_settings' -> play")
		_start_music()
	else:
		_debug("PersistentMusic: no node in group -> stop")
		_stop_music()


func _start_music() -> void:
	if not music_player.playing:
		music_player.play()


func _stop_music() -> void:
	if music_player.playing:
		music_player.stop()


func _on_music_finished() -> void:
	# manual loop for MP3
	music_player.play()


func _debug(msg: String) -> void:
	# uncomment this line to see debug messages in the output when testing
	print(msg)
