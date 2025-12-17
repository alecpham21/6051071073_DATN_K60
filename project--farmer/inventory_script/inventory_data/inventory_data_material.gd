extends InventoryData
class_name MaterialInventoryData

func refresh(source_inventory: InventoryData = null) -> void:

	var source = source_inventory
	if source == null:
		source = PlayerData.player_inventory_data 
	
	slot_datas.clear()
	
	var filtered_slots: Array[SlotData] = []
	
	for slot in source.slot_datas:
		if slot and slot.item_data:
			if slot.item_data is ItemDataMaterial:
				var mat_item = slot.item_data as ItemDataMaterial
				if mat_item.material_type != ItemDataMaterial.MaterialType.NONE:
					filtered_slots.append(slot)

	filtered_slots.sort_custom(func(a, b):
		var item_a = a.item_data as ItemDataMaterial
		var item_b = b.item_data as ItemDataMaterial
		
		if item_a.material_type != item_b.material_type:
			return item_a.material_type < item_b.material_type
		
		return item_a.name < item_b.name
	)

	slot_datas = filtered_slots
	
	# --- [THÊM ĐOẠN NÀY ĐỂ GIỮ NGUYÊN 16 Ô] ---
	# Nếu số lượng tìm thấy nhỏ hơn 16, nhét thêm ô trống (null) vào cho đủ
	while slot_datas.size() < 16:
		slot_datas.append(null)
	# ------------------------------------------
	
	inventory_updated.emit(self)
