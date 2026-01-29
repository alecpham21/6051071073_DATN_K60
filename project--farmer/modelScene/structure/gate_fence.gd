extends Node3D
class_name GateStructure

@export var animation_name: String = "open"
@export var is_open: bool = false

@onready var anim_player: AnimationPlayer = $AnimationPlayer 
@onready var interact_area: InteractArea = $HingePoint/InteractArea
@onready var hinge_point: Node3D = $HingePoint
@onready var gate_mesh: MeshInstance3D = $HingePoint/Gate
@onready var static_body: StaticBody3D = $HingePoint/StaticBody3D

func _ready():
	if interact_area:
		interact_area.interacted.connect(toggle_gate)
	
	# Initial state sync
	if is_open:
		anim_player.play(animation_name)
		anim_player.advance(10.0) 
	else:
		anim_player.play(animation_name)
		anim_player.advance(0)
		anim_player.stop()

func setup_size(target_width: float, native_width: float):
	scale = Vector3.ONE 
	hinge_point.position = Vector3(-target_width / 2.0, 0, 0)
	var scale_factor = target_width / native_width
	var center_offset = target_width / 2.0
	
	if gate_mesh:
		gate_mesh.position = Vector3(center_offset, 0, 0)
		gate_mesh.scale = Vector3(scale_factor, 1, 1)
	if static_body:
		static_body.position = Vector3(center_offset, 0, 0)
		static_body.scale = Vector3(scale_factor, 1, 1)
	if interact_area:
		interact_area.position = Vector3(center_offset, 0, 0)
		interact_area.scale = Vector3(scale_factor, 1, 1)

func toggle_gate():
	if anim_player.is_playing(): return
	
	is_open = !is_open
	if is_open:
		anim_player.play(animation_name)
	else:
		anim_player.play_backwards(animation_name)
		
	print("Gate toggled. Open: ", is_open)
