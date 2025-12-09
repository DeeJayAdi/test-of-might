@tool
extends Resource
class_name BaseSkill

@export var skill_name: String = "Base Skill"
@export var required_level: int = 1
@export var cooldown: float = 10.0
@export var skill_slot: int = 0

var is_on_cooldown: bool = false

# Wirtualna funkcja sprawdzająca, czy można użyć umiejętności
func can_use(player) -> bool:
	if is_on_cooldown:
		print("Umiejętność '%s' jest na cooldownie." % skill_name)
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

func start_cooldown(player):
	is_on_cooldown = true
	var timer = Engine.get_main_loop().create_timer(cooldown)
	timer.timeout.connect(func(): _on_cooldown_finished(player))
	print("Umiejętność '%s' wchodzi na %.1fs cooldownu." % [skill_name, cooldown])
	NotificationManager.start_cooldown_notification(skill_name, cooldown)
	_start_cooldown_visuals(player)


func _on_cooldown_finished(player):
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
	

func _start_cooldown_visuals(player):
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
	cooldown_label.text = "%.1f" % cooldown
	tween.tween_method(func(val): cooldown_label.text = "%.1f" % val, cooldown, 0.0, cooldown)
