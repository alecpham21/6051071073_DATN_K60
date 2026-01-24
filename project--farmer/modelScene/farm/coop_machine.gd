extends LivestockMachine
class_name CoopMachine

@export_group("Visual Settings")
@export var spawn_point: Marker3D 
@export var adult_chicken_icon: Texture2D

@export_group("Data & Logic")
@export var input_inv: InventoryData
@export var output_inv: InventoryData
@export var egg_item: ItemData
@export var max_capacity: int = 4
@export var days_to_adult: int = 5
@export var accepted_feeds: Array[String] = ["Chicken Feed", "Seed"]

@export var eggs_per_batch: int = 20
@export var minutes_to_finish_batch: float = 100.0

@onready var interact_area: InteractArea = $InteractArea

var chickens: Array[ChickenData] = []
var visual_chickens: Array[Node3D] = []
var last_day: int = 1

func _ready():
	if TimeManager.has_signal("tick"):
		TimeManager.tick.connect(_on_time_tick)
	
	_setup_initial_slots()
	
	input_inv.inventory_updated.connect(_on_input_inv_updated)
	interact_area.interacted.connect(_on_interacted)

func _setup_initial_slots():
	for inv in [input_inv, output_inv]:
		if inv:
			if inv.slot_datas.size() != max_capacity:
				inv.slot_datas.resize(max_capacity)
			inv.refresh()
	
	chickens.resize(max_capacity)
	visual_chickens.resize(max_capacity)

func _on_input_inv_updated(_inv):
	for i in range(max_capacity):
		var slot = input_inv.slot_datas[i]
		
		if slot and slot.item_data is ItemDataLivestock and chickens[i] == null:
			var ls = slot.item_data as ItemDataLivestock
			var new_data = ChickenData.new()
			new_data.gender = ls.gender
			new_data.stage = ls.stage
			new_data.birthday = TimeManager.get_total_minutes_played()
			
			chickens[i] = new_data
			_spawn_at_index(i, ls.entity_scene)
			
		elif slot == null and chickens[i] != null:
			chickens[i] = null
			if visual_chickens[i]:
				visual_chickens[i].queue_free()
				visual_chickens[i] = null

func _spawn_at_index(idx: int, scene: PackedScene):
	if not scene: return
	var chicken = scene.instantiate()
	add_child(chicken)
	
	var spawn_pos = spawn_point.global_position if spawn_point else global_position
	var offset = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	chicken.global_position = spawn_pos + offset
	
	if chicken.has_method("setup"):
		chicken.setup(chickens[idx])
	
	visual_chickens[idx] = chicken

func _on_time_tick():
	var current_total_min = TimeManager.get_total_minutes_played()
	var minutes_needed = days_to_adult * 24 * 60
	var has_update = false
	
	if TimeManager.day > last_day:
		for i in range(chickens.size()):
			var chicken = chickens[i]
			if chicken:
				if chicken.feed_count >= 2:
					chicken.yield_bonus += 0.2
				
				chicken.feed_count = 0
				
				if visual_chickens[i] and visual_chickens[i].bt_player:
					visual_chickens[i].bt_player.blackboard.set_var("is_hungry", true)
		
		last_day = TimeManager.day
		has_update = true

	for i in range(chickens.size()):
		var chicken = chickens[i]
		if chicken and chicken.stage == LivestockEnums.Stage.BABY:
			if (current_total_min - chicken.birthday) >= minutes_needed:
				chicken.stage = LivestockEnums.Stage.ADULT
				has_update = true
				
				var slot = input_inv.slot_datas[i]
				if slot and slot.item_data is ItemDataLivestock:
					var old_item = slot.item_data as ItemDataLivestock
					
					if old_item.adult_version:
						slot.item_data = old_item.adult_version
					else:
						slot.item_data = slot.item_data.duplicate()
						slot.item_data.stage = LivestockEnums.Stage.ADULT
						if adult_chicken_icon:
							slot.item_data.texture = adult_chicken_icon
						
				if i < visual_chickens.size() and visual_chickens[i]:
					if visual_chickens[i].has_method("update_visual"):
						visual_chickens[i].update_visual()
	
	if has_update:
		input_inv.inventory_updated.emit(input_inv)
	
	_process_egg_production(1.0)

func _process_egg_production(delta_min: float):
	var rooster_ready = chickens.any(func(c): 
		return c != null and c.gender == LivestockEnums.Gender.MALE and c.stage == LivestockEnums.Stage.ADULT and c.feed_count >= 1
	)
	if not rooster_ready: return

	var has_update = false
	for i in range(max_capacity):
		var chicken = chickens[i]
		if chicken and chicken.gender == LivestockEnums.Gender.FEMALE and chicken.stage == LivestockEnums.Stage.ADULT:
			if chicken.feed_count > 0:
				var speed = 100.0 / minutes_to_finish_batch
				chicken.egg_progress += speed * delta_min
				has_update = true
				
				if chicken.egg_progress >= 100.0:
					var daily_bonus = 0.2 if chicken.feed_count >= 2 else 0.0
					var total_bonus = chicken.yield_bonus + daily_bonus
					
					var final_yield = roundi(eggs_per_batch * (1.0 + total_bonus))
					
					if output_inv.add_item_at_index(egg_item, final_yield, i):
						chicken.egg_progress = 0.0
						chicken.yield_bonus = 0.0 
						print("🥚 Đẻ xong: ", final_yield, " trứng (Bonus tổng: ", total_bonus * 100, "%)")
					else:
						chicken.egg_progress = 100.0

	if has_update:
		input_inv.inventory_updated.emit(input_inv)

func _on_interacted():
	if PlayerData.is_player_stinky(): return
	var ui = get_tree().get_first_node_in_group("coop_ui")
	if ui: ui.open(self)

func get_coop_stage(exclude_index: int = -1) -> int:
	for i in range(chickens.size()):
		if i == exclude_index: continue
		var chicken = chickens[i]
		if chicken != null:
			return chicken.stage
	return -1

func feed_livestock(item_data: ItemData) -> bool:
	if not item_data: return false
	var item_name = item_data.name.to_lower()
	var is_valid = false
	for f in accepted_feeds:
		if f.to_lower() in item_name:
			is_valid = true
			break
	if not is_valid: return false

	var fed_at_least_one = false
	for i in range(chickens.size()):
		var c = chickens[i]
		if c and c.feed_count < c.get_max_feed():
			c.feed_count += 1
			fed_at_least_one = true
			if visual_chickens[i] and visual_chickens[i].bt_player:
				visual_chickens[i].bt_player.blackboard.set_var("is_hungry", false)
	
	if fed_at_least_one:
		input_inv.inventory_updated.emit(input_inv)
		return true
		
	return false

func get_machine_data() -> Dictionary:
	var saved_chickens = []
	for c in chickens:
		if c: saved_chickens.append(c.duplicate())
		else: saved_chickens.append(null)

	return {
		"chickens": saved_chickens,
		"last_day": last_day,
		"input_inv": input_inv.get_save_data(),
		"output_inv": output_inv.get_save_data()
	}

func load_machine_data(data: Dictionary, minutes_away: float = 0.0):
	if input_inv.inventory_updated.is_connected(_on_input_inv_updated):
		input_inv.inventory_updated.disconnect(_on_input_inv_updated)

	if data.has("input_inv"): input_inv.load_save_data(data["input_inv"])
	if data.has("output_inv"): output_inv.load_save_data(data["output_inv"])
	if data.has("chickens"):
		chickens.assign(data["chickens"]) 
		print("🐔 [CoopMachine] Restored ", chickens.size(), " chickens safely.")
	if data.has("last_day"): last_day = data["last_day"]

	if minutes_away > 0:
		_simulate_offline_time(minutes_away)
	
	_refresh_visual_after_load()

	if not input_inv.inventory_updated.is_connected(_on_input_inv_updated):
		input_inv.inventory_updated.connect(_on_input_inv_updated)
	input_inv.inventory_updated.emit(input_inv)

func _refresh_visual_after_load():
	print("🎬 [CoopMachine] Đang làm mới Visual...")
	for v in visual_chickens:
		if is_instance_valid(v): v.queue_free()
	visual_chickens.clear()
	visual_chickens.resize(max_capacity)
	
	for i in range(max_capacity):
		var slot = input_inv.slot_datas[i]
		if chickens[i] != null:
			if slot and slot.item_data is ItemDataLivestock:
				var ls = slot.item_data as ItemDataLivestock
				print("✨ [CoopMachine] Đang tạo gà tại index: ", i, " (Stage: ", chickens[i].stage, ")")
				_spawn_at_index(i, ls.entity_scene)
				
				if visual_chickens[i] and visual_chickens[i].has_method("update_visual"):
					visual_chickens[i].update_visual()
			else:
				print("⚠️ [CoopMachine] Slot ", i, " có data gà nhưng ItemData trong túi đồ bị trống!")

func _simulate_offline_time(total_min_away: float):
	var days_passed = floor(total_min_away / (24 * 60))
	
	if days_passed > 0:
		for chicken in chickens:
			if chicken:
				if chicken.feed_count >= 2:
					chicken.yield_bonus += 0.2
				chicken.feed_count = 0 
		last_day += days_passed
	_process_egg_production(total_min_away)
	print("⏳ Make up for the chick", total_min_away, "minute")
