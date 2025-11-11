extends Node3D
class_name Chest

signal toggle_inventory(external_inventory_owner)

@export var inventory_data: InventoryData
@export var ani:AnimationPlayer
@export var interact_area:InteractArea

var open:bool = false

func _ready() -> void:
	interact_area.interacted.connect(on_interact)
	
	Watcher.game_state_changed.connect(func(a):
		if GState.is_ui(): return
		close_chest())

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
	GState.ui()
	toggle_inventory.emit(self)
	ani.play("Open")

func close_chest():
	if !open: return
	open = false
	# Bạn nên thêm dòng này để trả về trạng thái Game (nếu cần)
	# GState.play() 
	ani.play("Close")
