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

func save() -> Dictionary:
	var items_data = []
	var slots = find_children("*", "Panel", true, false)
	
	print("--- ROZPOCZYNAM ZAPIS EKWIPUNKU ---")
	
	# Używamy pętli z indeksem 'i', żeby wiedzieć, który to numer na liście globalnej
	for i in range(slots.size()):
		var slot = slots[i]
		
		# Sprawdzamy czy slot ma przedmiot
		if "item" in slot and slot.item != null:
			var path = slot.item.resource_path
			
			if path == "":
				print("Błąd: Przedmiot bez ścieżki w slocie ", i)
				continue
				
			items_data.append({
				"item_path": path,
				"quantity": slot.quantity if "quantity" in slot else 1,
				"saved_index": i # <--- ZMIANA: Zapisujemy ten konkretny numer z listy
			})
			print("Zapisano: ", slot.item.resource_name, " pod indeksem globalnym: ", i)
	
	return { "items": items_data }

func load_data(data: Dictionary):
	print("--- ROZPOCZYNAM WCZYTYWANIE EKWIPUNKU ---")
	
	# 1. Pobieramy tę samą listę slotów co przy zapisie
	var slots = find_children("*", "Panel", true, false)
	
	# 2. Czyścimy wszystko
	for slot in slots:
		if "item" in slot:
			slot.item = null
			if "quantity" in slot: slot.quantity = 0
			if slot.has_method("update_ui"): slot.update_ui()
		
	# 3. Wczytujemy
	if data.has("items"):
		for item_entry in data["items"]:
			var path = item_entry["item_path"]
			var qty = item_entry["quantity"]
			var idx = item_entry["saved_index"] # <--- ZMIANA: Używamy indeksu globalnego
			
			if ResourceLoader.exists(path):
				var item_res = load(path)
				
				# Celujemy idealnie w ten sam slot
				if idx >= 0 and idx < slots.size():
					var s = slots[idx]
					if "item" in s:
						s.item = item_res
						if "quantity" in s: s.quantity = qty
						if s.has_method("update_ui"): s.update_ui()
						print("SUKCES: Wczytano ", item_res.resource_name, " do slotu #", idx)
				else:
					print("Błąd: Indeks poza zakresem: ", idx)
			else:
				print("Błąd: Plik nie istnieje: ", path)
