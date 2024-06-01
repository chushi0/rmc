extends Control

var timings

var last_beat_time = 0.0
var in_kiai_mode = false

var acc_count = [0, 0, 0, 0]
var score = 0
var max_combo = 0

var waiting = 2.0

var now_showing = true

func _ready():
	var level = GameStatus.level
	$AudioStreamPlayer.stream = GameStatus.current_audio()
	
	self.timings = level.timings
	
	if GameStatus.half_time:
		$AudioStreamPlayer.pitch_scale = 0.75
	if GameStatus.double_time:
		$AudioStreamPlayer.pitch_scale = 1.5

	%Index3d.setup_autoplay_target()

func _process(delta):
	update_subviewport_variables()
	
	if waiting > 0:
		waiting -= delta
		if waiting <= 0:
			$AudioStreamPlayer.play()
	var time = $AudioStreamPlayer.get_playback_position()

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
			%Index2d.kiai_start()
		in_kiai_mode = true
		var spb = float(current_timing.mspb) / 1000.0
		# 修正spb误差
		spb = 60.0 / round(60.0 / spb)
		if time - last_beat_time > spb:
			if last_beat_time < float(current_timing.time) / 1000.0:
				last_beat_time = float(current_timing.time) / 1000.0
			while last_beat_time + spb < time:
				last_beat_time += spb
			if now_showing:
				%Index2d.kiai_beat()
				%Index3d.kiai_beat()
	else:
		in_kiai_mode = false

	# 如果下一个物件在3秒以上，隐藏
	if now_showing and %Index3d.next_object_time() > 4.5:
		now_showing = false
		%Index2d.fade_out()
		%Index3d.fade_out()

	# 如果下一个物件在1秒以内，显示
	if not now_showing and %Index3d.next_object_time() < 2:
		now_showing = true
		%Index2d.fade_in()
		%Index3d.fade_in()

func change_score_and_acc():
	var new_score = "%010d" % score
	if $Score.text != new_score:
		$Score.text = new_score
	$Acc.text = "%.02f%%" % (float(acc_count[1] * 50 + acc_count[2] * 100 + acc_count[3] * 300) / float(acc_count[1] + acc_count[2] + acc_count[3] + acc_count[0]) / 3.0)

func update_subviewport_variables():
	var playback_time = $AudioStreamPlayer.get_playback_position()
	if waiting > 0:
		playback_time = -waiting

	%Index2d.playback_time = playback_time
	%Index2d.input_angle = %Index3d.get_input_angle()
	%Index3d.playback_time = playback_time

func _on_audio_stream_player_finished():
	GameStatus.perfect_count = acc_count[3]
	GameStatus.good_count = acc_count[2]
	GameStatus.bad_count = acc_count[1]
	GameStatus.miss_count = acc_count[0]

	GameStatus.max_combo = max_combo
	GameStatus.score = score
	
	get_tree().change_scene_to_file("res://screen/GameResult/index.tscn")

func _on_index_3d_object_determine(determine, combo):
	if combo > max_combo:
		max_combo = combo
	score += (combo + 1) * [0, 50, 100, 300][determine - 1] * GameStatus.score_mul
	acc_count[determine - 1] += 1
	change_score_and_acc()
