extends Area3D

var determine: int

func make_determine(level: int):
	if level > determine:
		determine = level

func get_determine():
	return determine

