extends Panel

@onready var icon: TextureRect = $icon
@export var item: ItemData
@onready var quantity_label: Label = $QuantityLabel
var quantity: int = 0
var player_node: CharacterBody2D = null



func _ready() -> void:
	if item:
		quantity = item.default_quantity
	update_ui()

func update_ui() -> void:
	if not item:
		icon.texture = null
		if quantity_label: quantity_label.visible = false
		quantity = 0 
		tooltip_text = "placeholder"
		return
		
	icon.texture = item.icon
	tooltip_text = item.item_name
	if quantity > 1:
		quantity_label.text = str(quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false 
	
	tooltip_text = item.item_name

func _make_custom_tooltip(for_text: String) -> Object:
	var tooltip_scene = preload("res://scenes/ui/custom_tooltip.tscn").instantiate()
	tooltip_scene.set_data(self.item)
	return tooltip_scene

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
	#icon.hide()
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

	var context_menu = PopupMenu.new()
	add_child(context_menu)
	context_menu.add_item("Use Item", 0)
	
	var is_usable = (item.heal_instant > 0) or (item.heal_per_second > 0 and item.heal_duration > 0)

	if not is_usable:
		context_menu.set_item_disabled(0, true)
		
	context_menu.add_item("Destroy Item", 1)
	context_menu.id_pressed.connect(_on_context_menu_item_selected.bind(context_menu))
	context_menu.popup_hide.connect(context_menu.queue_free)
	context_menu.popup(Rect2i(get_global_mouse_position(), Vector2i.ZERO))

func _on_context_menu_item_selected(id: int, menu: PopupMenu):
	match id:
		0: 
			_perform_use_logic()
		1: 
			_perform_destroy_logic()
	
	menu.queue_free()

func _perform_use_logic():
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

func _perform_destroy_logic():
	print("Destroying item:", item.item_name)
	
	item = null
	quantity = 0
	
	update_ui()
		
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		use_item()
