class_name Character
extends CharacterBody3D

@export var stats : CharacterStats:
	set(value):
		stats = value.duplicate()

@export var main_mesh: Node3D
@export var ani : AnimationPlayer
@export var bt_player:BTPlayer
@export var limbo_hsm:LimboHSM

func _apply_gravity(delta:float):
	velocity += get_gravity()*delta

func _physics_process(delta: float) -> void:
	
	limbo_hsm.update(delta)
	#print(limbo_hsm.blackboard.get_var("direction"))

func _ready() -> void:
	limbo_hsm.set_active(true)
