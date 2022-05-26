extends Timer

onready var body: KinematicBody2D = get_parent()

var time: float

func _ready() -> void:
	time = body.time * 0.01
	self.start(time)

func _physics_process(_delta) -> void:
	time = body.time * 0.01

func _on_Timer_timeout() -> void:
	body.linear_velocity = body.get_position().distance_to(body.prev_position) / body.time
	body.prev_position = body.get_position()
	self.start(time)
