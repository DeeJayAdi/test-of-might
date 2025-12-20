extends Control

const LOADING_STATES = ["Loading", "Loading.", "Loading..", "Loading..."]
const TIME_PER_UPDATE = 0.5
const MIN_LOADING_TIME = 2.0

@onready var loading_label: Label = $Label

var current_state_index: int = 0
var elapsed_time: float = 0.4
var time_visible: float = 1.0
var scene_loaded: bool = false
var loaded_scene: PackedScene
var global_node 

func _ready():
	global_node = get_node("/root/Global") 
	if loading_label:
		loading_label.text = LOADING_STATES[0]
	else:
		print("Error: 'Label' node not found as a child of the LoadingScreen.")


	ResourceLoader.load_threaded_request(global_node.next_scene_path)


func _process(delta: float):
	elapsed_time += delta
	time_visible += delta

	if elapsed_time >= TIME_PER_UPDATE:
		elapsed_time = 0.0
		current_state_index = (current_state_index + 1) % LOADING_STATES.size()
		loading_label.text = LOADING_STATES[current_state_index]
   

	if not scene_loaded:
		var status = ResourceLoader.load_threaded_get_status(global_node.next_scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			scene_loaded = true
			loaded_scene = ResourceLoader.load_threaded_get(global_node.next_scene_path)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			print("Failed to load scene: " + global_node.next_scene_path)
			get_tree().change_scene_to_file("res://scenes/menu/Main_Menu.tscn")
			return


	if scene_loaded and time_visible >= MIN_LOADING_TIME:
		

		if global_node and global_node.has_method("_stop_music"):
			global_node._stop_music()
		else:
			var music_node = get_node_or_null("/root/PersistentMusic")
			if music_node and music_node.has_method("_stop_music"):
				music_node._stop_music()
			else:
				print("LoadingScreen: Could not find a node with _stop_music() to stop the music.")

		get_tree().change_scene_to_packed(loaded_scene)
