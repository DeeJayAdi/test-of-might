extends Control

var sceneLink = "noLevel"

func _ready():
	var global = get_node("/root/Global")
	var btns = {
		"TutorialBtn": "level_tutorial",
		"Level1Btn": "level1",
		"Level2Btn": "level2",
		"Level3Btn": "level3",
		"Level4Btn": "level4"
	}
	var vbox = $VBoxContainer if has_node("VBoxContainer") else null
	if vbox:
		for btn_name in btns.keys():
			var btn = vbox.get_node_or_null(btn_name)
			if btn:
				btn.disabled = not global.is_level_unlocked(btns[btn_name])

func _on_tutorial_btn_pressed() -> void:
	sceneLink = "res://maps/level1/Dungeon.tscn"
	

func _on_level_1_btn_pressed() -> void:
	sceneLink = "res://maps/cave/cave.tscn"

func _on_level_2_btn_pressed() -> void:
	sceneLink = "res://maps/village/VillageMap.tscn"

func _on_level_3_btn_pressed() -> void:
	sceneLink = "noLevel"

func _on_level_4_btn_pressed() -> void:
	sceneLink = "noLevel"

func _on_start_game_btn_pressed() -> void:
	if sceneLink == "noLevel":
		$VBoxContainer2/ErrorLabel.text = "Choose level to continue"
		return
		
	$VBoxContainer2/ErrorLabel.text = ""
	get_node("/root/Global").SwitchScene(sceneLink)
	Global.SwitchScene(sceneLink)

func _play_Sound():
	$sfxHover.play()


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Main_Menu.tscn")
