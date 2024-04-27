extends Node3D


func anim(determine):
	if determine == 4:
		$Label3D.text = "PERFECT"
		$Label3D.modulate.r = 1.0
		$Label3D.modulate.g = 0.0
		$Label3D.modulate.b = 0.69
	elif determine == 3:
		$Label3D.text = "GOOD"
		$Label3D.modulate.r = 1.0
		$Label3D.modulate.g = 0.78
		$Label3D.modulate.b = 0.0
	elif determine == 2:
		$Label3D.text = "BAD"
		$Label3D.modulate.r = 0.0
		$Label3D.modulate.g = 0.78
		$Label3D.modulate.b = 0.25
	else:
		$Label3D.text = "MISS"
		$Label3D.modulate.r = 1.0
		$Label3D.modulate.g = 1.0
		$Label3D.modulate.b = 1.0
	$AnimationPlayer.play("anim")


func _on_animation_player_animation_finished(anim_name):
	get_parent().remove_child(self)
	queue_free()
