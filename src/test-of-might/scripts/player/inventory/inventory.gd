extends Panel

func _process(_delta: float) -> void:
	if Input.get_current_cursor_shape() == CURSOR_FORBIDDEN:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

var data_bk
func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_DRAG_BEGIN:
		data_bk = get_viewport().gui_get_drag_data()
	if what == Node.NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			if data_bk:
				data_bk.icon.show()
				data_bk = null


func _on_settings_pressed() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	var next_scene = preload("res://scenes/menu/settings.tscn").instantiate()
	get_tree().root.add_child(next_scene)
	pass # Replace with function body.
