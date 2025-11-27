extends Area2D

@export var images: Array[Texture2D] = []
@export var sound_effects: Array[AudioStream] = []
@export var play_on_start: bool = false 
@export var cutscene_id: String = "" 

var cutscene_scene = preload("res://scenes/Cutscenes/Cutscene.tscn")

func _ready():
	if cutscene_id != "" and SaveManager.is_cutscene_played(cutscene_id):
		queue_free()
		return

	if play_on_start:
		call_deferred("play_cutscene")
	else:
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "player":
		if images.is_empty(): return
		play_cutscene()

func play_cutscene():
	if cutscene_id != "":
		SaveManager.mark_cutscene_as_played(cutscene_id)
		
	var instance = cutscene_scene.instantiate()
	get_tree().get_root().add_child(instance)
	instance.start(images, sound_effects)
	
	queue_free()
