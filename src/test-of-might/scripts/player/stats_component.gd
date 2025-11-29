extends Node
class_name StatsComponent

signal health_changed(current, max)
signal died
signal xp_changed(current, next_lvl)
signal level_up(new_lvl)
signal gold_changed(current_gold)

@export_group("Konfiguracja")
@export var character_class: String = "swordsman"
@export var max_health: int = 100
@export var gold: int = 100 

# System XP
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100

# Zmienne wewnętrzne
var current_health: int

func _ready():
	current_health = max_health
	# Inicjalizacja przy starcie
	call_deferred("emit_all_signals")

func emit_all_signals():
	health_changed.emit(current_health, max_health)
	xp_changed.emit(current_xp, xp_to_next_level)
	gold_changed.emit(gold)
	level_up.emit(level)

func take_damage(amount: int):
	var def = UpdateStats.get_total_defense()
	var final_damage = max(0, amount - def)
	#var final_damage = amount
	
	current_health -= final_damage
	current_health = clamp(current_health, 0, max_health)
	
	print("Otrzymano obrażenia, HP: ", current_health)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()

func heal(amount: int):
	if current_health == max_health: return
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func add_xp(amount: int):
	current_xp += amount
	print("Zdobyto %s XP. Stan: %s/%s" % [amount, current_xp, xp_to_next_level])
	xp_changed.emit(current_xp, xp_to_next_level)
	_check_level_up()

func add_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)

func _check_level_up():
	while current_xp >= xp_to_next_level:
		level += 1
		current_xp -= xp_to_next_level
		xp_to_next_level = int(100 * pow(1.2, level - 1))
		
		max_health += 10
		current_health = max_health
		# attack_damage += 2 <- To teraz powinno być w CombatComponent lub modyfikatorach
		
		print("AWANS! Poziom: ", level)
		level_up.emit(level)
		health_changed.emit(current_health, max_health)
		xp_changed.emit(current_xp, xp_to_next_level)

# Funkcja dla Save Systemu
func get_save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"level": level,
		"current_xp": current_xp,
		"xp_to_next_level": xp_to_next_level,
		"gold": gold,
		"character_class": character_class
	}

func load_save_data(data: Dictionary):
	current_health = data.get("current_health", max_health)
	level = data.get("level", 1)
	current_xp = data.get("current_xp", 0)
	xp_to_next_level = data.get("xp_to_next_level", 100)
	gold = data.get("gold", 100)
	character_class = data.get("character_class", "swordsman")
	emit_all_signals()
