#klasa obsługująca życie xp i złoto
class_name StatsComponent extends Node

signal health_changed(current_health, max_health)
signal died
signal xp_changed(current_xp, xp_to_next_level)
signal level_up(new_level)
signal gold_changed(current_gold)

var current_health: int = max_health
@onready var player: CharacterBody2D = get_parent()
@onready var state_manager: StateManager = player.get_node("StateManager") as StateManager
@onready var sfx_comp: SFXComponent = player.get_node("SfxComponent") as SFXComponent
@onready var xp_bar = get_node("../UI/HUD/LvL/LVL+Pasek/Pasek_EXPA")

@export var max_health: int = 100
@export var gold: int = 100
@export var attack_radius: float = 30.0
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.9
@export var crit_chance: float = 0.15  # 15% szansy
@export var crit_multiplier: float = 2.0
@export var heavy_attack_damage: int = 75
@export var heavy_attack_radius: float = 45.0
@export var heavy_attack_cooldown: float = 1.2
@export var speed: float = 200.0
@export var run_multiplier: float = 1.5
@export var character_class: String = "swordsman"
@export var active_skill: BaseSkill
@export var skill_1: BaseSkill
@export var skill_2: BaseSkill
@export var skill_3: BaseSkill
@export var skill_4: BaseSkill

var skills: Dictionary = {}
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100
var damage_multiplier: float = 1.0


func _ready() -> void:
	await owner.ready
	level_up.connect(_on_level_up)
	health_changed.connect(_on_health_changed)
	
	xp_changed.connect(_on_xp_changed)
	
	var data = SaveManager.get_data_for_node(owner)
	
	if data:
		character_class = data.get("character_class", "swordsman")
		level = data.get("level", 1)
		current_xp = data.get("current_xp", 0)
		xp_to_next_level = data.get("xp_to_next_level", 100)
		current_health = data.get("current_health", max_health)
	if current_health <= 0:
		current_health = max_health

	level_up.emit.call_deferred(level)
	xp_changed.emit.call_deferred(current_xp, xp_to_next_level)
	
	player.health_bar.max_value = max_health
	player.health_bar.value = current_health
	health_changed.emit.call_deferred(current_health, max_health)

	skills = {
		"skill_1": skill_1,
		"skill_2": skill_2,
		"skill_3": skill_3,
		"skill_4": skill_4
	}
	if skill_1:
		skill_1.skill_slot = 1
	if skill_2:
		skill_2.skill_slot = 2
	if skill_3:
		skill_3.skill_slot = 3
	if skill_4:
		skill_4.skill_slot = 4


func update_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)
	print("Złoto: ", gold)

func _on_health_changed(new_health, max_health_value):
	player.health_bar.value = new_health
	player.health_bar.max_value = max_health_value

func take_damage(amount: int):
	if state_manager.get_current_state_name() == "death":
		return
	sfx_comp.play_hurt()
	var def = UpdateStats.get_total_defense()

	var final_damage = max(0, amount - def)

	current_health -= final_damage
	current_health = clamp(current_health, 0, max_health)
	
	print("Otrzymano obrażenia, aktualne ZD: ", current_health)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()
	else:
		state_manager.change_state("hurt")

func die():
	print("Gracz umarł.")
	state_manager.change_state("death")
	emit_signal("died")

func heal(amount: int):
	if state_manager.get_current_state_name() == "death" or current_health == max_health:
		return
		
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func heal_over_time(amount_per_second: int, duration: float) -> void:
	if state_manager.get_current_state_name() == "death" or current_health == max_health:
		return
	var seconds_passed := 0
	while seconds_passed < int(ceil(duration)):
		if state_manager.get_current_state_name() == "death":
			return
		heal(amount_per_second)
		seconds_passed += 1
		await get_tree().create_timer(1.0).timeout

#tu je experience
func add_xp(amount: int):
	if state_manager.get_current_state_name() == "death":
		return
	current_xp += amount
	print("Zdobyto %s XP. Aktualne XP: %s/%s" % [amount, current_xp, xp_to_next_level])
	xp_changed.emit(current_xp, xp_to_next_level)
	_check_for_level_up()

func _check_for_level_up():
	while current_xp >= xp_to_next_level:
		level += 1
		current_xp -= xp_to_next_level
		xp_to_next_level = _calculate_xp_for_next_level()
		
		# --- Zwiększ statystyki przy awansie ---
		max_health += 10
		current_health = max_health # Pełne uleczenie przy awansie
		attack_damage += 2
		# ------------------------------------
		
		print("AWANS! Osiągnięto poziom %s!" % level)
		NotificationManager.show_notification("Level up! Reached level %s" % level, 4.0)
		if level == skill_2.required_level and skill_2:
			NotificationManager.show_notification("New skill unlocked: %s" % skill_2.skill_name, 4.0)
		if level == skill_3.required_level and skill_3:
			NotificationManager.show_notification("New skill unlocked: %s" % skill_3.skill_name, 4.0)
		if level == skill_4.required_level and skill_4:
			NotificationManager.show_notification("New skill unlocked: %s" % skill_4.skill_name, 4.0)

		level_up.emit(level)
		health_changed.emit(current_health, max_health)
		xp_changed.emit(current_xp, xp_to_next_level)

func _calculate_xp_for_next_level() -> int:
	# Prosty wzór na potrzebne XP, można go skomplikować
	return int(100 * pow(1.2, level - 1))


func _on_level_up(new_level):
	player.get_node("UI/HUD/LvL/LVL+Pasek/TEXT_LVL").text = str(new_level)
	
func _on_xp_changed(curr_xp, max_xp):
	if xp_bar:
		xp_bar.max_value = max_xp
		xp_bar.value = curr_xp
