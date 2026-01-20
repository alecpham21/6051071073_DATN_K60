extends Node

func get_save_path(slot_name: String) -> String:
	return "user://save_" + slot_name + ".dat"

func save_game(slot_name: String = "manual_save_1"):
	var current_lvl = get_tree().current_scene
	if current_lvl.has_method("save_level_state"):
		current_lvl.save_level_state()
	
	var save_dict = {
		"scene_path": get_tree().current_scene.scene_file_path,
		"player": {
			"money": PlayerData.money,
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

	if data.has("world_states"):
		Watcher.world_states = data.world_states
	
	TimeManager.day = data.time.day
	TimeManager.current_time = data.time.current_time
	PlayerData.money = data.player.money

	var pos = str_to_var(data.player.position)
	SceneTransition.change_scene(data.scene_path, pos)

	await get_tree().process_frame
	PlayerData.player_inventory_data.load_save_data(data.player.inv)
	PlayerData.player_equip_data.load_save_data(data.player.equip)
	PlayerData.player_outfit_data.load_save_data(data.player.outfit)
	_load_quest_save_data(data.quests)

func _get_quest_save_data() -> Dictionary:
	var q_data = {}
	for id in QuestManager.quests:
		var q = QuestManager.quests[id]
		q_data[id] = {
			"started": q.is_started,
			"completed": q.is_completed,
			"objs": q.objectives.map(func(o): return {"cur": o.current_amount, "done": o.is_completed})
		}
	return q_data

func _load_quest_save_data(data: Dictionary):
	for id in data:
		if QuestManager.quests.has(id):
			var q = QuestManager.quests[id]
			q.is_started = data[id].started
			q.is_completed = data[id].completed
			for i in range(q.objectives.size()):
				if i < data[id].objs.size():
					q.objectives[i].current_amount = data[id].objs[i].cur
					q.objectives[i].is_completed = data[id].objs[i].done
