extends CharacterBody2D

@export var speed: float = 150.0
@export var max_hp: int = 30
@export var damage: int = 10

@export var separation_distance: float = 50.0 
@export var separation_strength: float = 4.0  
@export var bat_group_name: String = "Bats"   

# Odbicie
@export var bounce_force: float = 300.0       
@export var bounce_friction: float = 200.0    

enum State { APPEAR, CHASE, HURT, DEATH, BOUNCE }
var current_state: State = State.APPEAR

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
var target: Node2D = null
var hp: int

func _ready():
	add_to_group(bat_group_name)
	hp = max_hp
	var players = get_tree().get_nodes_in_group("player") 
	if players.size() > 0:
		target = players[0]
	
	anim_sprite.animation_finished.connect(_on_animation_finished)
	play_anim("appear")

func _physics_process(delta):
	match current_state:
		State.APPEAR:
			velocity = Vector2.ZERO
			
		State.CHASE:
			if target:
				var direction_to_player = (target.global_position - global_position).normalized()
				var desired_velocity = direction_to_player * speed
				var separation = calculate_separation()
				
				velocity = desired_velocity + (separation * separation_strength * 50.0)
				
				if velocity.length() > speed * 1.5:
					velocity = velocity.normalized() * speed * 1.5
				
				play_anim("fly")
			else:
				velocity = Vector2.ZERO
				
		State.HURT:
			velocity = Vector2.ZERO 
			
		State.BOUNCE:
			velocity = velocity.move_toward(Vector2.ZERO, bounce_friction * delta)
			play_anim("fly") 
			if velocity.length() < 10.0:
				current_state = State.CHASE
			
		State.DEATH:
			velocity = Vector2.ZERO

	move_and_slide()
	
	if current_state == State.CHASE:
		_check_player_collision()

func calculate_separation() -> Vector2:
	var separation_vector = Vector2.ZERO
	var neighbors = get_tree().get_nodes_in_group(bat_group_name)
	var count = 0
	
	for bat in neighbors:
		if bat == self:
			continue
		var distance = global_position.distance_to(bat.global_position)
		if distance < separation_distance:
			var push_dir = (global_position - bat.global_position).normalized()
			separation_vector += push_dir / (distance + 0.1)
			count += 1
			
	if count > 0:
		return separation_vector
	return Vector2.ZERO

func get_facing_direction() -> String:
	var look_target = target.global_position if target else global_position + velocity
	var dir = (look_target - global_position).normalized()
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

func play_anim(anim_name: String):
	if anim_name == "death" or anim_name == "appear" or anim_name == "hit":
		var full_name = anim_name + "_" + get_facing_direction()
		if anim_sprite.sprite_frames.has_animation(full_name):
			anim_sprite.play(full_name)
		else:
			anim_sprite.play(anim_name)
	else:
		var full_name = anim_name + "_" + get_facing_direction()
		if anim_sprite.sprite_frames.has_animation(full_name):
			anim_sprite.play(full_name)
		else:
			anim_sprite.play(anim_name)

func take_damage(amount: int, stagger: bool = true):
	if current_state == State.DEATH:
		return
		
	hp -= amount
	
	current_state = State.HURT
	play_anim("hit")

func die():
	current_state = State.DEATH
	play_anim("death")
	$CollisionShape2D.set_deferred("disabled", true)

func _on_animation_finished():
	var anim_name = anim_sprite.animation
	
	if current_state == State.APPEAR:
		current_state = State.CHASE
	
	elif current_state == State.HURT:
		if hp <= 0:
			die()
		else:
			current_state = State.CHASE
		
	elif current_state == State.DEATH:
		queue_free()

func _check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		
		if body.is_in_group("player") or body.is_in_group("Player"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
				var bounce_dir = (global_position - body.global_position).normalized()
				velocity = bounce_dir * bounce_force
				current_state = State.BOUNCE 
			break
