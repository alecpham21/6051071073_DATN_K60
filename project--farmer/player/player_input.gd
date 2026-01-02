class_name PlayerInput
extends Node

@export var player: CharacterBody3D
@export var player_actions: PlayerActions
@export var limbo_hsm: LimboHSM

var blackboard: Blackboard

func _ready() -> void:
	await get_tree().process_frame
	if limbo_hsm:
		blackboard = limbo_hsm.blackboard

func _process(_delta: float) -> void:
	if not blackboard or not player_actions: return
	
	if Input.is_action_pressed("aim"): 
		blackboard.set_var(BBNames.direction_var, Vector3.ZERO)
		blackboard.set_var(BBNames.run_var, false)
		blackboard.set_var(BBNames.use_item_var, false)
		blackboard.set_var(BBNames.interact_var, false)
		blackboard.set_var(BBNames.toggle_vehicle_var, false)
		return
	
	if GState.is_journal() or GState.is_shop() or GState.is_dialog() or GState.is_ui():
		blackboard.set_var(BBNames.direction_var, Vector3.ZERO)
		blackboard.set_var(BBNames.run_var, false)
		blackboard.set_var(BBNames.use_item_var, false)
		return
	
	
	# Movment(Vector3)
	var input_vec2 = Input.get_vector(
		player_actions.move_left, 
		player_actions.move_right, 
		player_actions.move_forward, 
		player_actions.move_backward
	)
	var input_vec3 = Vector3(input_vec2.x, 0, input_vec2.y)
	blackboard.set_var(BBNames.direction_var, input_vec3)

	var is_running = Input.is_action_pressed(player_actions.run) if player_actions.run else false
	blackboard.set_var(BBNames.run_var, is_running)

	var using_item = Input.is_action_pressed(player_actions.use_item) if player_actions.use_item else false
	blackboard.set_var(BBNames.use_item_var, using_item)

	if player_actions.interact and Input.is_action_just_pressed(player_actions.interact):
		blackboard.set_var(BBNames.interact_var, true)
	else:
		blackboard.set_var(BBNames.interact_var, false)
		
	if player_actions.toggle_vehicle and Input.is_action_just_pressed(player_actions.toggle_vehicle):
		blackboard.set_var(BBNames.toggle_vehicle_var, true)
	else:
		blackboard.set_var(BBNames.toggle_vehicle_var, false)

func _unhandled_input(event: InputEvent) -> void:
	pass
