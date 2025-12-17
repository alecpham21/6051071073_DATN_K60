extends SpringArm3D

@export_group("Config")
@export_node_path("Node3D") var player_path: NodePath
@export var follow_speed: float = 12.0
@export var mouse_sensibility: float = 0.005
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = deg_to_rad(-60)
@export_range(0.0, -90.0, 0.1, "radians_as_degrees")  var max_vertical_angle: float = deg_to_rad(-20)
@export var zoom_step: float = 0.8
@export var min_zoom: float = 4.0
@export var max_zoom: float = 14.0
@export var use_zoom_tween: bool = true

# lock the camera angle
const INDOOR_PITCH_ANGLE: float = deg_to_rad(-50.0)

var player: Node3D
var indoor_fixed_pos: Vector3 = Vector3.ZERO
var is_initialized_pos: bool = false
var is_focusing: bool = false
var tween_focus: Tween
var stored_spring_length: float = 0.0


func _ready() -> void:
	if player_path != NodePath():
		player = get_node(player_path) as Node3D
	
	set_as_top_level(true)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	collision_mask = 0

func _physics_process(delta: float) -> void:
	
	if is_focusing: return
	
	# indoor logic
	if Watcher.indoor:
		if not is_initialized_pos:
			indoor_fixed_pos = global_position
			is_initialized_pos = true
		
		global_position = indoor_fixed_pos
		
		rotation.x = INDOOR_PITCH_ANGLE
		
		return 
	
	# outdoor logic
	is_initialized_pos = false
	
	if player:
		var target := player.global_transform.origin
		global_position = global_position.lerp(target, clamp(follow_speed * delta, 0.0, 1.0))



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensibility
		rotation.y = wrapf(rotation.y, 0.0, TAU)


		if not Watcher.indoor:
			rotation.x -= event.relative.y * mouse_sensibility
			rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)


	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(spring_length - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(spring_length + zoom_step)


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
		t.tween_property(self, "spring_length", target_len, 0.08)
	else:
		spring_length = target_len


func focus_on_target(target_marker: Node3D):
	is_focusing = true
	
	stored_spring_length = spring_length
	
	if tween_focus: tween_focus.kill()
	tween_focus = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	
	tween_focus.tween_property(self, "global_transform", target_marker.global_transform, 1.0)
	
	tween_focus.tween_property(self, "spring_length", 0.0, 1.0)


func return_to_player():
	if tween_focus: tween_focus.kill()
	tween_focus = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	
	var target_transform = Transform3D(Basis.from_euler(Vector3(INDOOR_PITCH_ANGLE, rotation.y, 0)), indoor_fixed_pos)
	tween_focus.tween_property(self, "global_transform", target_transform, 0.8)
	
	tween_focus.tween_property(self, "spring_length", stored_spring_length, 0.8)
	
	tween_focus.chain().tween_callback(func(): is_focusing = false)
