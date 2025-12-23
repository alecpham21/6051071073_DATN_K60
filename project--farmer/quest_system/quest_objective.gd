extends Resource
class_name QuestObjective

@export var description: String = "Mission Description"
@export var required_item_id: String = ""
@export var target_amount: int = 1

var current_amount: int = 0
var is_completed: bool = false
