@tool
extends BTAction

@export var target_var: StringName = "target_pos"
@export var tolerance: float = 0.5 

func _tick(_delta: float) -> Status:
	var agent = blackboard.get_var("agent") as CharacterBody3D
	var target_pos = blackboard.get_var(target_var, Vector3.ZERO)
	
	if not agent: return FAILURE
	
	agent.move_to(target_pos)
	
	if agent.nav_agent.is_navigation_finished():
		return SUCCESS
		
	return RUNNING
