class_name GardeningState
extends CharacterState

@export var can_move := true
@export var can_run := true
var is_moving := false

func _enter() -> void:
	super()
	# Báo cho Player biết là không "bận" nữa
	character.is_busy = false

func _update(delta: float) -> void:
	var accel = character.accel
	var cam_ref:Node3D = character.cam_ref
	var move_speed = character.move_speed
	
	## Gravity
	if character.use_gravity and not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	else:
		character.velocity.y = 0.0

	## Dừng di chuyển nếu đang Tương tác/Mở UI (Logic từ Player)
	if not character.mouse_captured:
		character.velocity.x = lerpf(character.velocity.x, 0.0, clampf(accel * delta, 0.0, 1.0))
		character.velocity.z = lerpf(character.velocity.z, 0.0, clampf(accel * delta, 0.0, 1.0))
		character.move_and_slide()
		return

	## Input (Logic từ Player)
	var iv: Vector2 = Vector2(0, 0)
	if GState.is_playing(): iv = Input.get_vector("left", "right", "back", "forward")
	else: iv = Vector2.ZERO
	if iv.length() > 1.0:
		iv = iv.normalized()

	## Hướng theo yaw camera (Logic từ Player)
	var eul: Vector3 = cam_ref.global_transform.basis.get_euler()
	var cam_yaw: float = eul.y
	var forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw))
	var right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))
	var move_dir: Vector3 = right * iv.x + forward * iv.y

	## Animation (Logic từ Player)
	if move_dir.length() > 0.0:
		character.ani.play("Walking")
	else:
		character.ani.play("Idle1")

	## Velocity (Logic từ Player)
	var target_vel: Vector3 = move_dir * move_speed
	var k: float = clampf(accel * delta, 0.0, 1.0)
	character.velocity.x = lerpf(character.velocity.x, target_vel.x, k)
	character.velocity.z = lerpf(character.velocity.z, target_vel.z, k)

	character.move_and_slide()

	## Rotate on moving direction (Logic từ Player)
	if move_dir.length() > 0.0:
		var target_yaw: float = atan2(-move_dir.x, -move_dir.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_yaw, 10.0 * delta)
		
