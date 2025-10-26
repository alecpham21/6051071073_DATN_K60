extends Node

var current_stage: Node = null
var player_inventory = {}
var gold: int = 0
var last_door_id: String = ""

func set_current_stage(stage: Node):
	current_stage = stage

func get_current_stage() -> Node:
	return current_stage
