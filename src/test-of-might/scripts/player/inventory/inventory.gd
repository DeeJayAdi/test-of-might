extends Panel


@onready var inventory_canvas: CanvasLayer = get_parent().get_parent()
@onready var scene_root: Control = owner

var is_open: bool = false
var player_node: CharacterBody2D = null
var dark_overlay: ColorRect = null

func _ready():
	if not is_open:
		inventory_canvas.visible = false

func set_player_node(player: CharacterBody2D):
	player_node = player
	var slots = find_children("*", "Panel", true, false)
	
	for slot in slots:
		if slot.has_method("set_player"):
			slot.set_player(player)

func _input(event): #changed from _unhandled_input if any input errors arise it might be this
	if event.is_action_pressed("inventory"):
		if player_node and is_instance_valid(player_node) and player_node.current_state != player_node.State.DEATH:
			toggle()
			get_viewport().set_input_as_handled()

func toggle():
	if is_open:
		close()
	else:
		open()

func open():
	if is_open or not player_node:
		return
	
	is_open = true
	inventory_canvas.visible = true 
	
	if player_node.ui_layer:
		player_node.ui_layer.visible = false
		
	if dark_overlay == null:
		dark_overlay = ColorRect.new()
		dark_overlay.color = Color(0, 0, 0, 0.5) 
		dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dark_overlay.size = get_viewport_rect().size
		get_tree().get_root().add_child(dark_overlay)
		dark_overlay.move_to_front()
	
	scene_root.move_to_front() 
func close():
	if not is_open:
		return

	is_open = false
	inventory_canvas.visible = false 
	
	if player_node and is_instance_valid(player_node) and player_node.ui_layer:
		player_node.ui_layer.visible = true
		
	if dark_overlay:
		dark_overlay.queue_free()
		dark_overlay = null
