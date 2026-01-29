extends Node3D
class_name LevelStation


@onready var player = %MainFarmer
@onready var spawn_point = $SpawnPoint

const STATION_THEME = preload("res://audio/theme/ocean_wave cut.mp3")


func _ready():
	
	var bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = STATION_THEME
	bgm_player.autoplay = true
	bgm_player.volume_db = -2
	bgm_player.bus = "Music"
	add_child(bgm_player)
	
	if PlayerData.next_spawn_position != Vector3.ZERO:
		player.global_position = PlayerData.next_spawn_position
		PlayerData.next_spawn_position = Vector3.ZERO 
		print("Loaded: Player spawned at saved position.")
	
	elif spawn_point:
		player.global_position = spawn_point.global_position
		print("New Game: Player spawned at default marker.")
	
	_handle_delayed_spawn()
	
	SceneTransition.reveal_scene()

func _handle_delayed_spawn():
	await get_tree().physics_frame
	
	if PlayerData.used_spawn_position:
		player.global_position = PlayerData.next_spawn_position
		PlayerData.used_spawn_position = false
	elif spawn_point:
		player.global_position = spawn_point.global_position
		if player is CharacterBody3D:
			player.velocity = Vector3.ZERO
	
	var camera = get_viewport().get_camera_3d()
	if camera and camera.has_method("snap_to_target"):
		camera.snap_to_target(player.global_position)
