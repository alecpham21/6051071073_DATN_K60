class_name PlayerInput
extends Node

@export var player: CharacterBody3D
@export var player_actions: PlayerActions
@export var limbo_hsm: LimboHSM

var blackboard: Blackboard

func _ready() -> void:
	blackboard = limbo_hsm.blackboard

func _process(_delta: float) -> void:
	# 1. Lấy input 2D từ bàn phím
	var input_vec2 = Input.get_vector(
		player_actions.move_left, 
		player_actions.move_right, 
		player_actions.move_forward, 
		player_actions.move_backward
	)
	var input_vec3 = Vector3(input_vec2.x, 0, input_vec2.y)
	blackboard.set_var(BBNames.direction_var, input_vec3)

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree(): 
		return
	pass
