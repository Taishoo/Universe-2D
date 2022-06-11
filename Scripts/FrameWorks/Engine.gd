extends Node

#=============DESCRIPTION===============
# Used for executing subtask that happens in engine-level
#=======================================

const Math: GDScript = preload("res://Scripts/FrameWorks/Math.gd")
var math: Object
var rng: Object


func _init() -> void:
	math = Math.new()
	rng = RandomNumberGenerator.new()
	rng.randomize()


func get_all_bodies(object, parent) -> Array:
	var bodies: Array = []
	for i in parent.get_children():
		if "TYPE" in i and i.TYPE == "BODY" and i.get_name() != object.get_name():
			bodies.push_back(i)
	return bodies


func get_all_relational_data(object:KinematicBody2D, bodies: Array) -> Array:
	var result: Array = []
	if bodies.size() > 0:
		for body in bodies:
			var element:Dictionary = {"name": "null", "angle":0.0, "force": 0.0, "mass": 0.0}
			var radius: float = max(object.get_position().distance_to(body.get_position()), 1)
			element["name"] = body.get_name()
			element["force"] = (math.G) * ((body.mass) / pow(radius, 2)) # F = G * (m / r^2)
			element["angle"] = object.get_angle_to(body.get_position())  # in radians
			element["mass"] = body.mass
			result.push_back(element)
	return result


func sum_of_angle(data: Array, time: float, delta: float) -> Vector2:
	var result: Vector2 = Vector2.ZERO
	if data.size() > 0:
		for x in data:
			var angle: float = x["angle"]
			var time_norm = normalize(time, time, delta)
			var force: float = normalize(x["force"] * time_norm, time, delta) # f_norm = norm(f * t)
			result.x += cos(angle) * force
			result.y += sin(angle) * force
	return result


func set_random_initial_velocity() -> Vector2:
	var velocity: Vector2 = Vector2(rng.randf_range(-1,1), rng.randf_range(-1,1))
	var magnitude: float = rng.randf_range(10.0, 50.00)
	return velocity * magnitude


func lerp_vector2(initial_vector: Vector2, final_vector: Vector2, interpolation: float) -> Vector2:
	var final: Vector2 = Vector2.ZERO
	final.x = lerp(initial_vector.x, final_vector.x, interpolation)
	final.y = lerp(initial_vector.y, final_vector.y, interpolation)
	return final


func generate_random_float(a:float, b:float) -> float:
	return rng.randf_range(a,b)


func generate_probability_list(count: int, lowest: float, highest: float) -> Array:
	var list: Array = []
	while count > 0: # generate random numbers using softmax
		list.push_back(pow(math.e, rng.randf_range(0.1, 1.0)))
		count -= 1
	return math.list_quotient(list, math.sum(list))


func normalize(value, time: float, delta: float): # retuns either float or vector
	# my equation of normalizing speed in godot engine
	var exponent: float = log(1/time) / log(10) # exp = log(1/t)
	return (value * pow(3 + delta * 10, exponent)) # norm = s * (3 + Δt*10)^exp


func cap(value: float, lowest: float, highest: float) -> float:
	return min(max(value, lowest), highest)

