extends Node2D

# Updated by parent screen
var playback_time: float # 回放时间
var input_angle: float # 输入角度

var decoder: VideoDecoder # 解码器
var next_frame_video_time: float # 视频下一帧的时间
var video_image: Image # 视频图像（用于update图像数据）
var is_video_image = false # 当前是否正在展示视频

func _ready():
	# 加载背景图片
	_load_bg()
	
	# 如果开启了背景视频，并且存在视频文件，则加载视频解码器
	if GameStatus.mvmode and FileAccess.file_exists(GameStatus.current_video_path()):
		decoder = VideoDecoder.new()
		decoder.start_decode_thread(GameStatus.current_video_path())
		next_frame_video_time = 0
		video_image = Image.new()

func _process(_delta):
	_update_video()
	_update_particles_transform()
	_update_input()

func _load_bg():
	$Background.texture = ImageTexture.create_from_image(GameStatus.current_background())
	$Background.update_drawing_rect()
	$BgForBg.texture = $Background.texture
	$BgForBg.update_drawing_rect()

func _update_video():
	if decoder == null:
		return
	if decoder.is_finish():
		decoder = null
		is_video_image = false
		_load_bg()
		return

	var frame = null
	while playback_time > next_frame_video_time:
		frame = decoder.try_recv_frame()
		if frame == null || frame.width == 0 || frame.height == 0:
			frame = null
			break
		next_frame_video_time += 1.0 / frame.rate
	if frame != null:
		video_image.set_data(frame.width, frame.height, false, Image.FORMAT_RGB8, frame.get_bytes())
		if is_video_image:
			$Background.texture.update(video_image)
		else:
			$Background.texture.set_image(video_image)
			$Background.update_drawing_rect()
			$BgForBg.texture = $Background.texture
			$BgForBg.update_drawing_rect()
			is_video_image = true

func _update_particles_transform():
	var size = get_viewport_rect().size
	$ParticlesLeft.position.x = -size.x / 2
	$ParticlesLeft.position.y = size.y / 2
	$ParticlesRight.position.x = size.x / 2
	$ParticlesRight.position.y = size.y / 2

func _update_input():
	if GameStatus.fix_arrow:
		set_rotation(input_angle)

func kiai_beat():
	$KiaiModeBeat.play("kiai")

func kiai_start():
	$ParticlesLeft.emitting = true
	$ParticlesRight.emitting = true

func fade_out():
	$BreakAnim.play("fade_out")

func fade_in():
	$BreakAnim.play("fade_in")
