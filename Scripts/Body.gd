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
var prespawned: bool = true

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

	if not prespawned:
		self.get_node("Area2D/Area").set_deferred("disabled", true)
		yield(get_tree().create_timer(1/time), "timeout")
		self.get_node("Area2D/Area").set_deferred("disabled", false)

	if get_name() == "Theia":
		yield(get_tree().create_timer(0.2), "timeout")
		#velocity = (Vector2(1,1) * 0.84) * time
		velocity = (Vector2(1,0) * 4.00) * time
		var _x = move_and_slide(velocity)


func _physics_process(deltap) -> void:
	delta = deltap
	preset()
	transform(false)
	kinetic()


func preset() -> void:
	time = Global.UNIVERSE_TIME
	bodies = engine.get_all_bodies(self, get_parent())


func transform(init: bool) -> void:
	var volume: float = mass / density # v = m/p
	diameter = pow((volume * 3) / (4 * math.pi), (1.0/3.0)) * 2 # d = (v*3/4*pi)^(1/3) * 2
	gravity = (math.G * mass) / max(pow(diameter/2, 2), 0.001)  # g = G*M/r^2
	self.scale = engine.lerp_vector2(self.scale, Vector2(diameter,diameter), 0.3) if not init else Vector2(diameter,diameter)
	self.z_index = int(diameter)
	#self.set_modulate(color)
	mass = max(mass, 0.0000001)


func kinetic() -> void:
	var relational_data: Array = engine.get_all_relational_data(self, bodies) # F = G * m1 * m2 / r^2
	var angular_vector_sum: Vector2 = engine.sum_of_angle(relational_data, time, delta) # F1v = Σ F2v + F3v + F4v...
	var force_net: float = math.pythagorean_theorem(angular_vector_sum.x, angular_vector_sum.y) # F1_net = √(F1x^2)+(F1y^2)
	velocity = engine.lerp_vector2(velocity + ((angular_vector_sum  * force_net) * time), Vector2.ZERO, 0)  # →v_new = lerp(→v + (F1→v * F1_net) * t, 0, 0)
	velocity_norm = engine.normalize(velocity, time, delta)
	momentum = velocity * mass # →p = m * →v
	speed = math.pythagorean_theorem(velocity.x, velocity.y) # s = √(→vx^2)+(→vy^2)
	momentum_norm = engine.normalize(momentum, time, delta)
	speed_norm = engine.normalize(speed, time, delta)

	
	self.get_node("Position").rotation = velocity.angle()
	self.get_node("RayCast2D").set_cast_to(engine.normalize(velocity, time, delta) / diameter)
	var _catch_move_and_slide: Vector2 = move_and_slide(velocity)


func collide(retained: float, obj: KinematicBody2D) -> void:
	self.get_node("Area2D/Area").set_deferred("disabled", true)
	var merge_time: float =  ((1/time) / (speed + obj.speed)) * (time) # mt = ((1/t) / (s1 + s2)) * (t * 10)
	var mass_left: float = mass * (retained/100) # mf = mi (mr/100)
	var density_diff: float = abs(density - obj.density) 
	
	if mass >= (obj.mass * 0.01) and mass >= 0.005:
		#var count: int = round(engine.generate_random_float(1.0, 9.0))
		var count: int = 10
		var distribution: Array = engine.generate_probability_list(count, 1.0, 9999.0)
		var positions: Array = get_node("Position").get_children()
		var index: int = 0

		for fragment in distribution:
			var add_angle: float = positions[index].get_angle_to(self.get_position()) * density_diff
			var collision_angle: Vector2 = -Vector2(cos(add_angle), sin(add_angle)) * speed
			var body: Object = load("res://Prefabs/Planet.tscn").instance()
			
			body.position = positions[index].get_global_position()
			body.mass = max(mass_left * fragment, 0.000001)
			body.density = density
			body.velocity = -velocity
			body.set_modulate(get_modulate())
			get_tree().get_current_scene().get_node_or_null("World").add_child(body)
			index += 1

	yield(get_tree().create_timer(merge_time), "timeout")
	queue_free()


func _on_Area2D_area_entered(area) -> void:
	var obj: KinematicBody2D = area.get_parent()

	var final_momentum: Vector2 = momentum - obj.momentum # →pf = →p1 - →p2
	var final_momentum_norm: Vector2 = engine.normalize(final_momentum, time, delta)
	var final: Vector2 = final_momentum / (mass + obj.mass)  # →vf = →pf / (m1 + m2)

	# Artificially created, not the accurate representation
	var momentum_norm_scalar: float = math.pythagorean_theorem(final_momentum_norm.x, final_momentum_norm.y) # →p_scalar = √(→px^2)+(→py^2)
	displacement = engine.cap(100 - (momentum_norm_scalar * 10 / pow(mass, 2)) , -100.0, 100.0)  # d = 100 - (→p_scalar*10 / m^2) (capped -100 to 100)
	var loss: float = engine.cap(displacement + obj.displacement, -100.0, 100.0) # Δm = d1 + d2 (capped -100 to 100)

	if mass >= obj.mass:
		color = (self.get_modulate() + (obj.get_modulate() * loss/100)) / 2 # →c = →c1 + (→c2 * Δm/100) / 2
		color.a = 1.0 # keep alpha value at 1.0
		obj.collide(100 - loss, self)
		mass = mass + (obj.mass * (loss/100)) # mf = m1 + (m2 * Δm/100)
		velocity -= final
