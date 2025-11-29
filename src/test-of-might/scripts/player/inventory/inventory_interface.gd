extends Control

func add_item(item: ItemData) -> bool:
	var backpack: GridContainer = $CanvasLayer/ColorRect/Inventory/Backpack/GridContainer
	for child in backpack.get_children():
		if child.name.begins_with("ItemSlot"):
			var slot: Panel = child
			if slot.item == null:
				slot.item = item
				slot.update_ui()
				return true
	return false

func get_current_weapon() ->ItemData:
	var equipedItems = get_equipedItems()
	for slot in equipedItems:
		if slot.slot_type == "Weapon":
			return slot.item
	return null
	

func get_equipedItems():
	var container = $CanvasLayer/ColorRect/Inventory/CharacterSheet/GridContainer
	var list = []
	for child in container.get_children():
		if(child is Panel and child.slot_type != "" and child.item != null):
			list.append(child)

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
		return true
	return false