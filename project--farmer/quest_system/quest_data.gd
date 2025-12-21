extends Resource
class_name QuestResource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var target_amount: int = 1
var current_amount: int = 0
var is_completed: bool = false
var is_started: bool = false
