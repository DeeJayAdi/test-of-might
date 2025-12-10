@tool
extends Resource
class_name BaseSkill

@export var skill_name: String = "Base Skill"
@export var required_level: int = 1
@export var cooldown: float = 10.0
@export var skill_slot: int = 0

var is_on_cooldown: bool = false
var _active_timer: SceneTreeTimer = null

# Wirtualna funkcja sprawdzająca, czy można użyć umiejętności
func can_use(player) -> bool:
	if is_on_cooldown:
		var timer_is_valid = _active_timer != null and is_instance_valid(_active_timer) and _active_timer.time_left > 0
		
		if not timer_is_valid:
			print("DEBUG: Wykryto błąd cooldownu (brak timera). Naprawiam skill '%s'." % skill_name)
			is_on_cooldown = false
			_active_timer = null

			return true 
		print("Umiejętność '%s' jest na cooldownie (%.1fs)." % [skill_name, _active_timer.time_left])
		return false

	if player.stats_comp.level < required_level:
		print("Nie masz wymaganego poziomu (%s) dla umiejętności '%s'." % [required_level, skill_name])
		return false
	return true

# Wirtualna funkcja aktywująca umiejętność
func activate(player):
	# Ta funkcja powinna być nadpisana przez konkretne umiejętności
	print("Aktywowano bazową umiejętność (nic się nie dzieje).")
	
	# Uruchom cooldown
	start_cooldown(player)

func start_cooldown(player, custom_time: float = -1.0):
	if custom_time == 0.0:
		is_on_cooldown = false
		return

	is_on_cooldown = true
	var time_to_wait = custom_time if custom_time > 0 else cooldown
	if player.is_inside_tree():
		_active_timer = player.get_tree().create_timer(time_to_wait)
		_active_timer.timeout.connect(func(): _on_cooldown_finished(player))
		
		print("Skill '%s' cooldown: %.2fs" % [skill_name, time_to_wait])
		_start_cooldown_visuals(player, time_to_wait)
	else:
		print("BŁĄD: Gracz poza drzewem sceny, cooldown anulowany.")
		is_on_cooldown = false


func _on_cooldown_finished(player):
	if not is_instance_valid(player):
		return
	is_on_cooldown = false
	print("Umiejętność '%s' jest ponownie dostępna." % skill_name)
	var ui_hud = player.get_node_or_null("UI/HUD")
	if not ui_hud:
		return
	var skills_container = ui_hud.get_node_or_null("Skills")
	if not skills_container:
		return
	var skill_node_name = "Skill_" + str(skill_slot)
	var skill_node = skills_container.get_node_or_null(skill_node_name)
	if not skill_node:
		return
	var cooldown_label = skill_node.get_node_or_null("Cooldown")
	if not cooldown_label:
		return
	cooldown_label.text = ""
	

func _start_cooldown_visuals(player, time_val: float):
	if not is_instance_valid(player):
		return
	var ui_hud = player.get_node_or_null("UI/HUD")
	if not ui_hud:
		print("Error: Could not find UI/HUD node.")
		return

	var skills_container = ui_hud.get_node_or_null("Skills")
	if not skills_container:
		print("Error: Could not find Skills container.")
		return

	var skill_node_name = "Skill_" + str(skill_slot)
	var skill_node = skills_container.get_node_or_null(skill_node_name)
	if not skill_node:
		print("Error: Could not find skill node: " + skill_node_name)
		return

	var cooldown_label = skill_node.get_node_or_null("Cooldown")
	if not cooldown_label:
		print("Error: Could not find Cooldown label in " + skill_node_name)
		return

	var tween = player.create_tween()
	cooldown_label.text = "%.1f" % time_val
	tween.tween_method(func(val): cooldown_label.text = "%.1f" % val, time_val, 0.0, time_val)
	
func save() -> Dictionary:
	var time_left = 0.0
	# Jeśli skill jest na CD, pobieramy ile czasu zostało z timera
	if is_on_cooldown and _active_timer:
		time_left = _active_timer.time_left
	
	return { "time_left": time_left }

func load_data(data: Dictionary, player):
	var time_left = data.get("time_left", 0.0)
	if time_left > 0.0:
		print("Wczytano cooldown: %.2fs" % time_left)
		# Wznawiamy cooldown z czasem wczytanym z pliku
		start_cooldown(player, time_left)
	else:
		is_on_cooldown = false
