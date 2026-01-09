@tool
extends BTAction

func _tick(_delta: float) -> Status:
	var agent = blackboard.get_var("agent")
	if not is_instance_valid(agent):
		return FAILURE
	
	if blackboard.get_var("is_hungry", false):
		agent.eat_food()
		return SUCCESS
		
	return FAILURE
