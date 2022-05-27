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

var bodies:Array = []
var time: float = 0 # t = t_universe + Δ_game
var prev_position:Vector2 = Vector2.ZERO # changes every t * 0.01
var velocity:Vector2 = Vector2(0,0) * 0 # V * (pixel/t)
var speed:float = 0.0
var linear_velocity: float = 0.0 # km/Δt

func _ready() -> void:
	prev_position = self.get_position()

	yield(get_tree().create_timer(0.2), "timeout")
	velocity = engine.set_random_initial_velocity()
	var _x = move_and_slide(velocity)

func _physics_process(delta) -> void:
	preset(delta)
	transform()
	kinetic()

func preset(delta) -> void:
	time = Global.UNIVERSE_TIME + delta
	bodies = engine.get_all_bodies(self, get_parent())
	prev_position = self.get_position()


func transform() -> void:
	var volume = mass / density # v = m/p
	diameter = pow((volume * 3) / (4 * math.pi), (1.0/3.0)) * 2 # d = ( (v*3/4*pi)^(1/3) ) * 2
	gravity = ((math.G * mass) / pow(diameter/2, 2)) * 0.1  # g = G*M/r^2
	self.scale = Vector2(diameter, diameter)


func kinetic() -> void:
	# →p = m * →v
	# →L = →p * r
	var _momentum = mass * linear_velocity # →p = m * →v
	var relational_data = engine.get_all_relational_data(self, bodies) # F = G * m1 * m2 / r^2
	var angular_vector_sum = math.sum_of_angle(relational_data) # F1v = Σ F2v + F3v + F4v...	
	var force_net = sqrt(pow(angular_vector_sum.x, 2) + pow(angular_vector_sum.y, 2)) # F1_net = √(F1x^2)+(F1y^2)
	velocity = velocity + (angular_vector_sum * (time * force_net))

	velocity.x = lerp(velocity.x, 0, 0)
	velocity.y = lerp(velocity.y, 0, 0)

	pointer.set_cast_to(velocity)
	var _x = move_and_slide(velocity)