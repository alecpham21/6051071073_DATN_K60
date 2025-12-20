extends InventoryData
class_name ShopInventoryData

# Loại hàng chấp nhận
var accepted_type: ItemDataMaterial.SellingType = ItemDataMaterial.SellingType.GENERIC

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	if grabbed_slot_data.item_data is ItemDataMaterial:
		if grabbed_slot_data.item_data.selling_type != accepted_type:
			print("Shop này không mua loại này! Chỉ mua: ", accepted_type)
			return grabbed_slot_data
	else:
		print("Shop không mua vật phẩm này!")
		return grabbed_slot_data
	
	# Nếu đúng loại -> Cho phép thả vào
	return super.drop_slot_data(grabbed_slot_data, index)
