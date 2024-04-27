extends Node3D

const PERFECT = 4
const GOOD = 3
const BAD = 2
const MISS = 1

var combo = 0
var input_angle = 0

var android_sensor = null

var auto_play = false
var angle_start = {"time": 0, "target": PI / 2}
var angle_target = {"time": 0, "target": PI / 2}

var decoder: VideoDecoder
var next_frame_video_time: float
var video_image: Image
var is_video_image = false

# fade_out -> 变为false
# fade_in -> 变为true
var now_showing: bool = true

func _ready():
	$Sprite3D.texture = ImageTexture.create_from_image(GameStatus.current_background())
	
	if GameStatus.mvmode and FileAccess.file_exists(GameStatus.current_video_path()):
		decoder = VideoDecoder.new()
		decoder.start_decode_thread(GameStatus.current_video_path())
		next_frame_video_time = 0
		video_image = Image.new()
	
	if Engine.has_singleton("GDExtensionAndroidSensors"):
		android_sensor = Engine.get_singleton("GDExtensionAndroidSensors")
	
	clear_combo()

func _on_perfect_area_entered(area):
	area.make_determine(PERFECT)

func _on_good_area_entered(area):
	area.make_determine(GOOD)

func _on_bad_area_entered(area):
	area.make_determine(BAD)

func _on_miss_area_entered(area):
	area.make_determine(MISS)

func _process(delta):
	update_video(delta)
	update_input(delta)

func update_video(delta):
	if decoder == null:
		return
	if decoder.is_finish():
		decoder = null
		$Sprite3D.texture = ImageTexture.create_from_image(GameStatus.current_background())
		return
	var frame = null
	while -position.z > next_frame_video_time:
		frame = decoder.try_recv_frame()
		if frame == null || frame.width == 0 || frame.height == 0:
			frame = null
			break
		next_frame_video_time += 1.0 / frame.rate
	if frame != null:
		video_image.set_data(frame.width, frame.height, false, Image.FORMAT_RGB8, frame.get_bytes())
		if is_video_image:
			$Sprite3D.texture.update(video_image)
		else:
			$Sprite3D.texture.set_image(video_image)

func update_input(delta):
	$MoveCircle.position.z += delta * 1.5
	
	update_input_angle(delta)
	
	if auto_play:
		if -position.z >= angle_target.time:
			$Arrow.rotation.z = angle_target.target
		elif angle_target.time > angle_start.time:
			$Arrow.rotation.z = angle_start.target + (angle_target.target - angle_start.target) * (-position.z - angle_start.time) / (angle_target.time - angle_start.time)
	else:
		$Arrow.rotation.z = input_angle
	
	if GameStatus.fix_arrow:
		$Circle.rotation.z = $Arrow.rotation.z
		$Camera3D.rotation.z = $Arrow.rotation.z

func update_input_angle(delta):
	# Desktop
	var base = 3
	if Input.is_key_pressed(KEY_CTRL):
		base *= 2
	if Input.is_key_pressed(KEY_SHIFT):
		base /= 2
	if Input.is_key_pressed(KEY_UP) || Input.is_key_pressed(KEY_RIGHT):
		input_angle += base * delta
	if Input.is_key_pressed(KEY_DOWN) || Input.is_key_pressed(KEY_LEFT):
		input_angle -= base * delta
	# Android
	if android_sensor != null:
		if GameStatus.gyroscope:
			input_angle = -android_sensor.gyroscope_sensor_angle() * GameStatus.gyroscope_scale
		else:
			input_angle = android_sensor.gravity_sensor_angle()
	
	if GameStatus.reverse:
		input_angle = -input_angle

func beat():
	if !now_showing:
		return
	$AnimationPlayer.play("kiai")
	$MoveCircle.position.z = 0

func auto_play_target(angle: float, time_remain: float):
	var old_target = angle_target.target
	angle_start.time = -position.z
	angle_start.target = angle_normalize(angle_target.target)
	angle_target.target = angle_normalize(angle + PI / 2)
	angle_target.time = time_remain
	if angle_start.target - angle_target.target > PI / 2:
		angle_target.target = angle_target.target + PI
	elif angle_target.target - angle_start.target > PI / 2:
		angle_target.target = angle_target.target - PI

func angle_normalize(angle: float):
	while angle < 0:
		angle += PI * 2
	while angle > PI * 2:
		angle -= PI * 2
	return angle

func increase_combo():
	combo += 1
	$Combo.text = "x%s" % combo
	$ComboAnimationPlayer.stop()
	$ComboAnimationPlayer.play("combo")
	return combo

func clear_combo():
	combo = 0
	$Combo.text = ""

func fade_out():
	if !now_showing:
		return
	now_showing = false
	$BreakAnimationPlayer.play("fade_out")

func fade_in():
	if now_showing:
		return
	now_showing = true
	$BreakAnimationPlayer.play("fade_in")
