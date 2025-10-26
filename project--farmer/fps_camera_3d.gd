extends Camera3D

@export_node_path("Node3D") var player_path: NodePath
@export var mouse_sensibility: float = 0.005
@export_range(-90.0, 90.0, 0.1, "radians_as_degrees") 
var min_vertical_angle: float = deg_to_rad(-89)
@export_range(-90.0, 90.0, 0.1, "radians_as_degrees") 
var max_vertical_angle: float = deg_to_rad(89)

var player: Node3D
var pitch := 0.0

func _ready() -> void:
	if player_path != NodePath():
		player = get_node(player_path) as Node3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# xoay ngang cho player
		player.rotate_y(-event.relative.x * mouse_sensibility)

		# xoay dọc cho camera
		pitch -= event.relative.y * mouse_sensibility
		pitch = clamp(pitch, min_vertical_angle, max_vertical_angle)
		rotation.x = pitch

	if event.is_action_pressed("toggle_mouse_capture"):
		var m := Input.get_mouse_mode()
		if m == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
