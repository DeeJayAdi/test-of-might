extends Area2D
class_name PickableItem

var item_resource: ItemData

func setup(_item: ItemData):
	item_resource = _item
	if item_resource.icon:
		$Sprite2D.texture = item_resource.icon

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var success = body.inventory.add_item(item_resource)
		
		if success:
			queue_free()
