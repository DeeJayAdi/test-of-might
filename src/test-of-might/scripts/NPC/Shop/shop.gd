extends Control

# Ścieżki dopasowane do Twojego zdjęcia:
@onready var buy_grid = $Panel/TabContainer/Buy/BuyGrid
@onready var sell_grid = $Panel/TabContainer/Sell/SellGrid
@onready var gold_label = $Panel/GoldLabel

# Lista towarów do sprzedania (przeciągnij tu pliki .tres w Inspektorze)
@export var items_for_sale: Array[ItemData] = []

var player_ref: CharacterBody2D = null
var inventory_ref: Control = null 
var is_transaction_pending: bool = false

func _ready():
	visible = false 

# Tę funkcję wywoła NPC
func open_shop(player, inventory):
	player_ref = player
	inventory_ref = inventory
	is_transaction_pending = false
	visible = true
	
	update_gold_ui()
	populate_buy_tab()
	populate_sell_tab()
	
	# Opcjonalnie: Pokaż myszkę, jeśli jest ukryta
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	get_tree().paused = true 
	print("PAUZA WŁĄCZONA")

# Funkcja do przycisku wyjścia
func _on_close_button_pressed():
	_on_close_pressed()

func update_gold_ui():
	if player_ref:
		gold_label.text = "YourGold: " + str(player_ref.stats_comp.gold)

# --- ZAKŁADKA BUY ---
func populate_buy_tab():
	for child in buy_grid.get_children():
		child.queue_free()
		
	for item in items_for_sale:
		var btn = Button.new()
		btn.text = item.item_name + "\n" + str(item.price) + " G"
		btn.icon = item.icon
		btn.custom_minimum_size = Vector2(100, 100)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		
		btn.pressed.connect(func(): _on_buy_item_pressed(item))
		buy_grid.add_child(btn)

func _on_buy_item_pressed(item: ItemData):
	if is_transaction_pending:
		return 

	if player_ref.stats_comp.gold >= item.price:
		
		# ### TUTAJ BRAKOWAŁO: WŁĄCZENIE BLOKADY ###
		is_transaction_pending = true 
		# -------------------------------------------

		var added = inventory_ref.add_item(item, 1)
		
		if added:
			player_ref.stats_comp.update_gold(-item.price)
			update_gold_ui()
			print("Kupiono: ", item.item_name)
		else:
			print("Brak miejsca!")
			
		# ### TUTAJ BRAKOWAŁO: WYŁĄCZENIE BLOKADY PO CZASIE ###
		get_tree().create_timer(0.2).timeout.connect(func(): is_transaction_pending = false)
		# -----------------------------------------------------

	else:
		print("Bieda! Nie stać cię.")

# --- ZAKŁADKA SELL ---
func populate_sell_tab():
	for child in sell_grid.get_children():
		child.queue_free()
	
	var slots = inventory_ref.find_children("*", "Panel", true, false)
	
	for slot in slots:
		if not "quantity" in slot:
			continue

		if slot.get("item") != null:
			var item = slot.item
			var btn = Button.new()
			var sell_price = int(item.price * 0.5)
			
			var qty_text = ""
			if slot.quantity > 1:
				qty_text = " (x" + str(slot.quantity) + ")"

			btn.text = item.item_name + qty_text + "\nSell: " + str(sell_price)
			btn.icon = item.icon
			btn.custom_minimum_size = Vector2(100, 100)
			btn.expand_icon = true
			
			btn.pressed.connect(func(): _on_sell_item_pressed(slot, item, sell_price))
			
			sell_grid.add_child(btn)

func _on_sell_item_pressed(slot_ref, item, value):
	if is_transaction_pending:
		return 
	
	if slot_ref.item != item:
		populate_sell_tab() 
		return

	# ### TUTAJ BRAKOWAŁO: WŁĄCZENIE BLOKADY ###
	is_transaction_pending = true 
	# -------------------------------------------

	if slot_ref.quantity > 1:
		slot_ref.quantity -= 1
		slot_ref.update_ui()
	else:
		slot_ref.item = null
		slot_ref.quantity = 0
		slot_ref.update_ui()

	if player_ref.stats_comp.has_method("update_gold"):
		player_ref.stats_comp.update_gold(value)
	else:
		player_ref.update_gold(value)
	update_gold_ui()

	populate_sell_tab()
	
	# ### TUTAJ BRAKOWAŁO: WYŁĄCZENIE BLOKADY PO CZASIE ###
	get_tree().create_timer(0.2).timeout.connect(func(): is_transaction_pending = false)
	# -----------------------------------------------------


func _on_close_pressed(): 
	visible = false
	get_tree().paused = false 
	print("Gra odpalona!")
