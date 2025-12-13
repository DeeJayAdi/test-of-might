class_name FireBall
extends CharacterBody2D

@export var speed = 600
@export var damage = 20
@export var pierce = 1

var current_pierce = 0

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("loop")

func _physics_process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	velocity = direction * speed
	var collision = move_and_collide(velocity * delta)
	if collision and !collision.get_collider().has_method("take_damage"):
		$AnimatedSprite2D.play("hit")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		return
	if body != self:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		current_pierce += 1
		if current_pierce >= pierce:
			$AnimatedSprite2D.play("hit")
			speed = 0


func _on_AnimatedSprite2D_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "hit":
		queue_free()
