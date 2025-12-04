extends Panel

@onready var icon: TextureRect = $icon
@export var slot_type: String = ""  

var current_placeholder: Texture2D 

@export var item: ItemData:
	set(value):
		item = value
		if is_node_ready():
			update_ui() 
			_update_global_stats()

func _ready() -> void:
	current_placeholder = icon.texture
	update_ui()
	_update_global_stats()

func _exit_tree():
	UpdateStats.update_equipment_slot(get_instance_id(), null)

# --- 2. LOGIC ---

func update_ui() -> void:
	if not icon: return
	
	if not item:
		icon.texture = current_placeholder
		tooltip_text = "" # Keeps tooltip hidden if empty
	else:
		icon.texture = item.icon
		if item.placeholder:
			current_placeholder = item.placeholder
			
		# CHANGED: We set this to any string to tell Godot "Yes, I have a tooltip".
		# The text itself doesn't matter because _make_custom_tooltip overrides it.
		tooltip_text = "sanctum oficium at agilum" 

# ADDED: This function creates the visual box
func _make_custom_tooltip(_for_text: String) -> Object:
	# 1. Load your Tooltip Scene
	var tooltip_scene = preload("res://scenes/ui/custom_tooltip.tscn").instantiate()
	
	# 2. Pass the ItemData resource directly to the tooltip
	tooltip_scene.set_data(item)
	
	return tooltip_scene

func _update_global_stats():
	pass;

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item: return null
	
	var preview = TextureRect.new()
	preview.texture = icon.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(50, 50)
	
	var c = Control.new()
	c.add_child(preview)
	preview.position = -preview.size / 2 
	preview.self_modulate = Color(1, 1, 1, 0.8) 
	set_drag_preview(c)
	
	icon.hide()

	return self

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data or not "item" in data: return false
	if data.item == null: return false 
	return data.item.type == slot_type
	
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data): return
	
	var my_old_item = item
	var incoming_item = data.item
	
	item = incoming_item
	
	data.item = my_old_item
	
	icon.show()
	if data.has_method("update_ui"):
		data.update_ui()
		data.icon.show()
		
