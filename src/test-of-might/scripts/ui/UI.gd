extends CanvasLayer

@onready var notification_label: Label = $Notifications

func _ready():
	NotificationManager.set_label(notification_label)
