extends KinematicBody2D

const TYPE: String = "BODY"
const Math: GDScript = preload("res://Scripts/FrameWorks/Math.gd")
const Enginex: GDScript = preload("res://Scripts/FrameWorks/Engine.gd")

onready var math:Object = Math.new()
onready var engine:Object = Enginex.new()
onready var pointer = get_node("RayCast2D")

export var body_name: String = "earth"
export var mass: float = 5.972 # x10^24 kg
export var density: float = 5.514 # g/cm^3
export var gravity: float = 9.8 # m/s^2 (surface)
export var diameter: float = 1.2756 # x10^4 km
export var temperature: float = 0.0 # K

var bodies: Array = []
var time: float = Global.UNIVERSE_TIME # t = t_universe
var velocity: Vector2 = Vector2(0,0) * 0 # V * (pixel/t)
var momentum: Vector2 # kg/m^2/s
var speed: float
var speed_norm: float

func _ready() -> void:
	# yield(get_tree().create_timer(0.2), "timeout")
	# velocity = engine.set_random_initial_velocity()
	# var _x = move_and_slide(velocity)
	pass


func _physics_process(delta) -> void:
	preset()
	transform()
	kinetic(delta)


func preset() -> void:
	time = Global.UNIVERSE_TIME
	bodies = engine.get_all_bodies(self, get_parent())


func transform() -> void:
	var volume: float = mass / density # v = m/p
	diameter = pow((volume * 3) / (4 * math.pi), (1.0/3.0)) * 2 # d = ( (v*3/4*pi)^(1/3) ) * 2
	gravity = ((math.G * mass) / pow(diameter/2, 2)) * 0.1  # g = G*M/r^2
	self.scale = engine.lerp_vector2(self.scale, Vector2(diameter,diameter), .3)
	self.z_index = int(mass * density)


func kinetic(delta: float) -> void:
	var relational_data: Array = engine.get_all_relational_data(self, bodies) # F = G * m1 * m2 / r^2
	var angular_vector_sum: Vector2 = math.sum_of_angle(relational_data) # F1v = Σ F2v + F3v + F4v...	
	var force_net: float = math.pythagorean_theorem(angular_vector_sum.x, angular_vector_sum.y) # F1_net = √(F1x^2)+(F1y^2)
	velocity += (angular_vector_sum  * force_net) * time # →v_new = →v + (F1→v * F1_net) * t
	velocity = engine.lerp_vector2(velocity, Vector2.ZERO, 0)
	momentum = velocity * mass # →p = m * →v

	# my equation of normalizing speed in godot engine
	speed = math.pythagorean_theorem(velocity.x, velocity.y)
	var exponent: float = log(1/time) / log(10) # exp = log(1/t)
	speed_norm = (speed * pow(3 + delta * 10, exponent)) # s_norm = s * (3 + Δt*10)^exp

	pointer.set_cast_to(velocity / diameter)
	var _catch_move_and_slide = move_and_slide(velocity)


func collide(_retained: float, _obj: KinematicBody2D) -> void:
	var merge_speed: float = ((1 / speed)) * (1*time) # for improvement
	yield(get_tree().create_timer(merge_speed), "timeout")
	queue_free()


func _on_Area2D_area_entered(area) -> void:
	var obj: KinematicBody2D = area.get_parent()
	var final_linear_momentum: Vector2 = momentum - obj.momentum # →pf = →p1 - →p2
	var final: Vector2 = final_linear_momentum / (mass + obj.mass)  # →vf = →pf / (m1 + m2)
	var KE_before = (engine.get_kinetic_energy(mass, momentum) + engine.get_kinetic_energy(obj.mass, obj.momentum)) * math.KEC # KE_before = KE1 + KE2
	var KE_after = (0.5 * (mass + obj.mass) * pow(math.pythagorean_theorem(velocity.x - final.x, velocity.y - final.y), 2)) * math.KEC # KE_final = 1/2 * (m1 + m2) * Δ→v
	var KE_loss = 100 - ((KE_after / KE_before) * 100) # get the loss percentage

	if mass >= obj.mass:
		obj.collide(KE_loss, obj)
		# print("============")
		# print(get_name())
		# print(momentum)
		# print(KE_before - KE_after)

	velocity -=  final
		
