extends Node2D

@export var dialog_file: String = "res://assets/Dialog/textLines/Old_Man_CAVE/First.json"

@onready var prompt_label = $Label
@onready var interaction_area = $InteractionArea

var dialog_data: Array = []

func _ready():
	var file = FileAccess.open(dialog_file, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		dialog_data = JSON.parse_string(content)
	else:
		print("BŁĄD: Nie można wczytać pliku dialogu: %s" % dialog_file)
	
	prompt_label.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		prompt_label.visible = true
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.append(self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		prompt_label.visible = false
		if body.has_method("get_closest_interactable"):
			body.interactables_in_range.erase(self)

func interact():
	print("Rozpoczynam dialog z NPC")
	DialogBox.start_dialog(dialog_data)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.global_position.x < global_position.x:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false


func _on_interaction_area_body_entered(body: Node2D) -> void:
	pass
