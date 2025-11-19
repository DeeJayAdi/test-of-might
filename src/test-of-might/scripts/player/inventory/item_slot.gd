extends Panel

@onready var icon: TextureRect = $icon
@export var item: ItemData
@onready var quantity_label: Label = $QuantityLabel
var quantity: int = 0
var player_node: CharacterBody2D = null



func _read() -> void:
	if item:
		quantity = item.default_quantity
	update_ui()

func update_ui() -> void:
	if not item:
		icon.texture = null
		if quantity_label: quantity_label.visible = false
		quantity = 0 
		return
		
	if quantity <= 0:
		quantity = max(1, item.default_quantity)
	icon.texture = item.icon
	tooltip_text = item.item_name
	if quantity > 1:
		quantity_label.text = str(quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false 

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
	if "quantity" in data:
		var tmp_quantity = quantity
		quantity = data.quantity
		data.quantity = tmp_quantity
	else:
		quantity = 1
	icon.show()
	data.icon.show()
	update_ui()
	data.update_ui()
	
func set_player(player):
	player_node = player

func use_item():
	if not item:
		return
	if not player_node:
		return
	if item.type == "potion":
		print("Using potion:", item.item_name)
		if item.heal_instant > 0:
			player_node.heal(item.heal_instant)
		if item.heal_per_second > 0 and item.heal_duration > 0:
			player_node.heal_over_time(item.heal_per_second, item.heal_duration)
		quantity -= 1
		if quantity <= 0:
			item = null		
		update_ui()
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		use_item()
