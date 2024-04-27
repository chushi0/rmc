@tool
extends EditorImportPlugin

func _get_importer_name():
	return "rmc.osu_beatmap"

func _get_visible_name():
	return "osu! beatmap zip file"

func _get_recognized_extensions():
	return ["osz"]

func _get_resource_type():
	return "BeatmapPack"
