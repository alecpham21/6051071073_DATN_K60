class_name BikingState
extends GardeningState

@export_group("Bike Settings")
@export var bike_mesh: Node3D
@export var bike_ani_player: AnimationPlayer
@export var bike_ride_aniset: AnimationSet
@export var bike_fast_ride_aniset: AnimationSet

@export var steering_node: Node3D
@export var front_wheel_node: Node3D
@export var max_steer_angle: float = 30.0
@export var hand_marker_l: Marker3D
@export var hand_marker_r: Marker3D

@export var bike_sprint_speed: float = 14.0
@export var bike_speed: float = 10.0

@export var wheel_spin_factor: float = 1.0
@export var brake_power: float = 5.0
@export var reverse_speed: float = 3.0
@export var turn_speed: float = 4.0

@export_group("Dirt Settings")
@export var dirt_fast_per_tick: float = 0.2
@export var dirt_normal_per_tick: float = 0.025

var ik_left: SkeletonIK3D
var ik_right: SkeletonIK3D

func _enter() -> void:
	super()
	if not TimeManager.tick.is_connected(_on_bike_tick):
		TimeManager.tick.connect(_on_bike_tick)
	if bike_mesh: bike_mesh.visible = true
	
	if bike_ride_aniset:
		bike_ride_aniset.play(character.ani)
	
	if bike_ani_player:
		bike_ani_player.play("Cycling") 


	ik_left = character.find_child("IK_Left", true, false)
	ik_right = character.find_child("IK_Right", true, false)
	
	if ik_left and hand_marker_l:
		ik_left.target_node = hand_marker_l.get_path()
		ik_left.start()
		
	# 3. Bắt đầu dính tay phải
	if ik_right and hand_marker_r:
		ik_right.target_node = hand_marker_r.get_path()
		ik_right.start()

	if get_tree():
		get_tree().call_group("hotbar_ui", "set_locked", true)
func _exit() -> void:
	super()
	
	if TimeManager.tick.is_connected(_on_bike_tick):
		TimeManager.tick.disconnect(_on_bike_tick)
	
	#Stop will invisible the bike
	if bike_mesh: bike_mesh.visible = false
	if bike_ani_player: bike_ani_player.stop()
	
	
	#Reset Velocity
	character.velocity = Vector3.ZERO
	
	#Reset ani speed
	character.ani.speed_scale = 1.0
	
	if ik_left: ik_left.stop()
	if ik_right: ik_right.stop()
	
	if get_tree():
		get_tree().call_group("hotbar_ui", "set_locked", false)
func get_current_speed() -> float:
	return bike_speed

func _update(delta: float) -> void:
	check_dispatch()
	
	var accel = character.accel
	
	# Tính trước cái này
	var current_velocity_len = character.velocity.length()
	
	if character.use_gravity and not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	else:
		character.velocity.y = 0.0
	
	# Input
	var throttle = Input.get_axis("back", "forward")
	var steer_input = Input.get_axis("right", "left")
	var is_sprinting = Input.is_action_pressed("running")
	
	var target_vel = Vector3.ZERO
	var current_accel = accel
	
	# Choosing Speed
	var current_speed_limit = bike_sprint_speed if is_sprinting else bike_speed
	
	# Moving Logic
	var bike_forward_dir = -character.transform.basis.z
	
	if throttle > 0: 
		# Press Front
		target_vel = bike_forward_dir * current_speed_limit
		
	elif throttle < 0:
		# Press Back
		var is_moving_forward = character.velocity.dot(bike_forward_dir) > 0.1
		
		if is_moving_forward:
			# Brake
			target_vel = Vector3.ZERO
			current_accel = brake_power
		else:
			# Reverse Speed
			target_vel = -bike_forward_dir * reverse_speed

	# apply Velocity
	character.velocity.x = lerpf(character.velocity.x, target_vel.x, current_accel * delta)
	character.velocity.z = lerpf(character.velocity.z, target_vel.z, current_accel * delta)
	
	# --- [ĐOẠN ĐÃ SỬA Ở ĐÂY] ---
	# Logic xoay thân xe (Có xử lý lùi)
	if current_velocity_len > 0.1:
		var is_moving_forward = character.velocity.dot(-character.transform.basis.z) > 0
		var dir_mult = 1.0 if is_moving_forward else -1.0
		
		if steer_input != 0:
			character.rotate_y(steer_input * turn_speed * delta * dir_mult)
	# --------------------------
	
	character.move_and_slide()
	
	# Cập nhật lại length sau khi move
	current_velocity_len = character.velocity.length()

	if current_velocity_len < 0.1:
		if character.ani.is_playing(): character.ani.pause()
	else:
		if is_sprinting and bike_fast_ride_aniset:
			bike_fast_ride_aniset.play(character.ani)
		else:
			if bike_ride_aniset:
				bike_ride_aniset.play(character.ani)
		
		# Sync Animation
		character.ani.speed_scale = current_velocity_len / current_speed_limit
		
	# Bike Animation
	if bike_ani_player:
		if current_velocity_len < 0.1:
			bike_ani_player.pause()
		else:
			if !bike_ani_player.is_playing(): bike_ani_player.play("Cycling")
			bike_ani_player.speed_scale = current_velocity_len / bike_speed

	# Turn Steering (Ghi đông)
	if steering_node:
		var target_rot_y = steer_input * deg_to_rad(max_steer_angle)
		steering_node.rotation.y = lerp_angle(steering_node.rotation.y, target_rot_y, 5.0 * delta)

	# Front wheel spin
	if front_wheel_node:
		if current_velocity_len > 0.1:
			var is_moving_forward = character.velocity.dot(-character.transform.basis.z) > 0
			var spin_dir = -1.0 if is_moving_forward else 1.0
			front_wheel_node.rotate_object_local(Vector3.UP, current_velocity_len * delta * wheel_spin_factor * spin_dir)

func _on_bike_tick() -> void:
	if character.velocity.length() < 0.1:
		return

	var is_fast = false
	
	if Input.is_action_pressed("running"): 
		is_fast = true
		
	# 3. Cộng độ dơ
	if is_fast:
		# print("🚴 Đạp nhanh -> Dơ nhiều")
		PlayerData.add_dirt_to_outfit(dirt_fast_per_tick)
	else:
		# print("🚲 Đạp chill -> Dơ ít")
		PlayerData.add_dirt_to_outfit(dirt_normal_per_tick)

func check_dispatch():
	if Input.is_action_just_pressed("toggle_vehicle"):
		dispatch("idle")
