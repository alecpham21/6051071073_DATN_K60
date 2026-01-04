@tool
extends BTAction

func _tick(_delta: float) -> Status:
	var agent = blackboard.get_var("agent")
	if not is_instance_valid(agent):
		return FAILURE
	
	agent.eat_food() 
	return SUCCESS
