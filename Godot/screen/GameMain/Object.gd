extends Area3D

var determine: int

func make_determine(level: int):
	if level > determine:
		determine = level

func get_determine():
	return determine

func set_color(r: float, g: float, b: float):
	$Sprite3D.modulate = Color(r, g, b)
