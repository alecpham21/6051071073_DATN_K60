@tool
extends BTAction

@export var radius: float = 3.0
@export var target_var: StringName = "target_pos"

func _tick(_delta: float) -> Status:
	var agent = blackboard.get_var("agent") as CharacterBody3D
	if not agent:
		return FAILURE
	
	var center = agent.home_position
	
	var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var random_dist = randf_range(0, radius)
	var raw_pos = center + (random_dir * random_dist)
	
	var nav_map = agent.get_world_3d().get_navigation_map()
	var final_pos = NavigationServer3D.map_get_closest_point(nav_map, raw_pos)
	
	blackboard.set_var(target_var, final_pos)
	
	return SUCCESS
