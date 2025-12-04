extends Node2D

@onready var boss: CaveBoss = $YSort/CaveBoss

func _ready() -> void:
	if boss:
		boss.died.connect(_on_boss_died)

func _on_boss_died() -> void:
	print("Boss has been killed! Unlocking Level 2.")
	var global = get_node("/root/Global")
	if not global.is_level_unlocked("level2"):
		global.unlock_level("level2")
		global.save_unlocked_levels()
		NotificationManager.show_notification("New level unlocked: Level 2", 5.0)

		# Po 3 sekundach przenieś do menu map
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/map_menu/map_menu.tscn")
