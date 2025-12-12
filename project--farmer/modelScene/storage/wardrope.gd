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
		#Check AUTOLOAD
		if PlayerData.chest_inventories.has(chest_id):
			inventory_data = PlayerData.chest_inventories[chest_id]
		else:
			inventory_data = inventory_data.duplicate()
			PlayerData.chest_inventories[chest_id] = inventory_data
			
	interact_area.interacted.connect(on_interact)
	
	Watcher.game_state_changed.connect(func(a):
		if GState.is_ui(): return)


func on_interact():
	if open:
		# Nếu đang mở -> thì đóng lại
		toggle_inventory.emit(self) 
		close_chest()
		GState.play()
	else:
		# Nếu đang đóng -> thì mở ra (giữ nguyên logic cũ)
		open_chest()

func open_chest(): 
	if open: return
	open = true
	#GState.ui()
	toggle_inventory.emit(self)

func close_chest():
	if !open: return
	open = false
	# Bạn nên thêm dòng này để trả về trạng thái Game (nếu cần)
	# GState.play() 
