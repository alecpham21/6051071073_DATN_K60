@tool
extends BTAction

@export var target_pos_var: StringName = "target_pos"
@export var target_rot_var: StringName = "target_rot"
@export var align_on_arrival: bool = true

@export var speed: float = 3.0
@export var tolerance: float = 1.0

func _tick(delta: float) -> Status:
	var npc: CharacterBody3D = agent as CharacterBody3D
	if not npc: return FAILURE
	
	var nav_agent: NavigationAgent3D = npc.get_node_or_null("NavigationAgent3D")
	if not nav_agent: return FAILURE
		
	var target: Vector3 = blackboard.get_var(target_pos_var, Vector3.ZERO)
	nav_agent.target_position = target
	
	if nav_agent.is_navigation_finished():
		nav_agent.set_velocity(Vector3.ZERO)
		
		if not align_on_arrival:
			return SUCCESS
			
		var desired_rot_y = blackboard.get_var(target_rot_var, 0.0)
		var current_rot_y = npc.global_rotation.y
		
		npc.global_rotation.y = lerp_angle(current_rot_y, desired_rot_y, delta * 5.0)
		
		if abs(angle_difference(current_rot_y, desired_rot_y)) < 0.05:
			npc.global_rotation.y = desired_rot_y
			return SUCCESS
		
		return RUNNING
		
	var current_pos = npc.global_position
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = current_pos.direction_to(next_path_pos)
	
	if direction.length() > 0.001:
		var look_target = current_pos + direction
		look_target.y = current_pos.y
		npc.look_at(look_target)

	var intended_velocity = direction * speed
	
	nav_agent.set_velocity(intended_velocity)
	
	return RUNNING
