class_name StatusEffect
extends Node

var effect_type: String
var power: float
var duration: float
var timer: float = 0.0

#for effects like slow or weaken so that the enemies are not perma-debuffed
var original_val: float

func _init(p_type: String, p_power: float, p_duration: float):
	effect_type = p_type
	power = p_power
	duration = p_duration

func _ready() -> void:
	match effect_type:
		"slow":
			var parent = get_parent()
			if "movement_speed" in parent:
				original_val = parent.movement_speed
				parent.movement_speed = original_val * power 

func _process(delta: float) -> void:
	var parent = get_parent()
	
	match effect_type:
		"burn":
			if parent.has_method("take_damage"):
				parent.take_damage(power * delta) # 
	
	# 3. HANDLE TIMER
	timer += delta
	if timer >= duration:
		queue_free()

func _exit_tree() -> void:
	# 4. CLEANUP (Restore stats)
	match effect_type:
		"slow":
			var parent = get_parent()
			if parent and "movement_speed" in parent:
				parent.movement_speed = original_val
