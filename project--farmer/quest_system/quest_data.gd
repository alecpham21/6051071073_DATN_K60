extends Resource
class_name QuestResource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export var objectives: Array[QuestObjective] = []

@export var next_quest_id: String = ""

var is_started: bool = false
var is_completed: bool = false

func check_completion() -> bool:
	for obj in objectives:
		if not obj.is_completed:
			return false
	return true
