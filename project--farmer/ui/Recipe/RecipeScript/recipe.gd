extends InventoryData
class_name Recipe

enum STATION { STOVE, BOARD }

@export var station: STATION = STATION.STOVE
@export var cook_result: SlotData
@export var other_conditions: Array[StringName]
@export var craft_time: float = 1.5

func can_cook(kitchen_inv: InventoryData) -> bool:
	if not GState.is_cook(): return false

	var has_tools = contains_arr(GameData.interact_cargo.map(func(x): return x != null || x is String || x is StringName), other_conditions)
	if not has_tools: return false
	
	if kitchen_inv:
		for required_slot in slot_datas:
			if required_slot and required_slot.item_data:
				var item_in_kitchen = kitchen_inv.get_slot_from_item(required_slot.item_data)
				
				if not item_in_kitchen or item_in_kitchen.quantity < required_slot.quantity:
					return false
		
		return true
		
	return false

func contains_arr(big_arr: Array, small_arr: Array) -> bool:
	for i in small_arr:
		if !big_arr.has(i): return false
	return true
