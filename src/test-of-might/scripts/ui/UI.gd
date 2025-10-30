extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel

# Optional level/EXP bar reference (projects use different names)
var level_bar: TextureProgressBar = null

func _ready() -> void:
	# Try common node names used in scenes for the EXP/level bar
	if has_node("Pasek_EXPA"):
		level_bar = $Pasek_EXPA
	elif has_node("LvL/Pasek_EXPA"):
		level_bar = get_node_or_null("LvL/Pasek_EXPA")
	elif has_node("LvL/PASEK_EXPA"):
		level_bar = get_node_or_null("LvL/PASEK_EXPA")
	elif has_node("Level/LevelBar"):
		level_bar = get_node_or_null("Level/LevelBar")

func update_health_display(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health

	var target = clamp(current_health, 0, max_health)
	var duration := 0.25

	var t = create_tween()
	t.tween_property(health_bar, "value", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	health_label.text = "HP: " + str(target) + " / " + str(max_health)

func update_level_display(current_value: int, max_value: int) -> void:
	if level_bar == null:
		return
	level_bar.max_value = max_value
	var target = clamp(current_value, 0, max_value)
	var duration := 0.4
	create_tween().tween_property(level_bar, "value", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
