extends Resource
class_name SlotData

const MAX_TAC_SIZE: int = 99.0

@export var item_data: ItemData
@export_range(1, MAX_TAC_SIZE) var quantity: int = 1:
	set = set_quantity
@export var current_dirt_level: float = 0.0

func is_dirty() -> bool:
	return current_dirt_level > 0

func clean_slot() -> void:
	current_dirt_level = 0.0
	

func add_dirt(amount: float) -> void:
	# Cần lấy max_dirt từ item_data gốc
	var max_d = 100.0
	if item_data is ItemDataOutfit:
		max_d = item_data.max_dirt_level
		
	current_dirt_level = clamp(current_dirt_level + amount, 0, max_d)

func can_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data \
			and item_data.stackable \
			and quantity < MAX_TAC_SIZE

func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data \
			and item_data.stackable \
			and quantity + other_slot_data.quantity <= MAX_TAC_SIZE
func fully_merge_with(other_slot_data: SlotData) -> void:
	quantity += other_slot_data.quantity

func create_single_slot_data() -> SlotData:
	var new_slot_data = duplicate()
	new_slot_data.quantity = 1
	new_slot_data.current_dirt_level = current_dirt_level
	quantity -= 1
	return new_slot_data

func set_quantity(value: int) -> void:
	quantity = value
	if quantity > 1 and not item_data.stackable:
		quantity > 1
		push_error("%s is not stackable, setting quantity to 1" % item_data.name)
