extends Node

var quests: Dictionary = {}

func _ready():
	_load_all_quests("res://quests/")

func _load_all_quests(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var quest_resource = load(path + "/" + file_name)
				if quest_resource is QuestResource:
					register_quest(quest_resource)
					print("Đã load nhiệm vụ: " + quest_resource.id)
			file_name = dir.get_next()
	else:
		print("Không tìm thấy thư mục quests!")

func register_quest(quest: QuestResource):
	if not quests.has(quest.id):
		quests[quest.id] = quest

func start_quest(quest_id: String):
	if quests.has(quest_id):
		quests[quest_id].is_started = true
		print("Đã nhận nhiệm vụ: " + quests[quest_id].title)

func update_progress(quest_id: String, amount: int = 1):
	if quests.has(quest_id) and quests[quest_id].is_started:
		var q = quests[quest_id]
		q.current_amount += amount
		if q.current_amount >= q.target_amount:
			complete_quest(quest_id)

func complete_quest(quest_id: String):
	if quests.has(quest_id):
		quests[quest_id].is_completed = true
		print("Hoàn thành nhiệm vụ: " + quests[quest_id].title)

func check_status(quest_id: String) -> String:
	if not quests.has(quest_id): return "unknown"
	if quests[quest_id].is_completed: return "completed"
	if quests[quest_id].is_started: return "started"
	return "available"
