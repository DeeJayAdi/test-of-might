extends PanelContainer

func set_data(item: ItemData):
	var name_lbl = $VBoxContainer/Name
	var desc_lbl = $VBoxContainer/Description
	var stat_lbl = $VBoxContainer/Stats
	
	if not item: 
		return
	
	# Safety check: ensure data is not null before trying to read it
	name_lbl.text = item.item_name
	desc_lbl.text = item.description
	
	# 3. Use the helper function we made in Step 1
	stat_lbl.text = item.get_stat_text()
	
	stat_lbl.visible = stat_lbl.text != ""
