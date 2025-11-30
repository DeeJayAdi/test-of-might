extends Node
class_name SFXComponent

@export var sfx_walk: AudioStreamPlayer2D
@export var sfx_attack: AudioStreamPlayer2D
@export var sfx_hurt: AudioStreamPlayer2D

var rng = RandomNumberGenerator.new()

func play_walk():
	if !sfx_walk.playing:
		sfx_walk.pitch_scale = rng.randf_range(0.8, 1.2)
		sfx_walk.play()

func play_attack():
	sfx_attack.pitch_scale = rng.randf_range(0.9, 1.1)
	sfx_attack.play()

func play_hurt():
	sfx_hurt.play()
