extends Area2D
class_name InteractionComponent

var interactables_in_range: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("interact"):
		interactables_in_range.append(body)

func _on_body_exited(body):
	interactables_in_range.erase(body)

func interact_closest():
	if interactables_in_range.is_empty():
		return
		
	var closest_obj = null
	var min_dist_sq = INF 
	
	for obj in interactables_in_range:
		if not is_instance_valid(obj): continue
		
		var dist_sq = global_position.distance_squared_to(obj.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_obj = obj
			
	if closest_obj:
		closest_obj.interact()
