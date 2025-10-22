extends CharacterBody2D

@export var speed = 100

func get_input():
	var dir = Input.get_vector("left","right","up","down")
	velocity = dir * speed
	
func _physics_process(delta: float):
	get_input()
	move_and_slide()
	
