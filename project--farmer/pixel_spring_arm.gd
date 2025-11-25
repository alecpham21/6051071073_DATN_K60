extends SpringArm3D
# --- CONFIG ---
@export_node_path("Node3D") var player_path: NodePath   #Player
@export var follow_speed: float = 12.0                  #Camera Spring Arm Follow Speed
@export var mouse_sensibility: float = 0.005
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = deg_to_rad(-60)
@export_range(0.0, -90.0, 0.1, "radians_as_degrees")  var max_vertical_angle: float = deg_to_rad(-20)
@export var zoom_step: float = 0.8
@export var min_zoom: float = 4.0
@export var max_zoom: float = 14.0
@export var use_zoom_tween: bool = true                 # tween while zoom

var player: Node3D

func _ready() -> void:
	if player_path != NodePath():
		player = get_node(player_path) as Node3D
	#get mouse capture
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	collision_mask = 0

func _physics_process(delta: float) -> void:
	# Follow player
	if player:
		var target := player.global_transform.origin
		global_position = global_position.lerp(target, clamp(follow_speed * delta, 0.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	# Spin
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensibility
		rotation.y = wrapf(rotation.y, 0.0, TAU)

		rotation.x -= event.relative.y * mouse_sensibility
		rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)

	# ZOOM
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(spring_length - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(spring_length + zoom_step)

	# TOGGLE: on/off mouse capture
	if event.is_action_pressed("toggle_mouse_capture"):
		var m := Input.get_mouse_mode()
		if m == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _set_zoom(target_len: float) -> void:
	target_len = clamp(target_len, min_zoom, max_zoom)
	if use_zoom_tween:
		var t := create_tween()
		t.tween_property(self, "spring_length", target_len, 0.08) # 80ms mượt
	else:
		spring_length = target_len
