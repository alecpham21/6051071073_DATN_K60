class_name CoopMachine
extends Node3D

@export_group("Visual Settings")
@export var spawn_point: Marker3D 

@export_group("Data & Logic")
@export var input_inv: InventoryData
@export var output_inv: InventoryData
@export var egg_item: ItemData
@export var max_capacity: int = 4
@export var days_to_adult: int = 5

@onready var interact_area: InteractArea = $InteractArea

var chickens: Array[ChickenData] = []
var visual_chickens: Array[Node3D] = []

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
	chicken.global_position = spawn_point.global_position if spawn_point else global_position
	
	if chicken.has_method("setup"):
		chicken.setup(chickens[idx])
	
	visual_chickens[idx] = chicken

func _on_time_tick():
	var current_total_min = TimeManager.get_total_minutes_played()
	var minutes_needed = days_to_adult * 24 * 60
	
	for i in range(chickens.size()):
		var chicken = chickens[i]
		if chicken and chicken.stage == LivestockEnums.Stage.BABY:
			if (current_total_min - chicken.birthday) >= minutes_needed:
				chicken.stage = LivestockEnums.Stage.ADULT
				
				if i < visual_chickens.size() and visual_chickens[i]:
					if visual_chickens[i].has_method("update_visual"):
						visual_chickens[i].update_visual()
	
	_process_egg_production(1.0)
func _process_egg_production(delta_min: float):
	var rooster_ready = chickens.any(func(c): 
		return c != null and c.gender == LivestockEnums.Gender.MALE and c.stage == LivestockEnums.Stage.ADULT and c.feed_count >= 1
	)
	if not rooster_ready: return

	for i in range(max_capacity):
		var chicken = chickens[i]
		if chicken and chicken.gender == LivestockEnums.Gender.FEMALE and chicken.stage == LivestockEnums.Stage.ADULT:
			if chicken.feed_count > 0:
				var speed = 100.0 / 20.0
				chicken.egg_progress += speed * delta_min
				
				if chicken.egg_progress >= 100.0:
					if output_inv.add_item_at_index(egg_item, 1, i):
						chicken.egg_progress = 0.0

func _on_interacted():
	if PlayerData.is_player_stinky(): return
	var ui = get_tree().get_first_node_in_group("coop_ui")
	if ui: ui.open(self)
