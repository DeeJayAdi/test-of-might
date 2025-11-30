class_name UIManager extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HUD/HP/Zdrowie/TextureProgressBar
@onready var game_over_screen: Control = $Windows/PauseMenu 
@onready var inventory: Control = $Windows/Inventory
@onready var pause_menu: Control = $Windows/PauseMenu
@onready var shop: Control = $Windows/Shop
var player: Player = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	await owner.ready
	player = owner as Player

	if inventory.has_method("set_player_node"):
		inventory.set_player_node(player)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_escape()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()

func update_health_display(new_health: int, max_health: int) -> void:
	health_bar.value = new_health
	health_bar.max_value = max_health

func show_game_over_screen() -> void:
	game_over_screen.visible = true


func handle_escape() -> void:
	if inventory.is_open():
		toggle_inventory()
	elif shop.visible:
		shop.visible = false
		get_tree().paused = false
	else:
		pause_menu.visible = not pause_menu.visible
		get_tree().paused = pause_menu.visible

func toggle_inventory() -> void:
	if pause_menu.visible:
		return
		
	if inventory.has_method("toggle"):
		inventory.toggle()
