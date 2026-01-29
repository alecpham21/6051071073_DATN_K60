extends Node3D
class_name Intro


const TRAIN_THEME = preload("res://audio/theme/train_sound.mp3")


func _ready():
	var bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = TRAIN_THEME
	bgm_player.autoplay = true
	bgm_player.volume_db = -4
	bgm_player.bus = "Music"
	add_child(bgm_player)
	
	PlayerData.used_spawn_position = false
	
	TimeManager.is_enabled = false
	SceneTransition.reveal_scene()
	await get_tree().create_timer(6.0).timeout
	SceneTransition.change_scene(
		"res://level/level_station.tscn",
		Vector3.ZERO
	)
