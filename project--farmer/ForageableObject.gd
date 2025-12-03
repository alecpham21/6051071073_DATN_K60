extends Node3D

@export var item_data: ItemData # Resource của cái Măng
@export_range(1, 5) var min_qty: int = 1
@export_range(1, 5) var max_qty: int = 3

# Hàm này tên là harvest để trùng khớp với logic Player gọi
func harvest() -> void:
	# 1. Tính số lượng random
	var quantity = randi_range(min_qty, max_qty)
	
	var added = PlayerData.player_inventory_data.add_item(item_data, quantity)
	
	if added:
		print("Đã hái được ", quantity, " ", item_data.name)
		##VFX/SFX
		# spawn_particle()
		
		queue_free()
	else:
		print("Kho đồ đầy!")
