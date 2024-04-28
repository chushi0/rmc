extends Node2D

var android_file = null

func _ready():
	if Engine.has_singleton("GDExtensionAndroidObtainFile"):
		android_file = Engine.get_singleton("GDExtensionAndroidObtainFile")
	if not Engine.has_singleton("GDExtensionAndroidSensors"):
		$Extra/Gyroscope.visible = false
	$Easy/EasyMode.set_pressed_no_signal(GameStatus.easy_mode)
	$Easy/HalfTime.set_pressed_no_signal(GameStatus.half_time)
	$Easy/RangeLimit.set_pressed_no_signal(GameStatus.range_limit)
	$Hard/HardMode.set_pressed_no_signal(GameStatus.hard_mode)
	$Hard/DoubleTime.set_pressed_no_signal(GameStatus.double_time)
	$Hard/Hidden.set_pressed_no_signal(GameStatus.hidden)
	$Extra/AutoPlay.set_pressed_no_signal(GameStatus.autoplay)
	$Extra/MvMode.set_pressed_no_signal(GameStatus.mvmode)
	$Extra/AllPerfect.set_pressed_no_signal(GameStatus.all_perfect)
	$Extra/NoKiai.set_pressed_no_signal(GameStatus.no_kiai)
	$Extra/Reverse.set_pressed_no_signal(GameStatus.reverse)
	$Extra/FixArrow.set_pressed_no_signal(GameStatus.fix_arrow)
	$Extra/Gyroscope.set_pressed_no_signal(GameStatus.gyroscope)
	calc_score_mul()
	setup_osz_file()

func _process(_delta):
	if android_file != null:
		check_android_import_file()

func reload_texture():
	$Background.texture = ImageTexture.create_from_image(GameStatus.current_background())
	$Background.update_drawing_rect()

func play_bgm():
	$AudioStreamPlayer.play(GameStatus.level.preview_time / 1000.0)

func setup_osz_file():
	$AudioStreamPlayer.stream = GameStatus.current_audio()
	setup_difficulty()
	$Music.text = GameStatus.level.title
	play_bgm()

func setup_difficulty():
	$Difficulty.text = GameStatus.level.name
	reload_texture()

func calc_score_mul():
	var mul = 1
	if GameStatus.easy_mode:
		mul *= 0.75
	if GameStatus.half_time:
		mul *= 0.75
	if GameStatus.range_limit:
		mul *= 0.5
	if GameStatus.hard_mode:
		mul *= 1.08
	if GameStatus.double_time:
		mul *= 1.12
	if GameStatus.hidden:
		mul *= 1.2
	mul = round(mul * 100) / 100
	GameStatus.score_mul = mul
	$ScoreMulValue.text = "%.02f" % mul

func _on_audio_stream_player_finished():
	play_bgm()

func _on_prev_difficulty_pressed():
	GameStatus.switch_osu_level(GameStatus.difficulty_index - 1)
	setup_difficulty()

func _on_next_difficulty_pressed():
	GameStatus.switch_osu_level(GameStatus.difficulty_index + 1)
	setup_difficulty()

func _on_start_game_pressed():
	GameStatus.save_mod_config()
	get_tree().change_scene_to_file("res://screen/GameMain/index.tscn")

func _on_easy_mode_toggled(toggled_on):
	GameStatus.easy_mode = toggled_on
	calc_score_mul()

func _on_half_time_toggled(toggled_on):
	GameStatus.half_time = toggled_on
	calc_score_mul()

func _on_range_limit_toggled(toggled_on):
	GameStatus.range_limit = toggled_on
	calc_score_mul()

func _on_hard_mode_toggled(toggled_on):
	GameStatus.hard_mode = toggled_on
	calc_score_mul()

func _on_double_time_toggled(toggled_on):
	GameStatus.double_time = toggled_on
	calc_score_mul()

func _on_hidden_toggled(toggled_on):
	GameStatus.hidden = toggled_on
	calc_score_mul()

func _on_auto_play_toggled(toggled_on):
	GameStatus.autoplay = toggled_on
	calc_score_mul()

func _on_all_perfect_toggled(toggled_on):
	GameStatus.all_perfect = toggled_on
	calc_score_mul()

func _on_no_kiai_toggled(toggled_on):
	GameStatus.no_kiai = toggled_on
	calc_score_mul()

func _on_reverse_toggled(toggled_on):
	GameStatus.reverse = toggled_on
	calc_score_mul()

func _on_gyroscope_toggled(toggled_on):
	GameStatus.gyroscope = toggled_on
	calc_score_mul()
	if toggled_on:
		$GyroscopeAlign.visible = true

func _on_mv_mode_toggled(toggled_on):
	GameStatus.mvmode = toggled_on
	calc_score_mul()

func _on_fix_arrow_toggled(toggled_on):
	GameStatus.fix_arrow = toggled_on
	calc_score_mul()

func _on_prev_music_pressed():
	GameStatus.switch_osz_file(GameStatus.osz_file_index - 1)
	setup_osz_file()

func _on_next_music_pressed():
	GameStatus.switch_osz_file(GameStatus.osz_file_index + 1)
	setup_osz_file()

func _on_import_music_pressed():
	if android_file != null:
		android_file.request_open_file()
		return
	$FileDialog.visible = true

func import_file_from_disk(path):
	var before_import_index = GameStatus.osz_file_index
	GameStatus.import_file(path)
	if before_import_index != GameStatus.osz_file_index:
		setup_osz_file()

func _on_file_dialog_file_selected(path):
	import_file_from_disk(path)

func check_android_import_file():
	var last_cache_file_path = android_file.get_last_cache_file_path()
	if last_cache_file_path == null || last_cache_file_path == "":
		return
	import_file_from_disk(last_cache_file_path)
	android_file.clear_cache_file_path()
