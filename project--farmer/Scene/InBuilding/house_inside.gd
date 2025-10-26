extends Node3D

func _ready():
	if GameData.last_door_id == "house_1":
		$Player.global_position = $PlayerSpawn.global_position
