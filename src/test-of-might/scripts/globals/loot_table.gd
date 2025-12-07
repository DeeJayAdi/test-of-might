extends Resource
class_name LootTable

@export var items: Dictionary[ItemData, float] = {}


func get_drops() -> Array[ItemData]:
	var drops: Array[ItemData] = []
	
	if items.is_empty():
		return drops
	
	for item in items.keys():
		var chance = items[item]
		
		# Jeżeli jest gwarantowany drop, to losujemy bez niego, bo tak czy siak wypadnie
		if chance >= 1.0:
			drops.append(item)
		else:
			if randf() <= chance:
				drops.append(item)
				
	return drops
