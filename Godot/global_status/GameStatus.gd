extends Node

## 关卡信息
var osz_files: Array[OszFile] = []
var osz_file: OszFile = null
var osz_file_index: int = 0
var all_levels: Array[Beatmap] = []
var difficulty_index: int = 0
var level: Beatmap = null

## MOD
var score_mul = 1.0
var easy_mode = false
var half_time = false
var range_limit = false
var hard_mode = false
var double_time = false
var hidden = false
var autoplay = false
var mvmode = true
var all_perfect = false
var no_kiai = false
var reverse = false
var fix_arrow = false
var gyroscope = false
var gyroscope_scale = 1

## 结算
var perfect_count = 0
var good_count = 0
var bad_count = 0
var miss_count = 0
var max_combo = 0
var score = 0

var config_file: ConfigFile = ConfigFile.new()

func _ready():
	_load_config()
	_load_mod_config()
	
	if !config_file.get_value("init", "import-1763440", false):
		OszFile.import_file("res://assets/osz/1763440.osz")
		config_file.set_value("init", "import-1763440", true)
		_save_config()
	if !config_file.get_value("init", "import-2061458", false):
		OszFile.import_file("res://assets/osz/2061458.osz")
		config_file.set_value("init", "import-2061458", true)
		_save_config()
	
	_load_beatmaps()
	switch_osz_file(randi_range(0, osz_files.size() - 1))

func _load_config():
	if FileAccess.file_exists("user://configs.cfg"):
		config_file.load("user://configs.cfg")

func _save_config():
	var error = config_file.save("user://configs.cfg")
	if error != OK:
		push_error("save config file error:", error)

func _load_mod_config():
	easy_mode = config_file.get_value("mod", "easy_mod", easy_mode)
	half_time = config_file.get_value("mod", "half_time", half_time)
	range_limit = config_file.get_value("mod", "range_limit", range_limit)
	hard_mode = config_file.get_value("mod", "hard_mode", hard_mode)
	double_time = config_file.get_value("mod", "double_time", double_time)
	hidden = config_file.get_value("mod", "hidden", hidden)
	autoplay = config_file.get_value("mod", "auto_play", autoplay)
	mvmode = config_file.get_value("mod", "mv_mode", mvmode)
	all_perfect = config_file.get_value("mod", "all_perfect", all_perfect)
	no_kiai = config_file.get_value("mod", "no_kiai", no_kiai)
	reverse = config_file.get_value("mod", "reverse", reverse)
	fix_arrow = config_file.get_value("mod", "fix_arrow", fix_arrow)
	gyroscope = config_file.get_value("mod", "gyroscope", gyroscope)
	gyroscope_scale = config_file.get_value("mod", "gyroscope_scale", gyroscope_scale)

func save_mod_config():
	config_file.set_value("mod", "easy_mod", easy_mode)
	config_file.set_value("mod", "half_time", half_time)
	config_file.set_value("mod", "range_limit", range_limit)
	config_file.set_value("mod", "hard_mode", hard_mode)
	config_file.set_value("mod", "double_time", double_time)
	config_file.set_value("mod", "hidden", hidden)
	config_file.set_value("mod", "auto_play", autoplay)
	config_file.set_value("mod", "mv_mode", mvmode)
	config_file.set_value("mod", "all_perfect", all_perfect)
	config_file.set_value("mod", "no_kiai", no_kiai)
	config_file.set_value("mod", "reverse", reverse)
	config_file.set_value("mod", "fix_arrow", fix_arrow)
	config_file.set_value("mod", "gyroscope", gyroscope)
	config_file.set_value("mod", "gyroscope_scale", gyroscope_scale)
	_save_config()

func _load_beatmaps():
	var beatmaps = DirAccess.get_directories_at("user://osz/")
	for beatmap in beatmaps:
		var file = _open_osz_file("user://osz/" + beatmap)
		if file != null:
			osz_files.push_back(file)

func _open_osz_file(path: String):
	osz_file = OszFile.new()
	if not osz_file.parse_file(path):
		return null
	return osz_file

func switch_osz_file(index: int):
	osz_file_index = (index + osz_files.size()) % osz_files.size()
	osz_file = osz_files[osz_file_index]
	all_levels = osz_file.beatmaps
	switch_osu_level(randi_range(0, all_levels.size() - 1))

func switch_osu_level(index: int):
	difficulty_index = (index + all_levels.size()) % all_levels.size()
	level = all_levels[difficulty_index]

func current_audio():
	return osz_file.read_audio(level.audio)

func current_background():
	return osz_file.read_image(level.background)

func current_video_path():
	var path: String = osz_file.path + "/" + level.video
	if path.begins_with("user://"):
		path = path.replace("user://", OS.get_user_data_dir() + "/")
	return path

func import_file(file: String):
	var imported_path = OszFile.import_file(file)
	if imported_path == null || imported_path == "":
		return
	var imported_osz_file = _open_osz_file(imported_path)
	if imported_osz_file == null:
		return
	osz_files.push_back(imported_osz_file)
	switch_osz_file(osz_files.size() - 1)
