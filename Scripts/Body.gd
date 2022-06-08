extends KinematicBody2D

const TYPE: String = "BODY"
const Math: GDScript = preload("res://Scripts/FrameWorks/Math.gd")
const Enginex: GDScript = preload("res://Scripts/FrameWorks/Engine.gd")

onready var math:Object = Math.new()
onready var engine:Object = Enginex.new()

export var body_name: String = "earth"
export var mass: float = 5.972 # x10^24 kg
export var density: float = 5.514 # g/cm^3
export var gravity: float = 9.8 # m/s^2 (surface)
export var diameter: float = 1.2756 # x10^4 km
export var temperature: float = 0.0 # K

onready var color = self.get_modulate()

var bodies: Array = []
var delta: float = 0.0
var time: float = Global.UNIVERSE_TIME # t = t_universe
var velocity: Vector2 = Vector2(0,0) * 0 # V * (pixel/t)
var velocity_norm: Vector2 = Vector2(0,0)
var momentum: Vector2 = Vector2(0,0) # kg/m^2/s
var momentum_norm: Vector2 = Vector2(0,0)
var speed: float = 0.0
var speed_norm: float = 0.0
var displacement: float = 0.0

func _ready() -> void:
	transform(true)
	# yield(get_tree().create_timer(0.2), "timeout")
	# velocity = engine.set_random_initial_velocity()
	# var _x = move_and_slide(velocity)
	pass


func _physics_process(delt) -> void:
	delta = delt
	preset()
	transform(false)
	kinetic()


func preset() -> void:
	time = Global.UNIVERSE_TIME
	bodies = engine.get_all_bodies(self, get_parent())


func transform(init: bool) -> void:
	var volume: float = mass / density # v = m/p
	diameter = pow((volume * 3) / (4 * math.pi), (1.0/3.0)) * 2 # d = (v*3/4*pi)^(1/3) * 2
	gravity = ((math.G * mass) / pow(diameter/2, 2))  # g = G*M/r^2
	self.scale = engine.lerp_vector2(self.scale, Vector2(diameter,diameter), 0.3) if not init else Vector2(diameter,diameter)
	self.z_index = int(diameter)
	self.set_modulate(color)


func kinetic() -> void:
	var relational_data: Array = engine.get_all_relational_data(self, bodies) # F = G * m1 * m2 / r^2
	var angular_vector_sum: Vector2 = math.sum_of_angle(relational_data) # F1v = Σ F2v + F3v + F4v...
	var force_net: float = math.pythagorean_theorem(angular_vector_sum.x, angular_vector_sum.y) # F1_net = √(F1x^2)+(F1y^2)
	velocity += (angular_vector_sum  * force_net) * time # →v_new = →v + (F1→v * F1_net) * t
	velocity_norm = engine.normalize(velocity, time, delta)
	momentum = velocity * mass # →p = m * →v
	speed = math.pythagorean_theorem(velocity.x, velocity.y) # s = √(→vx^2)+(→vy^2)
	momentum_norm = engine.normalize(momentum, time, delta)
	speed_norm = engine.normalize(speed, time, delta)

	self.get_node("RayCast2D").set_cast_to(engine.normalize(velocity, time, delta) / diameter)
	var _catch_move_and_slide = move_and_slide(velocity)


func collide(retained: float, obj: KinematicBody2D) -> void:
	print(retained)
	self.get_node("Area2D/Area").set_deferred("disabled", true)
	var merge_time: float =  ((1/time) / (speed + obj.speed)) * (time * 10) # mt = ((1/t) / (s1 + s2)) * (t * 10)

	#var body = load("res://Prefabs/Planet.tscn").instance()
	#get_tree().get_current_scene().get_node_or_null("World").add_child(body)

	yield(get_tree().create_timer(merge_time), "timeout")
	queue_free()


func _on_Area2D_area_entered(area) -> void:
	var obj: KinematicBody2D = area.get_parent()
	var final_momentum: Vector2 = momentum - obj.momentum # →pf = →p1 - →p2
	var final_momentum_norm: Vector2 = engine.normalize(final_momentum, time, delta)
	var final: Vector2 = final_momentum / (mass + obj.mass)  # →vf = →pf / (m1 + m2)
	var final_norm: Vector2 = (final_momentum_norm / (mass + obj.mass))

	# Artificially created, not the accurate representation
	var momentum_norm_scalar = math.pythagorean_theorem(final_momentum_norm.x, final_momentum_norm.y) # →p_scalar = √(→px^2)+(→py^2)
	displacement = engine.cap(100 - (momentum_norm_scalar / pow(mass, 2)) , -100.0, 100.0)  # d = 100 - (→p / m^2) (capped -100 to 100)
	var loss = engine.cap(displacement + obj.displacement, -100.0, 100.0) # l = d1 - d2 (capped -100 to 100)

	if mass >= obj.mass:
		color = (self.get_modulate() + (obj.get_modulate() * loss/100)) / 2 # →c = →c1 + (→c2 * l/100) / 2
		color.a = 1.0 # ignore alpha value
		mass = mass + (obj.mass * (loss/100)) # mf = m1 + (m2 * l/100)
		obj.collide(100 - loss, self)
		velocity -= final
