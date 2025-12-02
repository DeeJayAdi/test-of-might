@tool
extends Resource
class_name BaseSkill

@export var skill_name: String = "Base Skill"
@export var required_level: int = 1
@export var cooldown: float = 10.0

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
	start_cooldown()

func start_cooldown():
	is_on_cooldown = true
	var timer = Engine.get_main_loop().create_timer(cooldown)
	timer.timeout.connect(_on_cooldown_finished)
	print("Umiejętność '%s' wchodzi na %.1fs cooldownu." % [skill_name, cooldown])
	NotificationManager.start_cooldown_notification(skill_name, cooldown)


func _on_cooldown_finished():
	is_on_cooldown = false
	print("Umiejętność '%s' jest ponownie dostępna." % skill_name)
