extends Node

func get_save_path(slot_name: String) -> String:
	return "user://save_" + slot_name + ".dat"

func save_game(slot_name: String = "manual_save_1"):
	var current_lvl = get_tree().current_scene
	if current_lvl.has_method("save_level_state"):
		current_lvl.save_level_state()
	
	var save_dict = {
		"scene_path": get_tree().current_scene.scene_file_path,
		"game_data": {
			"unlocked_doors": GameData.unlocked_doors,
			"john_has_left": GameData.john_has_left,
			"washing_timers": PlayerData.washing_machine_timers
		},
		"chests": _get_chest_save_data(),
		"player": {
			"money": PlayerData.money,
			"stats": PlayerData.stats.get_save_data(),
			"position": var_to_str(PlayerData.player.global_position if PlayerData.player else Vector3.ZERO),
			"inv": PlayerData.player_inventory_data.get_save_data(),
			"equip": PlayerData.player_equip_data.get_save_data(),
			"outfit": PlayerData.player_outfit_data.get_save_data()
		},
		"time": {
			"day": TimeManager.day,
			"current_time": TimeManager.current_time
		},
		"quests": _get_quest_save_data(),
		"world_states": Watcher.world_states 
	}

	var path = get_save_path(slot_name)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(save_dict)
		file.close()
		print("✅ Game Saved to File (including Watcher states)")

func load_game(slot_name: String = "manual_save_1"):
	var path = get_save_path(slot_name)
	if not FileAccess.file_exists(path): return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	if data.has("game_data"):
		GameData.unlocked_doors = data.game_data.unlocked_doors
		GameData.john_has_left = data.game_data.john_has_left
		
		if data.game_data.has("washing_timers"):
			PlayerData.washing_machine_timers = data.game_data.washing_timers
			print("[DEBUG] SaveManager: Restored washing timers.")
	
	if data.player.has("stats"):
		PlayerData.stats.load_save_data(data.player.stats)
	
	if data.has("world_states"):
		Watcher.world_states = data.world_states
	
	if data.has("chests"):
		_load_chest_save_data(data.chests)
	
	TimeManager.day = data.time.day
	TimeManager.current_time = data.time.current_time
	PlayerData.money = data.player.money

	var pos = str_to_var(data.player.position)
	SceneTransition.change_scene(data.scene_path, pos)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	PlayerData.player_inventory_data.load_save_data(data.player.inv)
	PlayerData.player_equip_data.load_save_data(data.player.equip)
	PlayerData.player_outfit_data.load_save_data(data.player.outfit)
	_load_quest_save_data(data.quests)

func _get_quest_save_data() -> Dictionary:
	var q_data = {
		"list": {},
		"contract": {
			"item_path": QuestManager.active_contract_item.resource_path if QuestManager.active_contract_item else "",
			"amount_needed": QuestManager.contract_amount_needed,
			"deadline": QuestManager.contract_deadline_day,
			"truck_arrived": QuestManager.truck_has_arrived,
			"truck_departed": QuestManager.truck_has_departed
		}
	}
	
	for id in QuestManager.quests:
		var q = QuestManager.quests[id]
		q_data.list[id] = {
			"started": q.is_started,
			"completed": q.is_completed,
			"objs": q.objectives.map(func(o): return {"cur": o.current_amount, "done": o.is_completed})
		}
	return q_data

func _load_quest_save_data(data: Dictionary):
	var list = data.get("list", {})
	for id in list:
		if QuestManager.quests.has(id):
			var q = QuestManager.quests[id]
			q.is_started = list[id].started
			q.is_completed = list[id].completed
			for i in range(q.objectives.size()):
				if i < list[id].objs.size():
					q.objectives[i].current_amount = list[id].objs[i].cur
					q.objectives[i].is_completed = list[id].objs[i].done

	var c_info = data.get("contract", {})
	if c_info.get("item_path", "") != "":
		QuestManager.active_contract_item = load(c_info.item_path)
		QuestManager.contract_amount_needed = c_info.get("amount_needed", 0)
		QuestManager.contract_deadline_day = c_info.get("deadline", 0)
		QuestManager.truck_has_arrived = c_info.get("truck_arrived", false)
		QuestManager.truck_has_departed = c_info.get("truck_departed", false)

func _get_chest_save_data() -> Dictionary:
	var dict = {}
	for id in PlayerData.chest_inventories:
		dict[id] = PlayerData.chest_inventories[id].get_save_data()
	return dict


func _load_chest_save_data(dict: Dictionary):
	PlayerData.chest_inventories.clear()
	for id in dict:
		var inv = InventoryData.new() 
		
		inv.load_save_data(dict[id]) 
		
		PlayerData.chest_inventories[id] = inv
