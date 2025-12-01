extends Node

var notification_queue: Array = []
var is_displaying: bool = false
var notification_label: Label
var cooldowns: Array = []

func _ready():
	# The label will be set from the UI scene
	pass

func set_label(label: Label):
	notification_label = label

func show_notification(message: String, duration: float = 3.0):
	notification_queue.append({"message": message, "duration": duration})
	if not is_displaying:
		_display_next_notification()

func _display_next_notification():
	if not cooldowns.is_empty():
		# Don't hide the label if a cooldown is active
		if notification_queue.is_empty():
			is_displaying = false
			return

	if notification_queue.is_empty():
		is_displaying = false
		if notification_label:
			notification_label.visible = false
		return

	is_displaying = true
	var notification = notification_queue.pop_front()
	
	if notification_label:
		notification_label.text = notification["message"]
		notification_label.visible = true

	await get_tree().create_timer(notification["duration"]).timeout
	_display_next_notification()

func start_cooldown_notification(skill_name: String, cooldown_time: float):
	cooldowns.append({"name": skill_name, "time_left": cooldown_time})
	if not is_displaying:
		is_displaying = true
		if notification_label:
			notification_label.visible = true
	set_process(true)

func _process(delta):
	if cooldowns.is_empty():
		set_process(false)
		if notification_queue.is_empty():
			if notification_label:
				notification_label.visible = false
			is_displaying = false
		return

	var cooldown_text = ""
	var new_cooldowns = []
	for cd in cooldowns:
		cd["time_left"] -= delta
		if cd["time_left"] > 0:
			cooldown_text += "%s - Cooldown: %.1fs\n" % [cd["name"], cd["time_left"]]
			new_cooldowns.append(cd)
	
	cooldowns = new_cooldowns

	if notification_label:
		notification_label.text = cooldown_text.strip_edges()

	if cooldowns.is_empty() and notification_queue.is_empty():
		if notification_label:
			notification_label.visible = false
		is_displaying = false
		set_process(false)

func update_cooldown(skill_name: String, time_left: float):
	if notification_label and is_displaying:
		# This function is not used anymore, but we keep it for now
		pass
