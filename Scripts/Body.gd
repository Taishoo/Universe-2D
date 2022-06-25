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
var can_collide: bool = true
var loss: float = 0.0

var bodies: Array = []
var delta: float = 0.0
var displacement: float = 0.0
var time: float = Global.UNIVERSE_TIME # t = t_universe
var velocity: Dictionary = {"real": Vector2.ZERO, "norm": Vector2.ZERO} # V * (pixel/t)
var momentum: Dictionary = {"real": Vector2.ZERO, "norm": Vector2.ZERO} # kg/m^2/
var speed: Dictionary = {"real": 0.0, "norm": 0.0} 

func _ready() -> void:
	transform(true)

	if not prespawned:
		can_collide = false
		yield(get_tree().create_timer(1 / (time * 10)), "timeout")
		can_collide = true

	#if get_name() == "Theia":
		#yield(get_tree().create_timer(0.2), "timeout")
		#velocity.real = (Vector2(1,1) * 0.35) * time
		#velocity.real = (Vector2(1,0) * 4.00) * time
		#var _x = move_and_slide(velocity.real)
	
	#yield(get_tree().create_timer(0.2), "timeout")
	#velocity.real = engine.set_random_initial_velocity()
	#var _x = move_and_slide(velocity.real)


func _physics_process(deltax) -> void:
	delta = deltax
	time = Global.UNIVERSE_TIME
	bodies = engine.get_all_bodies(self, get_parent())
	transform(false)
	kinetic()


func transform(init: bool) -> void:
	var volume: float = mass / density # vol = mass / density
	diameter = pow((volume * 3) / (4 * math.pi), (1.0/3.0)) * 2 # diameter = (vol * 3/4 * π) ^ (1/3) * 2
	gravity = (math.G * mass) / max(pow(diameter/2, 2), 0.001)  # g = G*M/r^2
	self.scale = engine.lerp_vector2(self.scale, Vector2(diameter,diameter), 0.3) if not init else Vector2(diameter,diameter)
	self.z_index = int(diameter)
	mass = max(mass, math.min_mass)


func kinetic() -> void:
	var relational_data: Array = engine.get_all_relational_data(self, bodies) # F = G * m1 * m2 / r^2
	var angular_vector_sum: Vector2 = engine.sum_of_angle(relational_data, time, delta) # F1v = Σ F2v + F3v + F4v...
	var force_net: float = math.pythagorean_theorem(angular_vector_sum.x, angular_vector_sum.y) # F1_net = √(F1x^2)+(F1y^2)
	velocity.real = engine.lerp_vector2(velocity.real + ((angular_vector_sum  * force_net) * time), Vector2.ZERO, 0)  # →v_new = lerp(→v + (F1→v * F1_net) * t, 0, 0)
	velocity.norm = engine.normalize(velocity.real, time, delta) # →v_norm = norm(→v)
	momentum.real = velocity.real * mass # →p = m * →v
	speed.real = math.pythagorean_theorem(velocity.real.x, velocity.real.y) # s = √(→vx^2)+(→vy^2)
	momentum.norm = engine.normalize(momentum.real, time, delta) # →p_norm = norm(→p)
	speed.norm = engine.normalize(speed.real, time, delta) # s_norm = norm(s)

	self.get_node("Position").rotation = velocity.real.angle()
	self.get_node("RayCast2D").set_cast_to(engine.normalize(velocity.real, time, delta) / diameter)
	var _catch_move_and_slide: Vector2 = move_and_slide(velocity.real)


func pre_collide(obj: KinematicBody2D) -> void:
	var final_momentum: Vector2 = momentum.real - obj.momentum.real # →pf = →p1 - →p2
	var final_momentum_norm: Vector2 = engine.normalize(final_momentum, time, delta)
	var final: Vector2 = final_momentum / (mass + obj.mass)  # →vf = →pf / (m1 + m2)

	# Artificially created, not the accurate representation
	var mass_sqrd: float = max(pow(mass, 2), pow(math.min_mass, 2)) # m^2 = max(m^2, 0.0000001^2)
	var momentum_norm_scalar: float = math.pythagorean_theorem(final_momentum_norm.x, final_momentum_norm.y) # →p_scalar = √(→px^2)+(→py^2)
	displacement = engine.cap(100 - (momentum_norm_scalar * 10 / mass_sqrd) , -100.0, 100.0)  # d = 100 - (→p * 10 / m^2) (capped -100 to 100)
	loss = engine.cap(displacement + obj.displacement, -100.0, 100.0) # Δm = d1 + d2 (capped -100 to 100)

	if mass > obj.mass:
		obj.collide(100 - loss, self)
		mass = mass + (obj.mass * (loss/100)) # mf = m1 + (m2 * Δm/100)
		velocity.real -= final # →v = →v - →vf


func collide(retained: float, obj: KinematicBody2D) -> void:
	self.get_node("Area2D/Area").set_deferred("disabled", true)
	var merge_time: float =  ((1/time) / (speed.real + obj.speed.real)) * time # mt = ((1/t) / (s1 + s2)) * t
	var mass_left: float = mass * (retained/100) # mf = mi * (mr/100)
	
	if mass > (obj.mass * 0.01) and mass >= 0.005:
		var count: int = round(engine.generate_random_float(1.0, 10.4))
		count = 10
		var distribution: Array = engine.generate_probability_list(count, 1.0, 9999.0)
		var positions: Array = get_node("Position").get_children()
		var index: int = 0

		for fragment in distribution:
			var body: Object = load("res://Prefabs/Planet.tscn").instance()
			body.prespawned = false
			body.position = positions[index].get_global_position()
			body.mass = max(mass_left * fragment, math.min_mass)
			body.density = density
			body.velocity.real = -(velocity.real/1.2)
			body.set_modulate(get_modulate())
			get_tree().get_current_scene().get_node_or_null("World").add_child(body)
			index += 1
		
	yield(get_tree().create_timer(merge_time), "timeout")
	queue_free()

#===========================SENSOR/EVENT FUNCTIONS+=========================

func _on_Area2D_area_entered(area) -> void:
	var obj: KinematicBody2D = area.get_parent()
	if can_collide:
		pre_collide(obj)
