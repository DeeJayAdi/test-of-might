extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var battle_player: AudioStreamPlayer = AudioStreamPlayer.new()

# --- ŚCIEŻKI (DODANE MENU) ---
var menu_music_path = "res://assets/audio/misc/chronicles-of-valor-204107.mp3"
var game_music_path = "res://assets/audio/maps/dawnforest_chill-215553.mp3"

var battle_tracks = [
	"res://assets/audio/Battle/Moby/battle-fighting-warrior-drums-372078.mp3",
	"res://assets/audio/Battle/Moby/battle-warrior-fighting-drums-430819.mp3",
	"res://assets/audio/Battle/Moby/fighting-battle-warrior-drums-272176.mp3",
	"res://assets/audio/Battle/Moby/soldier-warrior-fighting-soldier-music-269377.mp3"
]

var persistent_paths := [
	"res://scenes/menu/Main_Menu.tscn",
	"res://scenes/menu/Audio_Settings.tscn",
]
var persistent_names := [
	"Main_Menu",
	"Audio_Settings",
]

func _ready() -> void:
	music_player.bus = "Music"
	# Ładujemy domyślnie Dawnforest (tak jak było)
	var stream: AudioStream = load(game_music_path)
	if stream == null:
		print("!!! BŁĄD: Nie znaleziono pliku dawnforest !!!")
	else:
		print(">>> SUKCES: Plik załadowany.")
	music_player.stream = stream
	music_player.autoplay = false
	add_child(music_player)
	music_player.volume_db = 0 
	
	# Konfiguracja Walki
	battle_player.bus = "Music"
	battle_player.volume_db = -80
	add_child(battle_player)
	battle_player.finished.connect(func(): battle_player.play())

	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))
	music_player.finished.connect(_on_music_finished)

	await get_tree().process_frame
	_evaluate_scene(get_tree().current_scene)

# --- FUNKCJE WALKI (BEZ ZMIAN) ---
func switch_to_battle():
	if battle_player.volume_db > -10: return
	if not battle_player.playing:
		battle_player.stream = load(battle_tracks.pick_random())
		battle_player.play()
	var tween = create_tween()
	tween.parallel().tween_property(music_player, "volume_db", -80.0, 2.0)
	tween.parallel().tween_property(battle_player, "volume_db", 0.0, 2.0)

func switch_to_exploration():
	if music_player.volume_db > -10: return
	var tween = create_tween()
	tween.parallel().tween_property(battle_player, "volume_db", -80.0, 2.0)
	tween.parallel().tween_property(music_player, "volume_db", 0.0, 2.0)

# --- ZMIANY W LOGICE SCEN (DODANO OBSŁUGĘ MENU) ---

func _on_scene_changed() -> void:
	_evaluate_scene(get_tree().current_scene)

func _evaluate_scene(scene: Node) -> void:
	if scene == null:
		_stop_music()
		return

	# 1. Sprawdzamy czy to GRA (szukamy w całym drzewie)
	var is_game = false
	var game_nodes = get_tree().get_nodes_in_group("music_settigns") # Twoja nazwa z literówką
	if game_nodes.size() > 0:
		is_game = true

	# 2. Sprawdzamy czy to MENU (TERAZ TEŻ szukamy w całym drzewie)
	var is_menu = false
	var menu_nodes = get_tree().get_nodes_in_group("main_menu")
	if menu_nodes.size() > 0:
		is_menu = true

	# --- DECYZJA ---
	if is_menu:
		# Jeśli jesteśmy w menu (lub pod-menu), graj Chronicles
		# Funkcja _play_track sama zadba o to, żeby nie resetować muzyki, jeśli już gra
		_play_track(load(menu_music_path))
		
	elif is_game:
		# Jeśli jesteśmy w grze, graj Dawnforest
		_play_track(load(game_music_path))
		
	else:
		# Nieznana scena -> Cisza
		_stop_music()

# Nowa funkcja pomocnicza, żeby nie powtarzać kodu zmiany płyty
func _play_track(new_stream):
	if music_player.stream != new_stream:
		music_player.stream = new_stream
		music_player.play()
	elif not music_player.playing:
		music_player.play()
		
	# Reset głośności (wyłącz tryb walki)
	music_player.volume_db = 0
	battle_player.volume_db = -80

# --- RESZTA (PRAWIE BEZ ZMIAN) ---

func _start_music() -> void:
	# Ta funkcja była używana wcześniej, teraz zastępuje ją _play_track
	# Zostawiam ją dla kompatybilności
	if not music_player.playing:
		music_player.play()
	music_player.volume_db = 0
	battle_player.volume_db = -80

func _stop_music() -> void:
	if music_player.playing: music_player.stop()
	if battle_player.playing: battle_player.stop()

func _on_music_finished() -> void:
	music_player.play()

func _debug(msg: String) -> void:
	print(msg)
