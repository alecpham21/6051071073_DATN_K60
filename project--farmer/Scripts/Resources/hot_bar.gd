extends Inventory
class_name HotBar

static var hand:int = 9
static var active_item:Item

static func select_hand(idx:int):
	if idx > hand: return
	active_item = slots[idx]

static func active_idx() -> int:
	return slots.find(active_item)
