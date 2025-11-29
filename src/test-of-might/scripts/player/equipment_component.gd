extends Node
class_name EquipmentComponent

signal weapon_changed(weapon_res)

@export var current_weapon: Resource # Typ: WeaponItem
@export var active_skill: Resource

func equip_weapon(new_weapon: Resource):
	current_weapon = new_weapon
	weapon_changed.emit(current_weapon)
	# Tutaj możesz też pokazać/ukryć Marker2D dla broni dystansowej
	# albo zmienić sprite broni

func unequip_weapon():
	current_weapon = null
	weapon_changed.emit(null)

func get_current_weapon():
	return current_weapon

func use_active_skill(user):
	if active_skill and active_skill.has_method("activate"):
		active_skill.activate(user)
	else:
		print("Brak aktywnej umiejętności")
