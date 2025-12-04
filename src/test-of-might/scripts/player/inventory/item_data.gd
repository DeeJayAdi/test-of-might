extends Resource
class_name ItemData

@export var item_name: String = ""
@export var price: int = 10
@export var rarity: String = ""
@export var type: String = ""
@export var subtype: String = ""
@export var icon: Texture2D
@export var placeholder: Texture2D

@export var damage: int
@export var defense: int
@export var attack_range: float
@export var attack_speed: float
@export var effect: String = ""

@export_multiline var description: String = ""
#potki
@export var stack_size: int = 1       
@export var default_quantity: int = 1  
@export var heal_instant: int = 0      
@export var heal_per_second: int = 0   
@export var heal_duration: float = 0.0 

@export var animation: PackedScene

func get_stat_text() -> String:
	var text = ""
	match type:
		"weapon":
			text = "Damage: +%s \n" % damage
		"helmet":
			text = "Armor: +%s \n" % defense
		"armor":
			text = "Armor: +%s \n" % defense
		"boots":
			text = "Armor: +%s \n" % defense

	return text
	
