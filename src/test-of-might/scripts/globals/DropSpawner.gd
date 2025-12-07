extends Node

var pickable_item_scene = preload("res://scenes/objects/PickableItem.tscn") # Adjust path!

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func spawn_loot(loot_table: LootTable, world_position: Vector2):
	if loot_table == null:
		return
		
	var items_to_drop = loot_table.get_drops()
	
	for item in items_to_drop:
		_instantiate_item(item, world_position)

func _instantiate_item(item_data: ItemData, pos: Vector2):
	var pickable = pickable_item_scene.instantiate() as PickableItem
	pickable.setup(item_data)
	pickable.global_position = pos
	
	var random_angle = rng.randf() * TAU
	var random_distance = rng.randf_range(10.0, 30.0)
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	pickable.global_position += offset
	
	get_tree().current_scene.call_deferred("add_child", pickable)
