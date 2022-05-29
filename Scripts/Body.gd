extends KinematicBody2D

const TYPE: String = "BODY"
const Math = preload("res://Scripts/FrameWorks/Math.gd")
const Engine = preload("res://Scripts/FrameWorks/Engine.gd")

onready var math:Object = Math.new()
onready var engine:Object = Engine.new()
onready var pointer = get_node("RayCast2D")

export var body_name: String = "earth"
export var mass:float = 5.972 # x10^24 kg
export var density:float = 5.514 # g/cm^3
export var gravity:float = 9.8 # m/s^2 (surface)
export var diameter:float = 1.2756 # x10^4 km
export var temperature: float = 0.0 # K

var bodies:Array = []
var time: float = 0 # t = t_universe + Δ_game
var velocity:Vector2 = Vector2(0,0) * 0 # V * (pixel/t)
var momentum: Vector2 # kg/m^2/s
var speed: float

func _ready() -> void:
	# yield(get_tree().create_timer(0.2), "timeout")
	# velocity = engine.set_random_initial_velocity()
	# var _x = move_and_slide(velocity)
	pass

func _physics_process(delta) -> void:
	preset(delta)
	transform()
	kinetic()


func preset(delta) -> void:
	time = Global.UNIVERSE_TIME + delta
	bodies = engine.get_all_bodies(self, get_parent())


func transform() -> void:
	var volume = mass / density # v = m/p
	diameter = pow((volume * 3) / (4 * math.pi), (1.0/3.0)) * 2 # d = ( (v*3/4*pi)^(1/3) ) * 2
	gravity = ((math.G * mass) / pow(diameter/2, 2)) * 0.1  # g = G*M/r^2
	self.scale = engine.lerp_vector2(self.scale, Vector2(diameter,diameter), .3)
	self.z_index = mass * density


func kinetic() -> void:
	# →L = →p * r
	momentum = velocity * mass # →p = m * →v
	var relational_data = engine.get_all_relational_data(self, bodies) # F = G * m1 * m2 / r^2
	var angular_vector_sum = math.sum_of_angle(relational_data) # F1v = Σ F2v + F3v + F4v...	
	var force_net = math.pythagorean_theorem(angular_vector_sum.x, angular_vector_sum.y) # F1_net = √(F1x^2)+(F1y^2)
	velocity = velocity + ((angular_vector_sum  * force_net) * time)
	speed = math.pythagorean_theorem(velocity.x, velocity.y)
	velocity = engine.lerp_vector2(velocity, Vector2.ZERO, 0)

	pointer.set_cast_to(velocity / diameter)
	var _catch_move_and_slide = move_and_slide(velocity)

func collide(retained: float, obj: KinematicBody2D) -> void:
	var merge_speed: float = ((1 / speed)) * (1/time)
	yield(get_tree().create_timer(merge_speed), "timeout")
	queue_free()


func _on_Area2D_area_entered(area) -> void:
	var obj = area.get_parent()
	var final_linear_momentum = momentum - obj.momentum # →pf = →p1 - →p2
	var final = final_linear_momentum / (mass + obj.mass)  # →vf = →pf / (m1 + m2)

	if mass >= obj.mass:
		var _loss = engine.generate_random_value(60, 99)
		var KE_before = (engine.get_kinetic_energy(mass, momentum) + engine.get_kinetic_energy(obj.mass, obj.momentum)) * math.KEx # KE_before = KE1 + KE2
		var KE_after = (0.5 * (mass + obj.mass) * pow(engine.to_speed(velocity-final), 2)) * math.KEx # KE_final = 1/2 * (m1 + m2) * Δ→v
		var KE_loss = 100 - ((KE_after / KE_before) * 100) # get the loss percentage
		obj.collide(KE_loss, obj)
		print("============")
		print(get_name())
		print(KE_loss)

	velocity -=  final
		
