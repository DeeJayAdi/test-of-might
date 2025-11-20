extends GridContainer

func _ready():
	UpdateStats.stats_updated.connect(update_ui)
	
	for child in get_children():
		if child.name.begins_with("Row_"):
			var stat_name = child.name.trim_prefix("Row_")
			
			var btn = child.get_node_or_null("Button")
			if btn:
				btn.pressed.connect(_on_plus_clicked.bind(stat_name))

	UpdateStats.recalculate_stats()

func update_ui(stats: Dictionary):
	
	for stat_name in stats:
		var node_name = "Row_" + stat_name
		
		if has_node(node_name):
			var row_node = get_node(node_name)
			var value_label = row_node.get_node_or_null("Value") 
			
			if value_label:
				value_label.text = str(stats[stat_name])

func _on_plus_clicked(stat_name: String):
	print("Plus button clicked for: ", stat_name)
