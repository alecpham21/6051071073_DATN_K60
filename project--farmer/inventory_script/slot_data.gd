extends Resource
class_name SlotData

const MAX_TAC_SIZE: int = 99.0

@export var item_data: ItemData
@export_range(1, MAX_TAC_SIZE) var quantity: int = 1:
	set = set_quantity
@export var attributes: Array[ItemAttribute] = []
var locked:bool = false

func get_stat(id: String) -> float:
	for attr in attributes:
		if attr.id == id:
			return attr.value
	return 0.0 # Không tìm thấy trả về 0

func set_stat(id: String, new_value: float) -> void:
	# 1. Tìm xem có chưa, có thì sửa
	for attr in attributes:
		if attr.id == id:
			attr.value = new_value
			return
	
	# 2. Chưa có thì tạo mới
	var new_attr = ItemAttribute.new()
	new_attr.id = id
	new_attr.value = new_value
	attributes.append(new_attr)


func is_dirty() -> bool:
	return get_stat("dirt") > 0.0

func clean_slot() -> void:
	set_stat("dirt", 0.0)

func add_dirt(amount: float) -> void:
	if item_data is ItemDataOutfit:
		var current = get_stat("dirt")
		var max_d = item_data.max_dirt_level 
		set_stat("dirt", clamp(current + amount, 0, max_d))

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

	new_slot_data.attributes = []
	for attr in attributes:
		var new_attr = ItemAttribute.new()
		new_attr.id = attr.id
		new_attr.value = attr.value
		new_slot_data.attributes.append(new_attr)
		
	quantity -= 1
	return new_slot_data

func set_quantity(value: int) -> void:
	quantity = value
	if quantity > 1 and not item_data.stackable:
		quantity > 1
		push_error("%s is not stackable, setting quantity to 1" % item_data.name)
