extends Node

var next_scene_path: String

# Lista odblokowanych poziomów (np. nazwy lub ścieżki)
var unlocked_levels: Array = ["level_tutorial"] # Domyślnie tutorial odblokowany

# Odblokuj poziom
func unlock_level(level_name: String) -> void:
	if not unlocked_levels.has(level_name):
		unlocked_levels.append(level_name)

# Sprawdź czy poziom jest odblokowany
func is_level_unlocked(level_name: String) -> bool:
	return unlocked_levels.has(level_name)

# Zapisz odblokowane poziomy do pliku
func save_unlocked_levels():
	var file = FileAccess.open("user://unlocked_levels.save", FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(unlocked_levels))
		file.close()

# Wczytaj odblokowane poziomy z pliku
func load_unlocked_levels():
	var file = FileAccess.open("user://unlocked_levels.save", FileAccess.READ)
	if file:
		var line = file.get_line()
		var arr = JSON.parse_string(line)
		if typeof(arr) == TYPE_ARRAY:
			unlocked_levels = arr
		file.close()

func _ready():
	load_unlocked_levels()

func SwitchScene(scene_path: String):
	next_scene_path = scene_path
	get_tree().change_scene_to_file("res://scenes/loading_screen/loadingScreen.tscn")
