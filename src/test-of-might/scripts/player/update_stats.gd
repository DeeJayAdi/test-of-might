extends Node

signal stats_updated(stats_package: Dictionary)

var base_stats = {
	"max_health": 100,
	"damage": 25,
	"defense": 0,
	"attack_range": 30.0,
	"attack_speed": 1.0
}

var equipped_items: Dictionary = {}

func update_equipment_slot(slot_id: int, item: ItemData):
	if item == null:
		equipped_items.erase(slot_id)
	else:
		equipped_items[slot_id] = item
	
	recalculate_stats()

func recalculate_stats():
	var total_damage = base_stats["damage"]
	var total_defense = base_stats["defense"]
	var total_range = base_stats["attack_range"]
	var total_speed_bonus = 0.0
	var total_health_bonus = 0

	for key in equipped_items:
		var item = equipped_items[key]
		if item is ItemData:
			total_damage += item.damage
			total_defense += item.defense
			total_range += item.attack_range
			total_speed_bonus += item.attack_speed

	var final_cooldown = base_stats["attack_speed"] / max(0.1, (1.0 + total_speed_bonus))
	var final_max_health = base_stats["max_health"] + total_health_bonus

	var package = {
		"Max HP": final_max_health,
		"Attack": total_damage,
		"Defense": total_defense,
		"Range": total_range,
		"Cooldown": snapped(final_cooldown, 0.01)
	}
	
	stats_updated.emit(package)

func get_total_damage() -> int:
	var dmg = base_stats["damage"]
	for key in equipped_items:
		if equipped_items[key]: dmg += equipped_items[key].damage
	return dmg

func get_total_defense() -> int:
	var def = base_stats["defense"]
	for key in equipped_items:
		if equipped_items[key]: def += equipped_items[key].defense
	return def

func get_total_range() -> float:
	var rng = base_stats["attack_range"]
	for key in equipped_items:
		if equipped_items[key]: rng += equipped_items[key].attack_range
	return rng
	
func get_total_cooldown(base_cd: float) -> float:
	var speed_bonus = 0.0
	for key in equipped_items:
		if equipped_items[key]: speed_bonus += equipped_items[key].attack_speed
	return base_cd / max(0.1, (1.0 + speed_bonus))
