class_name PlayerInput
extends Node

@export var player: CharacterBody3D
@export var player_actions: PlayerActions
@export var limbo_hsm: LimboHSM

var blackboard: Blackboard
var input_direction: Vector3

func _ready() -> void:
	blackboard = limbo_hsm.blackboard
	blackboard.bind_var_to_property(BBNames.direction_var, self, "input_direction", false)

func _process(_delta: float) -> void:
	var input_vec3 = Input.get_vector(
		player_actions.move_left, 
		player_actions.move_right, 
		player_actions.move_forward, 
		player_actions.move_backward
	)

func _unhandled_input(event: InputEvent) -> void:
	pass
