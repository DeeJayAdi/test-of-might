class_name Bullet
extends CharacterBody2D

@export var speed = 150
@export var damage = 50
@export var pierce = 1

var current_pierce = 0

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("loop")

func _physics_process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	velocity = direction * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			$AnimatedSprite2D.play("hit")
			body.take_damage(damage)
		current_pierce += 1
		if current_pierce >= pierce:
			queue_free()
