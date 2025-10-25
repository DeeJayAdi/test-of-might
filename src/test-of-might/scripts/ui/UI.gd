extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel

func update_health_display(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	health_label.text = "HP: " + str(current_health) + " / " + str(max_health)
