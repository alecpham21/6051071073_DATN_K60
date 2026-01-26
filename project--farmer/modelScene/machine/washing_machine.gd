extends Node3D
class_name WashingMachine

signal toggle_inventory(external_inventory_owner)

@onready var machine_mesh: Node3D = $WashingClotheMachine

@export var machine_id: String = ""
@export var inventory_data: InventoryData
@export var interact_area: InteractArea 
@export var wash_duration_minutes: float = 60.0

var open: bool = false
var is_washing: bool = false
var finish_time: float = -1.0

func _ready() -> void:
	print("--- Washing Machine Init: ", machine_id, " ---")
	
	if machine_id.is_empty():
		inventory_data = inventory_data.duplicate()
	else:
		if PlayerData.chest_inventories.has(machine_id):
			inventory_data = PlayerData.chest_inventories[machine_id]
		else:
			inventory_data = inventory_data.duplicate()
			PlayerData.chest_inventories[machine_id] = inventory_data
			
	interact_area.interacted.connect(on_interact)
	TimeManager.tick.connect(_on_time_tick)
	
	if !machine_id.is_empty() and PlayerData.washing_machine_timers.has(machine_id):
		var saved_finish_time = PlayerData.washing_machine_timers[machine_id]
		var current_time = TimeManager.get_total_minutes_played()
		
		if current_time >= saved_finish_time:
			print("WashingMachine: Complete While Player Not Here!")
			finish_washing(true)
		else:
			finish_time = saved_finish_time
			is_washing = true
			inventory_data.is_locked = true
			print("Washing Machine: Continue... Remain ", saved_finish_time - current_time, " minute")

func _process(delta: float) -> void:
	if is_washing:
		shake_machine()
	else:
		if machine_mesh.rotation_degrees.z != 0:
			machine_mesh.rotation_degrees.z = lerp(machine_mesh.rotation_degrees.z, 0.0, delta * 5)

func shake_machine():
	var time = Time.get_ticks_msec() / 100.0
	machine_mesh.rotation_degrees.z = sin(time * 20) * 2.0

func on_interact():
	if is_washing:
		print("Washing Machine Working cant Open!")
		return

	if open: close_chest()
	else: open_chest()

func open_chest(): 
	if open: return
	open = true
	toggle_inventory.emit(self)

func close_chest():
	if !open: return
	open = false
	toggle_inventory.emit(self)

func request_start_washing():
	if is_washing: return
	
	var found_dirty = false
	for slot in inventory_data.slot_datas:
		if slot and slot.item_data is ItemDataOutfit and slot.get_stat("dirt") > 0:
			found_dirty = true
			break
	
	if not found_dirty:
		print("No dirty, No Wash!")
		return
	
	start_washing_process()

func start_washing_process():
	print(">>>Button Pressed: Proceed to Wash <<<")
	
	close_chest()
	
	is_washing = true
	inventory_data.is_locked = true
	
	var current_total_minutes = TimeManager.get_total_minutes_played()
	finish_time = current_total_minutes + wash_duration_minutes
	
	if !machine_id.is_empty():
		PlayerData.washing_machine_timers[machine_id] = finish_time
	
	print("Time on complete: ", finish_time)

func _on_time_tick() -> void:
	if not is_washing or finish_time == -1.0:
		return
		
	var current = TimeManager.get_total_minutes_played()
	
	if current >= finish_time:
		finish_washing()

func finish_washing(instant: bool = false):
	print(">>> Washing Machine: Complete Washed<<<")
	
	# Làm sạch đồ
	for slot in inventory_data.slot_datas:
		if slot and slot.item_data is ItemDataOutfit:
			if slot.get_stat("dirt") > 0:
				slot.clean_slot()
				print("-> Cleaned: ", slot.item_data.name)
	
	is_washing = false
	finish_time = -1.0
	inventory_data.is_locked = false 
	
	inventory_data.inventory_updated.emit(inventory_data)

	if !machine_id.is_empty():
		PlayerData.washing_machine_timers.erase(machine_id)
