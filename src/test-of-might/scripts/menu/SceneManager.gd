extends Node

var saved_scene: Node = null
var saved_scene_path: String = ""

func switch_scene_keep(old_scene: Node, new_scene_path: String) -> void:
	# Save the current scene and remove it from the tree
	saved_scene_path = old_scene.scene_file_path
	saved_scene = old_scene
	old_scene.get_parent().remove_child(old_scene)

	# Load and add the new scene
	var new_scene = load(new_scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

func return_to_saved_scene() -> void:
	if not saved_scene:
		push_warning("No saved scene to return to.")
		return

	# Remove the current one (optional)
	var current = get_tree().current_scene
	if current:
		current.queue_free()

	# Reattach the saved one
	get_tree().root.add_child(saved_scene)
	get_tree().current_scene = saved_scene

	# Clear reference so it's not reused accidentally
	saved_scene = null
	saved_scene_path = ""
