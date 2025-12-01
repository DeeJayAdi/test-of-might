class_name StateManager extends Node

@export var initial_state: PlayerState

var current_state: PlayerState = null
var states: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await owner.ready
	for child in get_children():
		if child is PlayerState:
			child.player = owner
			child.state_manager = self
			states[child.name.to_lower()] = child
			
	if initial_state:
		current_state = initial_state
		current_state.enter()

func change_state(state: String):
	#obsługa nazwy stanu
	var new_state_node = states.get(state.to_lower())
	if !new_state_node:
		push_error("Nie znaleziono takiego stanu:" + state)
		return
	if current_state == new_state_node:
		return
	if current_state:
		current_state.exit()
	current_state = new_state_node
	current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
