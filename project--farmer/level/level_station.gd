extends Node3D

@onready var player = %MainFarmer
@onready var spawn_point = $SpawnPoint

func _ready():
	if spawn_point:
		player.global_position = spawn_point.global_position
	
	print("Player spawned at gas station: ", player.global_position)
	SceneTransition.reveal_scene()
