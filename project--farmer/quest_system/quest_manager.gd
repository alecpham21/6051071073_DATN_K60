extends Node

signal quest_updated
signal reward_distributed(type: String, data: Variant, amount: int)

var quests: Dictionary = {}
var active_contract_item: ItemDataMaterial = null
var contract_amount_needed: int = 0
var contract_deadline_day: int = 0
var current_contract_id: String = "trade_contract_loop"

func _ready():
	_load_all_quests("res://quests/")
	
	if SignalBus.has_signal("object_harvested"):
		SignalBus.object_harvested.connect(_on_object_harvested)
	
	if SignalBus.has_signal("item_added_to_inventory"):
		SignalBus.item_added_to_inventory.connect(_on_item_added_to_inventory)
	
	TimeManager.tick.connect(_check_contract_deadline)

func _check_contract_deadline():
	if active_contract_item != null:
		if TimeManager.day > contract_deadline_day:
			_fail_contract()

func _fail_contract():
	print("❌ Contract Fail! Expired Date.")
	
	if quests.has(current_contract_id):
		quests.erase(current_contract_id)
	
	active_contract_item = null
	contract_amount_needed = 0
	
	quest_updated.emit()


func _on_object_harvested(obj_name: String, amount: int):
	for q_id in quests:
		var q = quests[q_id]
		
		if q.is_started and not q.is_completed:
			var any_update = false
			
			for obj in q.objectives:
				if not obj.is_completed and obj.required_item_id == obj_name:
					obj.current_amount += amount
					
					print("   -> Cập nhật '", obj.description, "': ", obj.current_amount, "/", obj.target_amount)
					
					if obj.current_amount >= obj.target_amount:
						obj.current_amount = obj.target_amount
						obj.is_completed = true
						print("   ✅ Đã xong mục tiêu: ", obj.description)
					
					any_update = true
			
			if any_update:
				if q.check_completion():
					complete_quest(q_id)

func _load_all_quests(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var quest_res = load(path + "/" + file_name)
				if quest_res is QuestResource:
					var new_quest = quest_res.duplicate(true)
					
					_reset_quest_state(new_quest)
					
					register_quest(new_quest)
					print("Đã load nhiệm vụ: " + new_quest.id)
			file_name = dir.get_next()
	else:
		print("Không tìm thấy thư mục quests!")

func _reset_quest_state(q: QuestResource):
	q.is_started = false
	q.is_completed = false
	for obj in q.objectives:
		obj.current_amount = 0
		obj.is_completed = false

func register_quest(quest: QuestResource):
	if not quests.has(quest.id):
		quests[quest.id] = quest

func start_quest(quest_id: String):
	if quests.has(quest_id):
		var q = quests[quest_id]
		if not q.is_started:
			q.is_started = true
			print("📜 Đã nhận nhiệm vụ: " + q.title)
			
			quest_updated.emit() 
			
			if q.check_completion():
				complete_quest(quest_id)

func complete_quest(quest_id: String):
	if quests.has(quest_id):
		var q = quests[quest_id]
		if not q.is_completed:
			q.is_completed = true
			print("🎉 QUEST COMPLETED: " + q.title)
			
			_handle_rewards(q)
			
			quest_updated.emit()
			
			if q.next_quest_id != "":
				start_quest(q.next_quest_id)

func _handle_rewards(q: QuestResource):
	if q.reward_gold > 0:
		reward_distributed.emit("GOLD", null, q.reward_gold)
	
	if q.reward_xp > 0:
		reward_distributed.emit("XP", null, q.reward_xp)
	
	for slot in q.reward_items:
		if slot and slot.item_data:
			print("   🎁 Reward Item: ", slot.item_data.name, " x", slot.quantity)
			
			reward_distributed.emit("ITEM", slot.item_data, slot.quantity)


func check_status(quest_id: String) -> String:
	if not quests.has(quest_id): return "unknown"
	if quests[quest_id].is_completed: return "completed"
	if quests[quest_id].is_started: return "started"
	return "available"

func _on_item_added_to_inventory(item_name: String, amount: int):
	_on_object_harvested(item_name, amount)


func start_trade_contract(item_id: String, amount: int, days_to_complete: int):
	var path = "res://inventory_script/item/items/item_harvest/" + item_id + ".tres"
	
	if not ResourceLoader.exists(path):
		printerr("❌ LỖI: Không tìm thấy file item tại: ", path)
		return
		
	var item_res = load(path) as ItemDataMaterial
	if not item_res:
		printerr("❌ LỖI: File đã load không phải là ItemDataMaterial: ", path)
		return

	active_contract_item = item_res
	contract_amount_needed = amount
	contract_deadline_day = TimeManager.day + days_to_complete
	
	var contract_q = QuestResource.new()
	contract_q.id = current_contract_id
	contract_q.title = "Hợp đồng: " + item_res.name
	contract_q.quest_type = QuestResource.QuestType.SIDE
	contract_q.description = "Yêu cầu: %d %s. Hạn giao: Ngày %d" % [amount, item_res.name, contract_deadline_day]
	
	var obj = QuestObjective.new()
	obj.description = "Đóng thùng " + item_res.name
	obj.required_item_id = item_res.name 
	obj.target_amount = amount
	
	contract_q.objectives.append(obj)
	
	if quests.has(current_contract_id):
		quests.erase(current_contract_id)
		
	register_quest(contract_q)
	start_quest(current_contract_id)
	
	print("✅ Bắt đầu hợp đồng: ", item_res.name, " x", amount)

func update_contract_progress(item_name: String, current_amount: int):
	if quests.has(current_contract_id):
		var q = quests[current_contract_id]
		for obj in q.objectives:
			if obj.required_item_id == item_name:
				obj.current_amount = current_amount
				quest_updated.emit()
