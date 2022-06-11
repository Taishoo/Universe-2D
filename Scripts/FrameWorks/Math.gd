extends Node

#=============DESCRIPTION===============
# Used as a framework for complex mathematical problems
#=======================================

const pi: float = 3.141592653589793238
const G: float = 6.67 # X 10^-11
const KEC: float = 0.00000000001
const e: float = 2.718281828459045


func pythagorean_theorem(a: float, b:float) -> float:
	var c = sqrt(pow(a, 2) + pow(b, 2))
	return c

func list_quotient(list: Array, divisor: float) -> Array:
	var quotient: Array = []
	for n in list:
		quotient.push_back(n/divisor)
	return quotient

func sum(list: Array) -> float:
	var sum: float = 0.0
	for n in list:
		sum += n
	return sum
