extends Node3D
class_name WashingMachine

signal toggle_inventory(external_inventory_owner)

@onready var machine_mesh: Node3D = $WashingClotheMachine

@export var machine_id: String = ""
@export var inventory_data: InventoryData
@export var interact_area: InteractArea 
@export var wash_duration_minutes: float = 30.0 # Giảm xuống 30p game để test cho lẹ

var open: bool = false
var finish_time: float = -1.0
var tween: Tween

func _ready() -> void:
	print("--- Washing Machine Init ---")
	if machine_id.is_empty():
		inventory_data = inventory_data.duplicate()
	else:
		if PlayerData.chest_inventories.has(machine_id):
			inventory_data = PlayerData.chest_inventories[machine_id]
		else:
			inventory_data = inventory_data.duplicate()
			PlayerData.chest_inventories[machine_id] = inventory_data
			
	interact_area.interacted.connect(on_interact)
	
	# Kết nối signal inventory
	if not inventory_data.inventory_updated.is_connected(_on_inventory_updated):
		inventory_data.inventory_updated.connect(_on_inventory_updated)
	
	# Kết nối signal thời gian
	TimeManager.tick.connect(_on_time_tick)
	
	Watcher.game_state_changed.connect(func(a):
		if GState.is_ui(): return)


func _process(delta: float) -> void:
	if finish_time > 0:
		shake_machine()
	else:
		if machine_mesh.rotation_degrees.z != 0:
			machine_mesh.rotation_degrees.z = lerp(machine_mesh.rotation_degrees.z, 0.0, delta * 5)

func shake_machine():
	# Tạo hiệu ứng rung nhẹ bằng cách xoay qua lại trục Z
	var time = Time.get_ticks_msec() / 100.0
	machine_mesh.rotation_degrees.z = sin(time * 20) * 2.0 # Rung biên độ 2 độ

func on_interact():
	if open: close_chest()
	else: open_chest()

func open_chest(): 
	if open: return
	open = true
	print("Máy giặt: Mở UI")
	toggle_inventory.emit(self)

func close_chest():
	if !open: return
	open = false
	print("Máy giặt: Đóng UI")
	toggle_inventory.emit(self)

# --- DEBUG LOGIC GIẶT ---
func _on_inventory_updated(_data: InventoryData) -> void:
	if finish_time > 0: return

	var found_dirty = false
	for slot in inventory_data.slot_datas:
		if slot and slot.item_data is ItemDataOutfit:
			# --- SỬA: Check độ dơ từ SLOT ---
			if slot.current_dirt_level > 0: 
				print("-> Thấy đồ dơ: ", slot.item_data.name, " | Dơ: ", slot.current_dirt_level)
				found_dirty = true
				break
	
	if found_dirty:
		start_washing()

func start_washing() -> void:
	print(">>> MÁY GIẶT: BẮT ĐẦU CHẠY! <<<")
	inventory_data.is_locked = true
	
	var current_total_minutes = TimeManager.get_total_minutes_played()
	finish_time = current_total_minutes + wash_duration_minutes
	
	print("Thời gian hiện tại: ", current_total_minutes)
	print("Dự kiến xong lúc: ", finish_time)

func _on_time_tick() -> void:
	if finish_time == -1.0:
		return
		
	var current = TimeManager.get_total_minutes_played()
	print("Đang giặt... ", current, "/", finish_time) # Bật cái này nếu muốn soi kỹ
	
	if current >= finish_time:
		finish_washing()

func finish_washing() -> void:
	print(">>> MÁY GIẶT: HOÀN THÀNH! <<<")
	
	for slot in inventory_data.slot_datas:
		if slot and slot.item_data is ItemDataOutfit:
			# --- SỬA: Gọi hàm clean của SLOT ---
			slot.clean_slot()
			print("-> Đã giặt sạch slot chứa: ", slot.item_data.name)
	
	finish_time = -1.0
	inventory_data.is_locked = false 
	inventory_data.inventory_updated.emit(inventory_data)
