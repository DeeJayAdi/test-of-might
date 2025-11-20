extends Node

var effects: Dictionary = {}
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	await owner.ready
	for child in get_children():
		if child is AudioStreamPlayer2D:
			effects[child.name.to_lower()] = child

func play_sound_effect(effect: String):
	var effect_to_play: AudioStreamPlayer2D = effects.get("sfx" + effect.to_lower())
	if effect_to_play:
		print("playing sound")
		effect_to_play.volume_db = rng.randf_range(-10.0, 0.0)
		effect_to_play.pitch_scale = rng.randf_range(0.9, 1.1)
		effect_to_play.play()
