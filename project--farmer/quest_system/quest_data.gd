extends Resource
class_name QuestResource

enum QuestType { MAIN, FARMING, LIVESTOCK, SIDE }

@export var id: String = ""
@export var title: String = ""
@export var quest_type: QuestType = QuestType.MAIN 
@export_multiline var description: String = ""

@export var objectives: Array[QuestObjective] = []
@export var next_quest_id: String = ""

@export_group("Rewards")
@export var reward_gold: int = 0
@export var reward_xp: int = 0

@export var reward_items: Array[SlotData] = [] 

var is_started: bool = false
var is_completed: bool = false

func check_completion() -> bool:
	for obj in objectives:
		if not obj.is_completed:
			return false
	return true
