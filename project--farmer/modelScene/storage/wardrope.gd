extends Node3D
class_name Box

signal toggle_inventory(external_inventory_owner)

@export var chest_id: String = ""
@export var inventory_data: InventoryData
@export var interact_area:InteractArea

var open:bool = false

func _ready() -> void:
	#Check ID
	if chest_id.is_empty():
		push_error("Rương này CHƯA ĐẶT chest_id, sẽ không thể LƯU/TẢI!")
		inventory_data = inventory_data.duplicate()
		
	else:
		if PlayerData.chest_inventories.has(chest_id):
			inventory_data = PlayerData.chest_inventories[chest_id]
		else:
			inventory_data = inventory_data.duplicate()
			PlayerData.chest_inventories[chest_id] = inventory_data
			
	
	if interact_area:
		interact_area.interacted.connect(on_interact)
	
	Watcher.game_state_changed.connect(func(a):
		if GState.is_ui(): return
		close_chest())


func on_interact():
	if open:
		toggle_inventory.emit(self) 
		close_chest()
		GState.play()
	else:
		open_chest()

func open_crate_inventory():
	open_chest()

func open_chest(): 
	if open: return
	open = true
	if SignalBus.has_signal("inventory_opened"):
		SignalBus.inventory_opened.emit(self)
	
	GState.ui()

func close_chest():
	if !open: return
	open = false
	# Bạn nên thêm dòng này để trả về trạng thái Game (nếu cần)
	# GState.play() 
