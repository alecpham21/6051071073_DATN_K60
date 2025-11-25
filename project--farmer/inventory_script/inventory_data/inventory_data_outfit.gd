extends InventoryData
class_name InventoryDataOutfit

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	if not grabbed_slot_data.item_data is ItemDataOutfit:
		return grabbed_slot_data
	
	var item_outfit = grabbed_slot_data.item_data as ItemDataOutfit
	
	#Check outfit type
	if index == 0 and item_outfit.outfit_type != ItemDataOutfit.OutfitType.HEAD:
		return grabbed_slot_data # Trả lại item, không cho mặc
	if index == 1 and item_outfit.outfit_type != ItemDataOutfit.OutfitType.BODY:
		return grabbed_slot_data
	if index == 2 and item_outfit.outfit_type != ItemDataOutfit.OutfitType.LEGS:
		return grabbed_slot_data

	return super.drop_slot_data(grabbed_slot_data, index)

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	
	if not grabbed_slot_data.item_data is ItemDataOutfit:
		return grabbed_slot_data
	var item_outfit = grabbed_slot_data.item_data as ItemDataOutfit
	
	if index == 0 and item_outfit.outfit_type != ItemDataOutfit.OutfitType.HEAD:
		return grabbed_slot_data
	if index == 1 and item_outfit.outfit_type != ItemDataOutfit.OutfitType.BODY:
		return grabbed_slot_data
	if index == 2 and item_outfit.outfit_type != ItemDataOutfit.OutfitType.LEGS:
		return grabbed_slot_data
	
	return super.drop_single_slot_data(grabbed_slot_data, index)
