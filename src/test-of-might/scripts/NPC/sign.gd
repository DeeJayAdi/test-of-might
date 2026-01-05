extends Node2D

@export var dialog_file: String

@onready var prompt_label = $Label
@onready var interaction_area = $InteractionArea

var dialog_data: Array = []
var has_been_read: bool = false

func _ready():
	var file = FileAccess.open(dialog_file, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		dialog_data = JSON.parse_string(content)
	else:
		print("BŁĄD: Nie można wczytać pliku dialogu: %s" % dialog_file)
	
	prompt_label.visible = false


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = true
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.append(self)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = false
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.erase(self) 

func interact():
	if has_been_read:
		return
		
	print("Rozpoczynam dialog z NPC")
	DialogBox.start_dialog(dialog_data)
	
	has_been_read = true
	prompt_label.visible = false
