extends Node2D

func _ready():
	$Background.texture = ImageTexture.create_from_image(GameStatus.current_background())
	
	var accuracy = (float(GameStatus.perfect_count * 300 + GameStatus.good_count * 100 + GameStatus.bad_count * 50) / float(GameStatus.perfect_count + GameStatus.good_count + GameStatus.bad_count + GameStatus.miss_count) / 3.0)
	
	$PerfectCount.text = "%d" % GameStatus.perfect_count
	$GoodCount.text = "%d" % GameStatus.good_count
	$BadCount.text = "%d" % GameStatus.bad_count
	$MissCount.text = "%d" % GameStatus.miss_count
	$MaxComboCount.text = "%d" % GameStatus.max_combo
	$AccuracyCount.text = "%.02f%%" % accuracy
	$ScoreCount.text = "%d" % GameStatus.score

	if accuracy > 98:
		$Rank.text = "S"
	elif accuracy > 95:
		$Rank.text = "A"
	elif accuracy > 80:
		$Rank.text = "B"
	elif accuracy > 70:
		$Rank.text = "C"
	else:
		$Rank.text = "D"
	
	if GameStatus.miss_count == 0 && GameStatus.bad_count == 0:
		if GameStatus.good_count == 0:
			$FC.text = "ALL PERFECT"
			$Rank.text = "SS"
		else:
			$FC.text = "FULL COMBO"
	else:
		$FC.text = ""
		
		
	$AnimationPlayer.play("fadein")


func _on_button_pressed():
	get_tree().change_scene_to_file("res://screen/GameTitle/index.tscn")


func _on_button_2_pressed():
	get_tree().change_scene_to_file("res://screen/GameMain/index.tscn")
