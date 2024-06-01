extends Node3D

# Updated by parent screen
var playback_time: float # 回放时间

signal object_determine(determine: int, combo: int)

var objects = [] # 物件

const PERFECT = 4
const GOOD = 3
const BAD = 2
const MISS = 1

func _ready():
	_create_objects()
	
	if GameStatus.hidden:
		$Objects.visible = false
	if GameStatus.autoplay:
		$Camera.auto_play = true

func _process(_delta):
	$Camera.position.z = -playback_time
	if playback_time < 0:
		pass
	_determine()

func _create_objects():
	for object in GameStatus.level.objects:
		var time = object.time
		var angle = object.position
		while angle < 0:
			angle += 180
		while angle > 180:
			angle -= 180
		
		if GameStatus.range_limit:
			if angle > 90:
				angle = 180 - angle
			angle += 45
		
		var color = GameStatus.level.color[object.color_index]
		_add_object(time, angle, color)
		_add_object(time, angle + 180, color)

func _add_object(time, angle, color: Array[float]):
	var node = preload ("res://screen/GameMain/Object.tscn").instantiate()
	node.position.z = -time / 1000.0
	node.position.x = 2.3 * sin(angle * PI / 180)
	node.position.y = 2.3 * - cos(angle * PI / 180)
	if GameStatus.easy_mode:
		node.scale.x = 0.41
		node.scale.y = 0.41
		node.scale.z = 0.41
	if GameStatus.hard_mode:
		node.scale.x = 0.21
		node.scale.y = 0.21
		node.scale.z = 0.21
	node.set_color(color[0], color[1], color[2])
	$Objects.add_child(node)
	objects.push_back({
		"node": node,
		"time": time / 1000.0,
		"angle": angle * PI / 180.0,
	})

func _determine():
	while objects.size() > 0&&objects[0].time < playback_time:
		var object = objects.pop_front()
		var node: Node = object.node
		var determine = node.get_determine()
		if determine == 0:
			node.make_determine(MISS)
			determine = 1
		if $Camera.auto_play:
			determine = 4
		if GameStatus.all_perfect:
			if determine == 3:
				determine = 1
			if determine == 2:
				determine = 1
		$Objects.remove_child(node)
		node.queue_free()
		# 判定文字展示
		var determine_node = preload ("res://screen/GameMain/Determine.tscn").instantiate()
		determine_node.position.z = 0
		determine_node.position.x = 2.3 * sin(object.angle)
		determine_node.position.y = 2.3 * - cos(object.angle)
		$Camera.add_child(determine_node)
		determine_node.anim(determine)
		# combo
		if determine >= GOOD:
			$Camera.increase_combo()
		else:
			$Camera.clear_combo()
		
		object_determine.emit(determine, $Camera.combo)
		setup_autoplay_target()

func kiai_beat():
	$Camera.beat()

func fade_out():
	$Camera.fade_out()

func fade_in():
	$Camera.fade_in()

func setup_autoplay_target():
	if objects.size() > 0:
		$Camera.auto_play_target(objects[0].angle, objects[0].time)

func next_object_time():
	if objects.size() == 0:
		return INF
	return objects[0].time - playback_time

func get_input_angle():
	return $Camera.input_angle
