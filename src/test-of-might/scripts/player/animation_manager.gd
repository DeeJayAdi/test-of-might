class_name AnimationManager extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Player = get_parent() as Player


func play_animation(animation_name: String) -> void:
	var full_animation_name = animation_name + "_" + player.facing_direction
	
	if animated_sprite.animation == full_animation_name:
		return
	if not animated_sprite.sprite_frames.has_animation(full_animation_name):
		push_error("Brak animacji: " + full_animation_name)
		return
	animated_sprite.animation = full_animation_name
	animated_sprite.play()



func connect_animation_finished(callback_object: Callable, callback_method: int) -> void:
	animated_sprite.animation_finished.connect(callback_object, callback_method)

func disconnect_animation_finished(callback_object: Callable) -> void:
	animated_sprite.animation_finished.disconnect(callback_object)


func is_animation_finished_connected(callback_object: Callable) -> bool:
	return animated_sprite.animation_finished.is_connected(callback_object)

func set_animation_speed_scale(speed_scale: float) -> void:
	animated_sprite.speed_scale = speed_scale


func get_current_animation() -> String:
	return animated_sprite.animation
