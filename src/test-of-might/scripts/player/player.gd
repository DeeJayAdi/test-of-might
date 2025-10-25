extends CharacterBody2D

signal health_changed(current_health, max_health)
signal died

@export var max_health: int = 100
@export var speed = 100

var current_health: int

func _ready():
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _physics_process(delta: float):
	if current_health <= 0:
		return 

	get_input()
	move_and_slide()

func get_input():
	var dir = Input.get_vector("left","right","up","down")
	velocity = dir * speed

## Funkcja do zadawania obrażeń tej postaci.
func take_damage(amount: int):
	if current_health <= 0:
		return

	current_health -= amount

	current_health = clamp(current_health, 0, max_health)

	print("Otrzymano obrażenia, aktualne ZD: ", current_health)

	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()

## Funkcja do leczenia tej postaci.
func heal(amount: int):
	if current_health == max_health:
		return
		
	current_health += amount
	
	current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)

## Funkcja wywoływana, gdy zdrowie spadnie do 0.
func die():
	print("Gracz umarł!")
	died.emit()
	queue_free()
