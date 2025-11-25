extends InventoryData
class_name HotBar

static var active_item:ItemData
static var active_slot:SlotData

static func select_item(_slot:SlotData):
	if _slot == null || _slot == active_slot:
		active_item = null
		active_slot = null
		return
	active_slot = _slot
	active_item = _slot.item_data

static func hand() -> bool:
	return active_item == null
