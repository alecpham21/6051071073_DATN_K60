extends Node3D

func _ready():
	SceneTransition.reveal_scene()
	await get_tree().create_timer(6.0).timeout
	SceneTransition.change_scene(
		"res://level/level_station.tscn",
		Vector3.ZERO
	)
