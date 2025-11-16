extends Panel
@onready var icon: TextureRect = $icon
@export var item: ItemData
@export var slot_type: String = ""  

var current_placeholder: Texture2D #= icon.texture

signal item_equipped(item: ItemData)
signal item_unequipped(item: ItemData)

func _ready() -> void:
	current_placeholder = icon.texture
	update_ui()

func update_ui() -> void:
	if not item:
		#icon.texture = null
		icon.texture = current_placeholder
		tooltip_text = ""
	else:
		icon.texture = item.icon
		current_placeholder = item.placeholder
		tooltip_text = item.item_name

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item:
		return
	var preview = duplicate()
	var c = Control.new()
	c.add_child(preview)
	preview.position -= Vector2(25, 25)
	preview.self_modulate = Color.TRANSPARENT
	c.modulate = Color(c.modulate, 0.5)
	set_drag_preview(c)
	icon.hide()
	return self
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data or not data.item:
		return false
	return data.item.type == slot_type
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_FORBIDDEN)
		return
	
	# Swap items
	var tmp = item
	item = data.item
	data.item = tmp
	
	icon.show()
	data.icon.show()
	update_ui()
	data.update_ui()
	# Emit signals to update stats
	if item:
		emit_signal("item_equipped", item)
	if tmp:
		emit_signal("item_unequipped", tmp)
		
