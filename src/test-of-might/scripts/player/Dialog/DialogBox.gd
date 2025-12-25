extends CanvasLayer

signal dialog_finished

@onready var speaker_label = $Panel/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var text_label = $Panel/HBoxContainer/VBoxContainer/TextLabel
@onready var avatar_texture = $Panel/HBoxContainer/Avatar

@onready var typewriter_timer = $TypewriterTimer
@onready var ContinuePrompt = $Panel/ContinuePrompt

var dialog_queue = []
var current_line_index = 0
var is_typing = false

func _ready():
	typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)
	pass

func start_dialog(dialog_data: Array):
	if dialog_data.is_empty():
		return

	get_tree().paused = true
	self.visible = true

	dialog_queue = dialog_data
	current_line_index = 0

	_show_current_line()

func _show_current_line():
	var line_data = dialog_queue[current_line_index]
	speaker_label.text = line_data.get("speaker", "")
	
	# Załaduj awatar
	var avatar_path = line_data.get("avatar", "")
	if avatar_path != "" and ResourceLoader.exists(avatar_path):
		avatar_texture.texture = load(avatar_path)
	else:
		avatar_texture.texture = null
		
	text_label.text = line_data.get("text", "")
	text_label.visible_characters = 0 
	
	is_typing = true
	ContinuePrompt.visible = false 
	
	typewriter_timer.stop()
	typewriter_timer.start()


func _advance_dialog():
	current_line_index += 1
	if current_line_index >= dialog_queue.size():
		_end_dialog()
	else:
		_show_current_line()

func _end_dialog():
	get_tree().paused = false
	self.visible = false
	dialog_queue = []
	emit_signal("dialog_finished")

func _on_typewriter_timer_timeout():
	if text_label.visible_characters < text_label.get_total_character_count():
		text_label.visible_characters += 1
	else:
		typewriter_timer.stop()
		is_typing = false
		ContinuePrompt.visible = true 

func _skip_typing():
	typewriter_timer.stop()
	text_label.visible_characters = -1 
	is_typing = false
	ContinuePrompt.visible = true 

func _input(event):
	if not self.visible:
		return
		
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			_skip_typing()
		else:
			_advance_dialog()
		get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		get_viewport().set_input_as_handled()
