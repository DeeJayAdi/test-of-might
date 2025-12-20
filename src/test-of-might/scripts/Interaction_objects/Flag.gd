extends Node2D
@export var default_animation_name: String = "nazwa_twojej_animacji" 
var is_animated: bool = true 
@onready var prompt_label = $Label
@onready var interaction_area = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D 
func _ready():
	prompt_label.visible = false
	animated_sprite.play(default_animation_name)
	is_animated = true
func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		prompt_label.visible = true
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.append(self)
func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		prompt_label.visible = false
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.erase(self)
func interact():
	# 1. ODBLOKOWANIE POZIOMU (Używamy Global, tak jak chciałeś)
	var global = get_node("/root/Global")
	
	# Tutaj wpisz nazwę poziomu, który chcesz odblokować (np. "level2" jeśli kończysz 1)
	if not global.is_level_unlocked("level1"):
		global.unlock_level("level1")
		global.save_unlocked_levels() # To zapisuje plik unlocked_levels.save
		NotificationManager.show_notification("New level unlocked: Level 1", 5.0)

	# 2. ANIMACJA
	if is_animated:
		animated_sprite.stop()
		print("Flaga zdobyta - animacja stop")
		is_animated = false
	else:
		animated_sprite.play(default_animation_name)
		is_animated = true

	# 3. CZEKAMY 5 SEKUND
	await get_tree().create_timer(5).timeout

	# 4. ZAPISUJEMY BOHATERA (HP, EXP, EQ)
	# SaveManager zapisze wszystko co jest w grupie "Persist" (czyli gracza)
	print("Zapisuję statystyki bohatera...")
	SaveManager.save_game()
	
	# Czekamy jedną klatkę, żeby plik zdążył się zapisać przed zmianą sceny
	await get_tree().process_frame 
	
	# 5. PRZEJŚCIE DO MAPY CAVE
	Global.SwitchScene("res://maps/cave/cave.tscn")
