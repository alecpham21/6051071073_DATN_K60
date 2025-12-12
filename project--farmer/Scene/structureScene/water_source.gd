extends Node3D
class_name WaterSource

@export var max_capacity: float = 10.0 

@onready var interact_area: InteractArea = $InteractArea

func _ready() -> void:
	# Nối signal từ InteractArea
	if interact_area:
		interact_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	# Lấy item đang cầm trên tay từ HotBar
	var active_slot = HotBar.active_slot
	
	if active_slot and active_slot.item_data:
		# Kiểm tra tên xem có phải bình tưới không
		# (Hoặc ông có thể check active_slot.item_data is ItemDataTool)
		if "watering can" in active_slot.item_data.name.to_lower():
			
			# NẠP ĐẦY NƯỚC: Dùng set_stat của hệ thống Attribute mới
			active_slot.set_stat("water_max", max_capacity)
			active_slot.set_stat("water_current", max_capacity)
			
			print("💦 Đã múc đầy nước! (%s/%s)" % [max_capacity, max_capacity])
			
			# Báo UI update (để icon sáng lại)
			PlayerData.player_inventory_data.inventory_updated.emit(PlayerData.player_inventory_data)
			
			# (Optional) Play Sound múc nước ở đây
		else:
			print("🚫 Cần cầm bình tưới để lấy nước!")
	else:
		print("Tay không thì múc bằng gì?")
