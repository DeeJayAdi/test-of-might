extends Node2D

# Usuwamy dialogi, bo to sklep
@onready var prompt_label = $Label
@onready var interaction_area = $InteractionArea

func _ready():
	prompt_label.visible = false
	# To zostaje bez zmian - łączy sygnały
	if not interaction_area.body_entered.is_connected(_on_body_entered):
		interaction_area.body_entered.connect(_on_body_entered)
	if not interaction_area.body_exited.is_connected(_on_body_exited):
		interaction_area.body_exited.connect(_on_body_exited)

# To zostaje DOKŁADNIE TAK SAMO - dzięki temu gracz wykrywa NPC
func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("Player"): # Dla pewności obie wielkości liter
		prompt_label.visible = true
		if "interactables_in_range" in body:
			body.interactables_in_range.append(self) # Dodajemy TEGO NPC do listy gracza

func _on_body_exited(body):
	if body.is_in_group("player") or body.is_in_group("Player"):
		prompt_label.visible = false
		if "interactables_in_range" in body:
			body.interactables_in_range.erase(self)

# --- TU JEST ZMIANA ---
# Zamiast DialogBox, odpalamy Sklep
func interact():
	print("Otwieram sklep...")
	
	# Obracanie postaci do gracza (z Twojego starego kodu)
	var player = get_tree().get_first_node_in_group("Player") # Upewnij się co do dużej litery w grupie!
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	if player:
		# Obracanie sprite'a
		if player.global_position.x < global_position.x:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
			
		# LOGIKA SKLEPU
		var shop_ui = player.get_node_or_null("UI/Shop")
		var inventory_instance = player.inventory_instance
		
		if inventory_instance:
			var inventory_script = inventory_instance.get_node("CanvasLayer/ColorRect/Inventory")
			if shop_ui and inventory_script:
				shop_ui.open_shop(player, inventory_script)
			else:
				print("Błąd: Brak UI Sklepu lub ścieżka do Inventory jest zła.")
		else:
			print("Błąd: Inventory instance nie istnieje.")
