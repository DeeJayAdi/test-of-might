extends Control

# Ścieżki dopasowane do Twojego zdjęcia:
@onready var buy_grid = $Panel/TabContainer/Buy/BuyGrid
@onready var sell_grid = $Panel/TabContainer/Sell/SellGrid
@onready var gold_label = $Panel/GoldLabel

# Lista towarów do sprzedania (przeciągnij tu pliki .tres w Inspektorze)
@export var items_for_sale: Array[ItemData] = []

var player_ref: CharacterBody2D = null
var inventory_ref: Control = null 

func _ready():
	visible = false 

# Tę funkcję wywoła NPC
func open_shop(player, inventory):
	player_ref = player
	inventory_ref = inventory
	visible = true
	
	update_gold_ui()
	populate_buy_tab()
	populate_sell_tab()
	
	# Opcjonalnie: Pokaż myszkę, jeśli jest ukryta
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	get_tree().paused = true  # <--- TA LINIA ZATRZYMUJE GRĘ
	print("PAUZA WŁĄCZONA")

# Funkcja do przycisku wyjścia (dodaj guzik "X" i podłącz go tutaj)
func _on_close_button_pressed():
	visible = false
	get_tree().paused = false # <--- TA LINIA WZNAWIA GRĘ
	print("PAUZA WYŁĄCZONA")

func update_gold_ui():
	if player_ref:
		# Upewnij się, że w player.gd masz zmienną "gold"
		gold_label.text = "YourGold: " + str(player_ref.stats_comp.gold)

# --- ZAKŁADKA BUY ---
func populate_buy_tab():
	# Czyścimy stare przyciski, żeby się nie dublowały przy każdym otwarciu
	for child in buy_grid.get_children():
		child.queue_free()
		
	for item in items_for_sale:
		var btn = Button.new()
		# Ustawiamy tekst na przycisku
		btn.text = item.item_name + "\n" + str(item.price) + " G"
		btn.icon = item.icon
		
		# Wygląd przycisku
		btn.custom_minimum_size = Vector2(100, 100)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		
		# Podłączamy funkcję kupowania
		btn.pressed.connect(func(): _on_buy_item_pressed(item))
		
		buy_grid.add_child(btn)

func _on_buy_item_pressed(item: ItemData):
	if player_ref.stats_comp.gold >= item.price:
		# Wywołujemy funkcję add_item z inventory.gd (którą dodałeś wcześniej)
		var added = inventory_ref.add_item(item, 1)
		
		if added:
			player_ref.stats_comp.update_gold(-item.price)
			update_gold_ui()
			print("Kupiono: ", item.item_name)
		else:
			print("Brak miejsca!")
	else:
		print("Bieda! Nie stać cię.")

# --- ZAKŁADKA SELL ---
func populate_sell_tab():
	for child in sell_grid.get_children():
		child.queue_free()
	
	# Szukamy slotów w ekwipunku gracza
	var slots = inventory_ref.find_children("*", "Panel", true, false)
	
	for slot in slots:
		# Jeśli w slocie jest przedmiot
		if slot.get("item") != null:
			var item = slot.item
			var btn = Button.new()
			var sell_price = int(item.price * 0.5) # Sprzedaż za 50% ceny
			
			btn.text = item.item_name + "\nSell: " + str(sell_price)
			btn.icon = item.icon
			btn.custom_minimum_size = Vector2(100, 100)
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			
			# Kliknięcie sprzedaje
			btn.pressed.connect(func(): _on_sell_item_pressed(slot, item, sell_price))
			
			sell_grid.add_child(btn)

func _on_sell_item_pressed(slot_ref, item, value):
	# Usuwanie przedmiotu ze slotu
	if slot_ref.quantity > 1:
		slot_ref.quantity -= 1
		slot_ref.update_ui()
	else:
		slot_ref.item = null
		slot_ref.quantity = 0
		slot_ref.update_ui()
	
	player_ref.stats_comp.update_gold(value)
	update_gold_ui()
	
	# Odświeżamy listę sprzedaży, bo właśnie sprzedaliśmy przedmiot
	populate_sell_tab()


func _on_close_pressed(): 
	visible = false
	get_tree().paused = false  # <--- TA LINIA MUSI TU BYĆ!
	print("Gra odpalona!")     # Dodaj ten print dla pewności
