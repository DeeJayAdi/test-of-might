@tool
extends BaseSkill
class_name SwordsmanDamageBoost

@export var damage_multiplier: float = 1.5
@export var duration: float = 5.0

func activate(player):
	if not can_use(player):
		return

	print("Aktywowano '%s'! Obrażenia x%.1f na %.1fs." % [skill_name, damage_multiplier, duration])
	
	# Ustaw mnożnik na graczu
	player.damage_multiplier = damage_multiplier
	
	# Uruchom timer do zresetowania mnożnika
	var timer = Engine.get_main_loop().create_timer(duration)
	timer.timeout.connect(Callable(self, "_on_duration_finished").bind(player))
	
	# Uruchom cooldown z bazowej klasy
	super.start_cooldown()

func _on_duration_finished(player):
	# Sprawdź czy gracz wciąż istnieje
	if is_instance_valid(player):
		player.damage_multiplier = 1.0
		print("Efekt '%s' zakończył się." % skill_name)
