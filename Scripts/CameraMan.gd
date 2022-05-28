extends KinematicBody2D

onready var camera:Camera2D = get_node("Camera")

var dragging:bool = false

var drag_mouse_pos:Vector2
var init_mouse_pos:Vector2
var init_camera_pos:Vector2

func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			dragging = event.pressed

			if(event.pressed):
				init_mouse_pos = get_viewport().get_mouse_position()
				init_camera_pos = get_position() / Global.camera_zoom

		if event.button_index == BUTTON_WHEEL_DOWN:
			Global.camera_zoom = Global.camera_zoom + set_zoom("DOWN")
			camera.zoom = Vector2(Global.camera_zoom, Global.camera_zoom)

		if event.button_index == BUTTON_WHEEL_UP:
			Global.camera_zoom = (Global.camera_zoom - set_zoom("UP"))
			camera.zoom = Vector2(Global.camera_zoom, Global.camera_zoom)

	if dragging:
		drag_mouse_pos = get_viewport().get_mouse_position()
		self.position = (init_camera_pos + init_mouse_pos - drag_mouse_pos) * Global.camera_zoom

func set_zoom(shift: String) -> float:
	var val = 0.0
	if shift == "UP":
		val = 0.01 if Global.camera_zoom >= 0.02 else 0.0
	else:
		val = 0.01
	return val
