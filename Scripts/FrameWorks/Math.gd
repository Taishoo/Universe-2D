extends Node

#=============DESCRIPTION===============
# Used as a framework for complex mathematical problems
#=======================================

const pi = 3.141592653589793238
const G = 6.67 # X 10^-11

func sum_of_angle(data: Array) -> Vector2:
	var result = Vector2.ZERO
	if data.size() > 0:
		for x in data:
			var angle = x["angle"]
			result.x = result.x + cos(angle)
			result.y = result.y + sin(angle)
	return result

func pythagorean_theorem(a: float, b:float) -> float:
	var c = sqrt(pow(a, 2) + pow(b, 2))
	return c
