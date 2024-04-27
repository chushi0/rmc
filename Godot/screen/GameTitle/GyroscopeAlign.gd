extends Node2D

var android_sensor = null

func _ready():
	if Engine.has_singleton("GDExtensionAndroidSensors"):
		android_sensor = Engine.get_singleton("GDExtensionAndroidSensors")

func _process(delta):
	if android_sensor != null:
		$Node.rotation = android_sensor.gyroscope_sensor_angle() * GameStatus.gyroscope_scale
	if GameStatus.reverse:
		$Node.rotation = -$Node.rotation

func _on_align_pressed():
	if android_sensor != null:
		android_sensor.align_gyroscope_sensor()

func _on_close_pressed():
	visible = false


func _on_h_slider_value_changed(value):
	GameStatus.gyroscope_scale = value / 1000.0
