extends Node3D
class_name GateStructure

@export_group("Gate Settings")
@export var open_angle: float = 90.0 
@export var animation_duration: float = 0.5
@export var is_open: bool = false

@onready var interact_area: InteractArea = $InteractArea
@onready var hinge_point: Node3D = $HingePoint

@onready var gate_mesh: MeshInstance3D = $HingePoint/Gate
@onready var gate_col: CollisionShape3D = $HingePoint/StaticBody3D/CollisionShape3D

var is_animating: bool = false

func _ready():
	if interact_area:
		interact_area.interacted.connect(toggle_gate)
	update_gate_visuals(true)

func setup_size(target_width: float, native_width: float):
	scale = Vector3.ONE 
	
	hinge_point.position = Vector3.ZERO
	
	hinge_point.position.x = -target_width / 2.0
	
	var scale_factor = target_width / native_width
	
	if gate_mesh:
		gate_mesh.position = Vector3.ZERO
		
		gate_mesh.scale = Vector3(scale_factor, 1, 1)
		
		gate_mesh.position.x = target_width / 2.0 
		
	if gate_col:
		gate_col.scale = Vector3(scale_factor, 1, 1)
		gate_col.position = Vector3.ZERO
		gate_col.position.x = target_width / 2.0

func toggle_gate():
	if is_animating: return
	is_animating = true
	is_open = !is_open
	update_gate_visuals(false)

func update_gate_visuals(instant: bool):
	var target_rotation = deg_to_rad(open_angle) if is_open else 0.0
	
	if instant:
		hinge_point.rotation.y = target_rotation
		is_animating = false
	else:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(hinge_point, "rotation:y", target_rotation, animation_duration)
		tween.finished.connect(func(): is_animating = false)
