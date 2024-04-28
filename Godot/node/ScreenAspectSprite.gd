extends Sprite2D

@export var base_scale: Vector2 = Vector2(1, 1)

var last_tex_rect: Vector2
var last_vp_rect: Vector2

func _ready():
	update_drawing_rect()

func _process(_delta):	
	update_drawing_rect()

func update_drawing_rect():
	if texture == null:
		return
	var cur_vp_rect = get_viewport_rect().size
	var cur_tex_rect = texture.get_size()
	if last_tex_rect == cur_tex_rect and last_vp_rect == cur_vp_rect:
		return
	
	var scale = cur_vp_rect / cur_tex_rect
	var final_scale = max(scale.x, scale.y)
	set_scale(base_scale * Vector2(final_scale, final_scale))
