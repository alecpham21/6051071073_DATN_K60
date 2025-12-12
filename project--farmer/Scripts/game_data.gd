extends Node

var current_stage: Node = null
var player_inventory = {}
var gold: int = 0
var last_door_id: String = ""
var john_has_left: bool = false
var unlocked_doors: Array = []
var local_gstate:int = 0:
	set(val):
		if val != local_gstate:
			game_state_changed.emit(local_gstate, val)
			local_gstate = val
var interact_cargo:Array = []
signal game_state_changed(old:int, new:int)
signal current_recipe_changed(_recipe:Recipe)
signal open_kitchen_interface(kitchen_node)


func set_current_stage(stage: Node):
	current_stage = stage

func get_current_stage() -> Node:
	return current_stage

func _process(delta: float) -> void:
	local_gstate = GState.game_state

func save_door_unlocked(door_id: String):
	if door_id != "" and not door_id in unlocked_doors:
		unlocked_doors.append(door_id)


func check_door_unlocked(door_id: String) -> bool:
	return door_id in unlocked_doors
