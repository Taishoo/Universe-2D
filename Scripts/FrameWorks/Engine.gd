extends Node

#=============DESCRIPTION===============
# Used for executing subtask that happens in engine-level
#=======================================

const Math = preload("res://Scripts/FrameWorks/Math.gd")
var math:Object
var rng: Object


func _init() -> void:
	math = Math.new()
	rng = RandomNumberGenerator.new()
	rng.randomize()


func get_all_bodies(object, parent) -> Array:
	var bodies = []
	for i in parent.get_children():
		if "TYPE" in i and i.TYPE == "BODY" and i.get_name() != object.get_name():
			bodies.push_back(i)
	return bodies


func get_all_relational_data(object:KinematicBody2D, bodies: Array) -> Array:
	var result:Array = []
	if bodies.size() > 0:
		for body in bodies:
			var element:Dictionary = {"name": "null", "angle":0.0, "force": 0.0, "mass": 0.0}
			element["name"] = body.get_name()
			element["force"] = (math.G * object.mass * body.mass) / (pow (object.get_position().distance_to(body.get_position()), 2) * 1) # F = G * m1 * m2 / r^2
			element["angle"] = object.get_angle_to(body.get_position())  # in radians
			element["mass"] = body.mass
			result.push_back(element)
	return result


func set_random_initial_velocity() -> Vector2:
	var velocity:Vector2 = Vector2(rng.randf_range(-1,1), rng.randf_range(-1,1))
	var magnitude: float = rng.randf_range(10.0, 50.00)
	return velocity * magnitude


func lerp_vector2(initial_vector: Vector2, final_vector: Vector2, interpolation: float) -> Vector2:
	var final: Vector2 = Vector2.ZERO
	final.x = lerp(initial_vector.x, final_vector.x, interpolation)
	final.y = lerp(initial_vector.y, final_vector.y, interpolation)
	return final


func generate_random_value(a:float, b:float) -> float:
	return rng.randf_range(a,b)

func to_speed(vector: Vector2) -> float:
	return(abs(vector.x * vector.y))

func get_kinetic_energy(mass: float, momentum:Vector2) -> float: # KE = 1/2 * m * v^2
	return (0.5 * mass * pow(to_speed(momentum), 2)) # to avoid number explosion
