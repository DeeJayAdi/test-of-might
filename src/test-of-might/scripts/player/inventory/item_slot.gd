extends Panel

@onready var icon: TextureRect = $icon
@export var item: ItemData



func _read() -> void:
	update_ui()

func update_ui() -> void:
	if not item:
		icon.texture = null
		return
		
	icon.texture = item.icon
	tooltip_text = item.item_name

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item:
		return
		
	var preview = duplicate()
	var c = Control.new()
	c.add_child(preview)
	preview.position -= Vector2(25,25)
	preview.self_modulate = Color.TRANSPARENT
	c.modulate = Color(c.modulate, 0.5)
	
	set_drag_preview(c)
	icon.hide()
	return self

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return true
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var tmp = item
	item = data.item
	data.item = tmp
	icon.show()
	data.icon.show()
	update_ui()
	data.update_ui()
	
