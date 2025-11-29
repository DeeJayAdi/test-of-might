extends CanvasLayer
class_name UIManager

# Referencje do okien
@onready var inventory_window = $Windows/Inventory
@onready var shop_window = $Windows/Shop
@onready var pause_menu = $Windows/PauseMenu

# Referencje do HUD
@onready var hp_bar = $HUD/HP/Zdrowie/TextureProgressBar
@onready var xp_bar = $"HUD/LvL/LVL+Pasek/Pasek_EXPA"
@onready var lvl_label = $"HUD/LvL/LVL+Pasek/TEXT_LVL"

func _ready():
	# Reset widoczności
	inventory_window.visible = false
	shop_window.visible = false
	pause_menu.visible = false

# --- Metody odświeżania HUD ---
func update_health_bar(current, max_val):
	if hp_bar:
		hp_bar.value = current
		hp_bar.max_value = max_val

func update_xp_bar(current, max_val):
	if xp_bar:
		xp_bar.value = current
		xp_bar.max_value = max_val

func update_level_text(lvl):
	if lvl_label:
		lvl_label.text = str(lvl)

# --- Obsługa Inputu (ESC / I) ---
func handle_back_action() -> bool:
	# 1. Zamknij UI gry (Inventory/Shop)
	if inventory_window.visible:
		inventory_window.visible = false
		return true
	if shop_window.visible:
		shop_window.visible = false
		return true
		
	# 2. Obsłuż Pauzę
	if pause_menu.visible:
		toggle_pause(false)
		return true
	else:
		toggle_pause(true)
		return true

func toggle_inventory():
	if shop_window.visible: shop_window.visible = false
	inventory_window.visible = not inventory_window.visible

func toggle_pause(is_paused: bool):
	pause_menu.visible = is_paused
	get_tree().paused = is_paused
