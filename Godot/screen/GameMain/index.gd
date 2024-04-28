extends Control

var timings

var last_beat_time = 0.0
var in_kiai_mode = false

const PERFECT = 4
const GOOD = 3
const BAD = 2
const MISS = 1

var objects = []

var acc_count = [0, 0, 0, 0]
var score = 0
var max_combo = 0

var waiting = 2.0

func _ready():
	var level = GameStatus.level
	$AudioStreamPlayer.stream = GameStatus.current_audio()

	for object in level.objects:
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
		
		var color = level.color[object.color_index]
		add_object(time, angle, color)
		add_object(time, angle + 180, color)
	self.timings = level.timings
	
	if GameStatus.half_time:
		$AudioStreamPlayer.pitch_scale = 0.75
	if GameStatus.double_time:
		$AudioStreamPlayer.pitch_scale = 1.5
	if GameStatus.hidden:
		$Render3D/SubViewport/Objects.visible = false
	if GameStatus.autoplay:
		$Render3D/SubViewport/Camera.auto_play = true

	setup_autoplay_target( - waiting)

func add_object(time, angle, color: Array[float]):
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
	$Render3D/SubViewport/Objects.add_child(node)
	objects.push_back({
		"node": node,
		"time": time / 1000.0,
		"angle": angle * PI / 180.0,
	})

func _process(delta):
	update_subviewport_variables()
	
	if waiting > 0:
		waiting -= delta
		if waiting > 0:
			$Render3D/SubViewport/Camera.position.z = waiting
			return
		else:
			$AudioStreamPlayer.play()
	var time = $AudioStreamPlayer.get_playback_position()
	$Render3D/SubViewport/Camera.position.z = -time

	# 判定
	while objects.size() > 0&&objects[0].time < time:
		var object = objects.pop_front()
		var node: Node = object.node
		var determine = node.get_determine()
		if determine == 0:
			node.make_determine(MISS)
			determine = 1
		if $Render3D/SubViewport/Camera.auto_play:
			determine = 4
		if GameStatus.all_perfect:
			if determine == 3:
				determine = 1
			if determine == 2:
				determine = 1
		$Render3D/SubViewport/Objects.remove_child(node)
		node.queue_free()
		# 判定文字展示
		var determine_node = preload ("res://screen/GameMain/Determine.tscn").instantiate()
		determine_node.position.z = 0
		determine_node.position.x = 2.3 * sin(object.angle)
		determine_node.position.y = 2.3 * - cos(object.angle)
		$Render3D/SubViewport/Camera.add_child(determine_node)
		determine_node.anim(determine)
		# combo
		if determine >= GOOD:
			$Render3D/SubViewport/Camera.increase_combo()
		else:
			$Render3D/SubViewport/Camera.clear_combo()
		if $Render3D/SubViewport/Camera.combo > max_combo:
			max_combo = $Render3D/SubViewport/Camera.combo
		score += ($Render3D/SubViewport/Camera.combo + 1) * [0, 50, 100, 300][determine - 1] * GameStatus.score_mul
		acc_count[determine - 1] += 1
		change_score_and_acc()
		setup_autoplay_target(time)

	# Kiai Mode
	var current_timing = null
	for i in range(timings.size()):
		var timing = timings[i]
		if time * 1000 > timing.time:
			current_timing = timing
			continue
		break
	if current_timing != null&&current_timing.kiai_mode&&!GameStatus.no_kiai:
		if !in_kiai_mode:
			$Render2D/SubViewport/Index2d.kiai_start()
			#$ParticlesLeft.emitting = true
			#$ParticlesRight.emitting = true
		in_kiai_mode = true
		var spb = float(current_timing.mspb) / 1000.0
		# 修正spb误差
		spb = 60.0 / round(60.0 / spb)
		var start_time = float(current_timing.time) / 1000.0
		if time - last_beat_time > spb:
			if last_beat_time < float(current_timing.time) / 1000.0:
				last_beat_time = float(current_timing.time) / 1000.0
			while last_beat_time + spb < time:
				last_beat_time += spb
			$Render2D/SubViewport/Index2d.kiai_beat()
			$Render3D/SubViewport/Camera.beat()
	else:
		in_kiai_mode = false

	# 如果下一个物件在3秒以上，隐藏
	if objects.size() == 0 or objects[0].time - time > 4.5:
		$Render3D/SubViewport/Camera.fade_out()
		$Render2D/SubViewport/Index2d.fade_out()

	# 如果下一个物件在1秒以内，显示
	if objects.size() > 0 and objects[0].time - time < 2:
		$Render3D/SubViewport/Camera.fade_in()
		$Render2D/SubViewport/Index2d.fade_in()

func setup_autoplay_target(time):
	if objects.size() > 0:
		$Render3D/SubViewport/Camera.auto_play_target(objects[0].angle, objects[0].time)

func change_score_and_acc():
	var new_score = "%010d" % score
	if $Score.text != new_score:
		$Score.text = new_score
	$Acc.text = "%.02f%%" % (float(acc_count[1] * 50 + acc_count[2] * 100 + acc_count[3] * 300) / float(acc_count[1] + acc_count[2] + acc_count[3] + acc_count[0]) / 3.0)

func update_subviewport_variables():
	$Render2D/SubViewport/Index2d.playback_time = $AudioStreamPlayer.get_playback_position()
	$Render2D/SubViewport/Index2d.input_angle = $Render3D/SubViewport/Camera.input_angle

func _on_audio_stream_player_finished():
	GameStatus.perfect_count = acc_count[3]
	GameStatus.good_count = acc_count[2]
	GameStatus.bad_count = acc_count[1]
	GameStatus.miss_count = acc_count[0]

	GameStatus.max_combo = max_combo
	GameStatus.score = score
	
	get_tree().change_scene_to_file("res://screen/GameResult/index.tscn")
