extends Control

func add_item(item: ItemData) -> bool:
	var backpack: GridContainer = $CanvasLayer/ColorRect/Inventory/Backpack/GridContainer
	for child in backpack.get_children():
		if child.name.begins_with("ItemSlot"):
			var slot: Panel = child
			if slot.item_data == null:
				slot.set_item(item)
				return true
	return false