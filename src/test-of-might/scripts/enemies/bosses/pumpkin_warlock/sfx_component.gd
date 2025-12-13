extends Node2D

func play_sound_effect(effect: String):
	# get children AudioStreamPlayer2D nodes
	var sfx_players = get_children().filter(func(c):
		return c is AudioStreamPlayer2D
	)
	for player in sfx_players:
		if player.name == effect:
			player.play()
			return
	print("Sound effect not found: " + effect)
