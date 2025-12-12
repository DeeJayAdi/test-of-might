extends Node

func apply_effect(target: Node, type: String, power: float, duration: float) -> void:
	if type == "" or duration <= 0:
		return
		
	if target.has_node(type + "_effect"):
		var existing = target.get_node(type + "_effect")
		existing.timer = 0.0 
		existing.duration = duration
		return

	var effect_instance = StatusEffect.new(type, power, duration)
	effect_instance.name = type + "_effect"
	
	target.add_child(effect_instance)
