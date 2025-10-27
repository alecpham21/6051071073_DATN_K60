extends Resource
class_name Inventory

static var capacity:int = 30
static var slots:Array[Item]

static func slot_swap(idx1:int,idx2:int):
	var temp = slots[idx1]
	slots[idx1] = slots[idx2]
	slots[idx2] = temp

static func inv_init():
	for i in capacity:
		slots.append(Item.new("none"))
	HotBar.select_hand(0)

static func add_item(_item:Item):
	slots[slots.find_custom(func(x): return x.item_name == "none")] = _item
