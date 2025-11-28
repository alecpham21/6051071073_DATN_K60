extends Node

signal game_state_changed

var current_stage: Node = null
var player_inventory = {}
var gold: int = 0
var last_door_id: String = ""
var player: CharacterBody3D = null
#World Management
var world_states: Dictionary = {}
var indoor: bool = false

func set_current_stage(stage: Node):
	current_stage = stage

func get_current_stage() -> Node:
	return current_stage

func _ready() -> void:
	pass

func _input(event):
	pass

func save_level_data(level_id: String, data: Dictionary):
	world_states[level_id] = data

func get_level_data(level_id: String):
	if world_states.has(level_id):
		return world_states[level_id]
	return null

func has_data(level_id: String) -> bool:
	return world_states.has(level_id)
