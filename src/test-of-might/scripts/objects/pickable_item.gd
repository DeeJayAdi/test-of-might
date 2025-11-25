extends Node2D
class_name PickableItem

@export var item_resource: ItemData

# Ustawienia animacji lewitowania
@export var float_amplitude: float = 5.0
@export var float_speed: float = 4.0
var _time_offset: float = 0.5
var _original_sprite_pos: Vector2

var is_being_picked_up = false

func setup(_item: ItemData):
	item_resource = _item
	_update_texture()

func _ready() -> void:
	_update_texture()
	_time_offset = randf_range(0.0, 10.0)
	_original_sprite_pos = $Sprite2D.position

func _process(delta: float) -> void:
	if is_being_picked_up:
		return
		
	var new_y = sin(Time.get_ticks_msec() / 1000.0 * float_speed + _time_offset) * float_amplitude
	$Sprite2D.position.y = _original_sprite_pos.y + new_y

func _update_texture():
	if item_resource and item_resource.icon:
		$Sprite2D.texture = item_resource.icon

func _on_body_entered(body):
	if is_being_picked_up:
		return
		
	if body.is_in_group("player"):
		if body.get("inventory_instance") == null: 
			return
			
		var success = body.inventory_instance.add_item(item_resource)
		
		if success:
			collect_animation()

func collect_animation():
	is_being_picked_up = true
	
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property($Sprite2D, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.3)
	tween.tween_property($Sprite2D, "position:y", -20.0, 0.3).as_relative() # Lekko unieś przy podnoszeniu
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
