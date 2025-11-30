extends Control

signal equipment_changed

func add_item(item: ItemData) -> bool:
	var backpack: GridContainer = $CanvasLayer/ColorRect/Inventory/Backpack/GridContainer
	for child in backpack.get_children():
		if child.name.begins_with("ItemSlot"):
			var slot: Panel = child
			if slot.item == null:
				slot.item = item
				slot.update_ui()
				equipment_changed.emit()
				return true
	return false

func get_current_weapon() ->ItemData:
	var equipedItems = get_equipedItems()
	for slot in equipedItems:
		if slot.slot_type == "weapon":
			return slot.item
	return null
	

func get_equipedItems():
	var container = $CanvasLayer/ColorRect/Inventory/CharacterSheet/GridContainer
	var list = []
	for child in container.get_children():
		if(child is Panel and child.slot_type != "" and child.item != null):
			list.append(child)
	return list

#swaps weapon between weapon slot and swap slot
func swap_weapon() -> bool:
	var container = $CanvasLayer/ColorRect/Inventory/CharacterSheet/GridContainer
	var weapon_slot: Panel = null
	var swap_slot: Panel = null
	for child in container.get_children():
		if child.name == "Weapon":
			weapon_slot = child
		if child.name == "SwapSlot":
			swap_slot = child
	if weapon_slot != null and swap_slot != null:
		var temp_item = weapon_slot.item
		weapon_slot.item = swap_slot.item
		swap_slot.item = temp_item
		weapon_slot.update_ui()
		swap_slot.update_ui()
		equipment_changed.emit()
		return true
	return false
	
	
func toggle() -> void:
	var inventory = $CanvasLayer/ColorRect/Inventory
	if inventory:
		inventory.toggle()
		
func set_player_node(node: Node) -> void:
	var inventory = $CanvasLayer/ColorRect/Inventory
	if inventory and inventory.has_method("set_player_node"):
		inventory.set_player_node(node)


func is_open() -> bool:
	var inventory = $CanvasLayer/ColorRect/Inventory
	if inventory:
		return inventory.is_open
	return false
