extends SpringArm3D

@export_group("Config")
@export_node_path("Node3D") var player_path: NodePath
@export var follow_speed: float = 12.0 
@export var mouse_sensibility: float = 0.005
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = deg_to_rad(-40)
@export_range(0.0, -90.0, 0.1, "radians_as_degrees")  var max_vertical_angle: float = deg_to_rad(-10)
@export var zoom_step: float = 0.8
@export var min_zoom: float = 10.0
@export var max_zoom: float = 20.0
@export var use_zoom_tween: bool = true
@export var indoor_zoom: float = 8.0
@export var indoor_pitch: float = -45.0

@export_group("Advanced Follow")
@export var dead_zone_radius: float = 0.0
@export var look_ahead_ratio: float = 0.0

const INDOOR_PITCH_ANGLE: float = deg_to_rad(-50.0)

var player: Node3D
var indoor_fixed_pos: Vector3 = Vector3.ZERO
var is_initialized_pos: bool = false
var is_focusing: bool = false
var tween_focus: Tween
var stored_spring_length: float = 0.0

var is_aiming: bool = false
var default_pitch: float


func _ready() -> void:
	if player_path != NodePath():
		player = get_node(player_path) as Node3D
	
	set_as_top_level(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	collision_mask = 0
	stored_spring_length = spring_length
	
	default_pitch = min_vertical_angle 
	
	rotation.x = default_pitch
	spring_length = max_zoom

func _physics_process(delta: float) -> void:
	
	if is_focusing: return
	
	if Watcher.indoor:
		if not is_initialized_pos:
			indoor_fixed_pos = global_position
			is_initialized_pos = true
		
		global_position = indoor_fixed_pos
		
		spring_length = lerp(spring_length, indoor_zoom, 5.0 * delta)
		
		var target_pitch = deg_to_rad(indoor_pitch)
		rotation.x = lerp_angle(rotation.x, target_pitch, 5.0 * delta)
		
		return
	
	is_initialized_pos = false
	
	if player:
		var target := player.global_transform.origin
		
		if look_ahead_ratio > 0.0 and "velocity" in player:
			var p_vel = player.velocity as Vector3
			target += p_vel * look_ahead_ratio
		
		if dead_zone_radius > 0.0:
			var dist = global_position.distance_to(target)
			if dist < dead_zone_radius:
				target = global_position 
			else:
				var dir = global_position.direction_to(target)
				target = target - (dir * dead_zone_radius)
		
		global_position = global_position.lerp(target, clamp(follow_speed * delta, 0.0, 1.0))

	if not is_aiming and not Watcher.indoor:
		rotation.x = lerp_angle(rotation.x, default_pitch, 5.0 * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("aim"):
		is_aiming = true
	elif event.is_action_released("aim"):
		is_aiming = false
	
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensibility
		rotation.y = wrapf(rotation.y, 0.0, TAU)



		if is_aiming and not Watcher.indoor:
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
	if not is_focusing: 
		return

	if tween_focus: tween_focus.kill()
	tween_focus = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	
	var target_transform = Transform3D(Basis.from_euler(Vector3(INDOOR_PITCH_ANGLE, rotation.y, 0)), indoor_fixed_pos)
	tween_focus.tween_property(self, "global_transform", target_transform, 0.8)
	
	tween_focus.tween_property(self, "spring_length", stored_spring_length, 0.8)
	
	tween_focus.chain().tween_callback(func(): is_focusing = false)
