extends Node
signal save_completed(success: bool)

const SAVE_PATH = "user://save_game.json"

var loaded_data : Dictionary = {}
var saved_scene_path : String = ""

func save_game():
	print("Rozpoczynam zapis gry...")

	var scene = get_tree().current_scene
	if not scene:
		print("BŁĄD ZAPISU: Brak aktywnej sceny!")
		emit_signal("save_completed", false)
		return

	var save_data = {
		"scene_path": scene.scene_file_path,
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

	# Zapisz plik synchronicznie
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Gra zapisana pomyślnie w: %s" % SAVE_PATH)
		
		# 🔹 Emituj sygnał z opóźnieniem jednej klatki, żeby dać silnikowi czas na flush IO
		call_deferred("_emit_save_completed_safe", true)
	else:
		print("BŁĄD ZAPISU: Nie można otworzyć pliku %s" % SAVE_PATH)
		call_deferred("_emit_save_completed_safe", false)


func _emit_save_completed_safe(success: bool):
	emit_signal("save_completed", success)


func load_game():
	if not has_save_file():
		print("BŁĄD WCZYTYWANIA: Nie znaleziono pliku zapisu.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("BŁĄD WCZYTYWANIA: Nie można otworzyć pliku %s" % SAVE_PATH)
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

	print("Wczytuję scenę: %s" % data["scene_path"])
	get_tree().change_scene_to_file(data["scene_path"])


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

		var name = node.name
		for k in loaded_data.keys():
			if k.ends_with("/" + name) or k == name:
				return loaded_data[k]

		return null

	var path_str = str(node_or_path)
	if loaded_data.has(path_str):
		return loaded_data[path_str]

	for k in loaded_data.keys():
		if k.ends_with(path_str) or path_str.ends_with(k):
			return loaded_data[k]

	return null


func has_save_file():
	return FileAccess.file_exists(SAVE_PATH)
