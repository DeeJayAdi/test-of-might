extends CanvasLayer

@onready var notification_label: Label = $Notifications
@onready var minimap_root: Control = $MinimapRoot
@onready var minimap_mask: Panel = $MinimapRoot/Mask
@onready var minimap_border: Panel = $MinimapRoot/Border
@onready var minimap_viewport: SubViewport = $MinimapRoot/Mask/SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $MinimapRoot/Mask/SubViewportContainer/SubViewport/Camera2D
@onready var player_icon: Node2D = $MinimapRoot/PlayerIconRoot

# Minimap Settings
const MINIMAP_SIZE_SMALL = Vector2(200, 200)
const MINIMAP_POS_SMALL = Vector2(20, -220) 
const MINIMAP_ZOOM_SMALL = Vector2(0.15, 0.15)

const MINIMAP_SIZE_LARGE = Vector2(800, 600)
const MINIMAP_ZOOM_LARGE = Vector2(0.12, 0.12)

var is_map_expanded: bool = false
var default_corner_radius: int = 100

func _ready():
	NotificationManager.set_label(notification_label)
	
	# Initial Setup for Minimap
	update_minimap_state()
	
	await get_tree().process_frame
	var main_viewport = get_viewport()
	if main_viewport:
		minimap_viewport.world_2d = main_viewport.world_2d

func _process(_delta):
	# Update camera position
	var player = get_tree().get_first_node_in_group("player")
	if player:
		minimap_camera.global_position = player.global_position
	
	# Rotate player icon towards mouse (always update rotation)
	var screen_center = get_viewport().get_visible_rect().size / 2
	var mouse_pos = get_viewport().get_mouse_position()
	var dir = (mouse_pos - screen_center).normalized()
	player_icon.rotation = dir.angle() + PI / 2

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		is_map_expanded = not is_map_expanded
		update_minimap_state()

func update_minimap_state():
	var style_mask = minimap_mask.get_theme_stylebox("panel") as StyleBoxFlat
	var style_border = minimap_border.get_theme_stylebox("panel") as StyleBoxFlat
	
	if is_map_expanded:
		# Center the map on screen
		minimap_root.anchors_preset = Control.PRESET_CENTER
		minimap_root.size = MINIMAP_SIZE_LARGE
		minimap_root.position = (get_viewport().get_visible_rect().size - MINIMAP_SIZE_LARGE) / 2
		
		minimap_camera.zoom = MINIMAP_ZOOM_LARGE
		
		# Make it rectangular with rounded corners
		if style_mask: set_corner_radius(style_mask, 20)
		if style_border: set_corner_radius(style_border, 20)
		
		player_icon.position = MINIMAP_SIZE_LARGE / 2
		
	else:
		# Bottom-Left Corner
		minimap_root.anchors_preset = Control.PRESET_BOTTOM_LEFT
		minimap_root.size = MINIMAP_SIZE_SMALL
		minimap_root.position = Vector2(20, get_viewport().get_visible_rect().size.y - 220)
		
		minimap_camera.zoom = MINIMAP_ZOOM_SMALL
		
		# Make it circular
		if style_mask: set_corner_radius(style_mask, 100)
		if style_border: set_corner_radius(style_border, 100)
		
		player_icon.position = MINIMAP_SIZE_SMALL / 2

func set_corner_radius(style: StyleBoxFlat, radius: int):
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
