extends Node3D
class_name MainMenu

const MAIN_THEME = preload("res://audio/theme/shepherd_dog.mp3")


func _ready():
	TimeManager.is_enabled = false
	var bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = MAIN_THEME
	bgm_player.autoplay = true
	bgm_player.volume_db = -12.0
	bgm_player.bus = "Music"
	add_child(bgm_player)
