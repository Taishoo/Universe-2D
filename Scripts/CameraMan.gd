extends KinematicBody2D

onready var camera:Camera2D = get_node("Camera")

var dragging:bool = false
var zoom_speed = 0.01
onready var zoom = camera.zoom.x

var drag_mouse_pos:Vector2
var init_mouse_pos:Vector2
var init_camera_pos:Vector2

func _ready() -> void:
	pass

func _input(event) -> void:

	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			dragging = event.pressed

			if(event.pressed):
				init_mouse_pos = get_viewport().get_mouse_position()
				init_camera_pos = get_position() / zoom

		if event.button_index == BUTTON_WHEEL_DOWN:
			zoom = zoom + set_zoom("DOWN")
			camera.zoom = Vector2(zoom,zoom)
		if event.button_index == BUTTON_WHEEL_UP:
			zoom = (zoom - set_zoom("UP"))
			camera.zoom = Vector2(zoom,zoom)

	if dragging:
		drag_mouse_pos = get_viewport().get_mouse_position()
		self.position = (init_camera_pos + init_mouse_pos - drag_mouse_pos) * zoom

func set_zoom(shift: String) -> float:
	var val = 0.0
	if shift == "UP":
		val = 0.01 if zoom >= 0.02 else 0.0
	else:
		val = 0.01
	return val
