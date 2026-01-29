class_name MainState
extends CharacterState


@export var can_move := true
@export var can_run := true
@export var rotation_speed: float = 10.0
@export var lock_hotbar := false
@export var hide_tool := false

func _enter() -> void:
	super()
	
	if not is_inside_tree(): return
	
	if lock_hotbar:
		get_tree().call_group("hotbar_ui", "set_locked", true)
	
	if hide_tool:
		get_tree().call_group("hotbar_ui", "tool_cache")

func _exit() -> void:
	super()
	
	if not is_inside_tree(): return
	
	if lock_hotbar:
		get_tree().call_group("hotbar_ui", "set_locked", false)

func _update(delta: float) -> void:
	if character.use_gravity and not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	else:
		character.velocity.y = 0.0
	
	if not is_instance_valid(character.cam_ref):
		return
	
	var input_vec3 = blackboard.get_var(BBNames.direction_var, Vector3.ZERO)
	
	if not character.mouse_captured:
		input_vec3 = Vector3.ZERO

	var move_dir: Vector3 = Vector3.ZERO

	if can_move and input_vec3.length() > 0.01:
		var cam_basis = character.cam_ref.global_transform.basis
		var cam_forward = -cam_basis.z 
		var cam_right = cam_basis.x
		
		cam_forward.y = 0
		cam_right.y = 0
		move_dir = (cam_right * input_vec3.x) + (cam_forward * -input_vec3.z)
		move_dir = move_dir.normalized()

	var current_speed = get_current_speed()
	
	if move_dir.length() > 0.01:
		if can_run and blackboard.get_var(BBNames.run_var, false):
			character.stats.consume(character.stats.run_cost_per_sec * delta)

		var target_vel = move_dir * current_speed
		character.velocity.x = lerpf(character.velocity.x, target_vel.x, character.accel * delta)
		character.velocity.z = lerpf(character.velocity.z, target_vel.z, character.accel * delta)
		
		var target_rotation = atan2(-move_dir.x, -move_dir.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_rotation, rotation_speed * delta)
	else:
		character.velocity.x = lerpf(character.velocity.x, 0.0, character.accel * delta)
		character.velocity.z = lerpf(character.velocity.z, 0.0, character.accel * delta)
		
		if character.velocity.length() < 0.1:
			character.velocity.x = 0
			character.velocity.z = 0

	character.move_and_slide()

func get_current_speed() -> float:
	if can_run and blackboard.get_var(BBNames.run_var, false):
		var threshold = character.stats.get_max_stamina() * 0.1
		
		if character.stats.stamina > threshold:
			return character.stats.run_speed
			
	return character.stats.walk_speed

func check_tool_transitions() -> void:
	if limbo_hsm.can_till(): 
		dispatch("till")
	elif limbo_hsm.can_plant(): 
		dispatch("plant")
	elif limbo_hsm.can_harvest(): 
		dispatch("harvest")
	elif limbo_hsm.can_care(): 
		dispatch("care")
	
	elif limbo_hsm.can_feed():
		dispatch("feed")
	
	if blackboard.get_var(BBNames.toggle_vehicle_var, false):
		if not Watcher.indoor:
			dispatch("bike")

func check_interaction_transitions() -> void:
	if limbo_hsm.can_pickup():
		dispatch("pickup")
	elif limbo_hsm.can_place_down():
		dispatch("placedown")
