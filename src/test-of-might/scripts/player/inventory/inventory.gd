extends Panel


@onready var inventory_canvas: CanvasLayer = get_parent().get_parent()
@onready var scene_root: Control = owner

var is_open: bool = false
var player_node: CharacterBody2D = null
var dark_overlay: ColorRect = null

func _ready():
	if not is_open:
		inventory_canvas.visible = false
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", 0)

func set_player_node(player: CharacterBody2D):
	player_node = player
	var slots = find_children("*", "Panel", true, false)
	
	for slot in slots:
		if slot.has_method("set_player"):
			slot.set_player(player)



func toggle():
	if is_open:
		close()
	else:
		open()

func open():
	if is_open or not player_node:
		return
	
	is_open = true
	inventory_canvas.visible = true 
	get_tree().paused = true
	
	if player_node.ui_layer:
		player_node.ui_layer.visible = false
		
	if dark_overlay == null:
		dark_overlay = ColorRect.new()
		dark_overlay.color = Color(0, 0, 0, 0.5) 
		dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dark_overlay.size = get_viewport_rect().size
		get_tree().get_root().add_child(dark_overlay)
		dark_overlay.move_to_front()
	
	scene_root.move_to_front()
	 
func close():
	if not is_open:
		return

	is_open = false
	inventory_canvas.visible = false 
	get_tree().paused = false
	
	if player_node and is_instance_valid(player_node) and player_node.ui_layer:
		player_node.ui_layer.visible = true
		
	if dark_overlay:
		dark_overlay.queue_free()
		dark_overlay = null


func add_item(new_item: ItemData, quantity: int = 1) -> bool:
	var slots = find_children("*", "Panel", true, false)
	
	if new_item.stack_size > 1:
		for slot in slots:
			if slot.get("item") == new_item and slot.quantity < new_item.stack_size:
				slot.quantity += quantity
				slot.update_ui()
				return true 
	for slot in slots:
		if slot.get("item") == null:
			slot.item = new_item
			slot.quantity = quantity
			slot.update_ui()
			return true 

	print("Ekwipunek pełny!")
	return false 

func _exit_tree():
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", 0.5)

func save() -> Dictionary:
	var items_data = []
	var slots = find_children("*", "Panel", true, false)
	
	for slot in slots:
		# Sprawdzamy czy slot ma skrypt item_slot.gd i czy ma przedmiot
		if slot.has_method("get_item") and slot.get_item() != null:
			var item_data = {
				"item_path": slot.get_item().resource_path,
				"slot_index": slot.get_index()
			}
			if "quantity" in slot:
				item_data["quantity"] = slot.quantity
			items_data.append(item_data)
	
	return {
		"items": items_data
	}

func load_data(data: Dictionary):
	# 1. Wyczyść obecny ekwipunek
	var slots = find_children("*", "Panel", true, false)
	for slot in slots:
		if slot.has_method("set_item"):
			slot.set_item(null)
		if "quantity" in slot:
			slot.quantity = 0
		if slot.has_method("update_ui"):
			slot.update_ui()
		
	# 2. Wczytaj zapisane przedmioty
	if data.has("items"):
		for item_entry in data["items"]:
			var path = item_entry["item_path"]
			var qty = item_entry.get("quantity", 1) # Domyślnie 1, jeśli brak
			var idx = item_entry.get("slot_index", -1)
			
			if ResourceLoader.exists(path):
				var item_res = load(path)
				if idx != -1 and idx < slots.size():
					var target_slot = slots[idx]
					if target_slot.has_method("set_item"):
						target_slot.set_item(item_res)
					if "quantity" in target_slot:
						target_slot.quantity = qty
					if target_slot.has_method("update_ui"):
						target_slot.update_ui()
				else:
					add_item(item_res, qty)
			else:
				print("BŁĄD: Nie znaleziono pliku przedmiotu: ", path)
