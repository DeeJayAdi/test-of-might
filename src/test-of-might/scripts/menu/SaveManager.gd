extends Node
signal save_completed(success: bool)

const SAVE_PATH := "user://save_slot_%d.json"
var current_slot: int = 1

var loaded_data : Dictionary = {}
var saved_scene_path : String = ""
var played_cutscenes: Array = []

func is_cutscene_played(id: String) -> bool:
	return id in played_cutscenes
	
func mark_cutscene_as_played(id: String):
	if id not in played_cutscenes:
		played_cutscenes.append(id)

func reset_cutscenes():
	played_cutscenes = []

func get_save_path() -> String:
	return SAVE_PATH % current_slot

func save_game():
	print("Rozpoczynam zapis gry (slot %d)..." % current_slot)

	var scene = get_tree().current_scene
	if not scene:
		print("BŁĄD ZAPISU: Brak aktywnej sceny!")
		emit_signal("save_completed", false)
		return

	var save_data = {
		"scene_path": scene.scene_file_path,
		"played_cutscenes": played_cutscenes,
		"nodes": {}
		}
		
	var nodes_to_save = get_tree().get_nodes_in_group("Persist")
	print("Znaleziono %s obiektów do zapisu." % nodes_to_save.size())

	for node in nodes_to_save:
		if is_instance_valid(node) and node.has_method("save"):
			var rel_path = str(scene.get_path_to(node))
			if rel_path == "":
				rel_path = str(node.get_path())
			print("ZAPISUJĘ: %s (rel: %s)" % [node.get_path(), rel_path])
			save_data["nodes"][rel_path] = node.save()
		else:
			print("BŁĄD: Obiekt %s jest w grupie 'Persist', ale nie ma funkcji save()!" % node.name)

	# Zapisz plik synchronicznie do ścieżki slota
	var file = FileAccess.open(get_save_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Gra zapisana pomyślnie w: %s" % get_save_path())

		# Emituj sygnał w deferred, żeby dać czas na flush IO
		call_deferred("_emit_save_completed_safe", true)
	else:
		print("BŁĄD ZAPISU: Nie można otworzyć pliku %s" % get_save_path())
		call_deferred("_emit_save_completed_safe", false)


func _emit_save_completed_safe(success: bool):
	emit_signal("save_completed", success)


func load_game():
	if not has_save_file():
		print("BŁĄD WCZYTYWANIA: Nie znaleziono pliku zapisu.")
		return

	var file = FileAccess.open(get_save_path(), FileAccess.READ)
	if not file:
		print("BŁĄD WCZYTYWANIA: Nie można otworzyć pliku %s" % get_save_path())
		return

	var content = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if not parsed or typeof(parsed) == TYPE_NIL:
		print("BŁĄD WCZYTYWANIA: Nie można przetworzyć pliku save_game.json.")
		return

	var data = parsed.result if parsed.has("result") else parsed
	if not data.has("scene_path") or not data.has("nodes"):
		print("BŁĄD WCZYTYWANIA: Plik zapisu jest uszkodzony (brak scene_path lub nodes).")
		return

	saved_scene_path = data["scene_path"]
	loaded_data = data["nodes"]

	if data.has("played_cutscenes"):
		played_cutscenes = data["played_cutscenes"]
	else:
		played_cutscenes = [] # Jeśli stary save, to lista pusta

	Global.SwitchScene(data["scene_path"])


func get_data_for_node(node_or_path):
	if loaded_data.size() == 0:
		return null

	if saved_scene_path != "" and get_tree().current_scene:
		var cur = get_tree().current_scene.scene_file_path
		if cur != saved_scene_path:
			return null

	if node_or_path is Node:
		var node: Node = node_or_path
		var abs_path = str(node.get_path())
		if loaded_data.has(abs_path):
			return loaded_data[abs_path]

		var scene = get_tree().current_scene
		if scene:
			var rel_path = str(scene.get_path_to(node))
			if rel_path != "" and loaded_data.has(rel_path):
				return loaded_data[rel_path]

		var node_name = node.name
		for k in loaded_data.keys():
			if k.ends_with("/" + node_name) or k == node_name:
				return loaded_data[k]

		return null

	var path_str = str(node_or_path)
	if loaded_data.has(path_str):
		return loaded_data[path_str]

	for k in loaded_data.keys():
		if k.ends_with(path_str) or path_str.ends_with(k):
			return loaded_data[k]

	return null


func has_save_file(slot: int = -1) -> bool:
	var s = current_slot
	if slot != -1:
		s = slot
	return FileAccess.file_exists(SAVE_PATH % s)

func get_slot_preview_data(slot_id: int) -> Dictionary:
	if not has_save_file(slot_id):
		return {}

	var path = SAVE_PATH % slot_id
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
		
	var content = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if not parsed or typeof(parsed) == TYPE_NIL:
		return {}

	var data = parsed.result if parsed.has("result") else parsed
	
	var player_data = null
	for key in data["nodes"]:
		if key.ends_with("/player") or key == "player":
			player_data = data["nodes"][key]
			break
	
	var preview_data = {}
	
	preview_data["scene_name"] = data.get("scene_path", "Nieznana").get_file().get_basename()
	
	if player_data:
		preview_data["player_level"] = player_data.get("level", 1)
		preview_data["player_class"] = player_data.get("class", "Warrior")
	
	var local_time_dict = Time.get_datetime_dict_from_system(false)
	var local_timestamp = Time.get_unix_time_from_datetime_dict(local_time_dict)
	var utc_timestamp = Time.get_unix_time_from_system()
	var offset_seconds = local_timestamp - utc_timestamp
	var file_timestamp_utc = FileAccess.get_modified_time(path)
	var file_timestamp_local = file_timestamp_utc + offset_seconds
	var time = Time.get_datetime_dict_from_unix_time(file_timestamp_local)
	preview_data["save_date"] = "%02d-%02d-%s %02d:%02d" % [time.day, time.month, time.year, time.hour, time.minute]

	return preview_data
