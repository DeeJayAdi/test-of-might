extends CanvasLayer

@onready var image_display = $ImageDisplay
@onready var prompt_label = $Label
@onready var sfx_player = $SFXPlayer # Upewnij się, że masz ten węzeł!

var slides: Array[Texture2D] = []
var slide_sounds: Array[AudioStream] = [] # Tu wylądują dźwięki z triggera
var current_index: int = 0

# Funkcja start przyjmuje teraz dwa argumenty
func start(images_to_show: Array[Texture2D], sounds_to_play: Array[AudioStream]):
	slides = images_to_show
	slide_sounds = sounds_to_play # Zapisujemy dźwięki
	current_index = 0
	
	if slides.is_empty():
		finish()
		return

	visible = true
	get_tree().paused = true
	
	show_current_slide()

func show_current_slide():
	image_display.texture = slides[current_index]
	
	prompt_label.visible = false
	
	if current_index < slide_sounds.size():
		var sound = slide_sounds[current_index]

		if sound != null:
			sfx_player.stream = sound
			sfx_player.play()
		else:
			pass 
	
	var timer = get_tree().create_timer(3.0, true, false, true)
	timer.timeout.connect(func(): prompt_label.visible = true)

func _input(event):
	if not visible:
		return

	if event.is_action_pressed("ui_accept"):
		next_slide()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_cancel"):
		finish()
		get_viewport().set_input_as_handled()

func next_slide():
	current_index += 1
	if current_index < slides.size():
		show_current_slide()
	else:
		finish()

func finish():
	get_tree().paused = false
	queue_free()
