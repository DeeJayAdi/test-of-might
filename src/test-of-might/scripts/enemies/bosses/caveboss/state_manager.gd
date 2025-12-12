class_name BossStateManager extends Node

@export var initial_state: BossState

var current_state: BossState
var states: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await owner.ready
	for child in get_children():
		if child is BossState:
			child.boss = owner
			child.state_machine = self
			states[child.name.to_lower()] = child
			
	if initial_state:
		current_state = initial_state

func change_state(state: String):
	#obsługa nazwy stanu
	print("zmiana stanu na " + state)
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
	
