extends Resource
class_name InventoryData

signal inventory_updated(inventory_data: InventoryData)
signal inventory_interact(invetory_data: InventoryData, index: int, button: int)
signal item_used_up()


@export var slot_datas: Array[SlotData]

var is_locked: bool = false

func grab_slot_data(index: int) -> SlotData:
	
	if is_locked:
		print("Inventory is locked!")
		return null
	
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null
	

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	var return_slot_data: SlotData
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	else:
		slot_datas[index] = grabbed_slot_data
		return_slot_data = slot_data
		
	inventory_updated.emit(self)
	return return_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data())
		
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null
	
	

func use_slot_data(index: int) -> void:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		return
	
	if slot_data.item_data is ItemDataConsumable:
		if PlayerData.player:
			slot_data.item_data.use(PlayerData.player)

		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			slot_datas[index] = null
	
	print(slot_data.item_data.name)
	
	inventory_updated.emit(self)

func actual_use_slot_data(index: int) -> void:
	
	var slot_data = slot_datas[index]
	
	if not slot_data:
		return
		
	if slot_data.item_data is ItemDataUsable :
		print("i am using drug")
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			print("no more drug")
			slot_datas[index] = null
			item_used_up.emit()
	
			
	inventory_updated.emit(self)

func pick_up_slot_data(slot_data: SlotData) -> bool:
	for index in slot_datas.size():
		if slot_datas[index] and slot_datas[index].can_fully_merge_with(slot_data):
			slot_datas[index].fully_merge_with(slot_data)
			inventory_updated.emit(self)
			SignalBus.item_added_to_inventory.emit(slot_data.item_data.name, slot_data.quantity)
			return true
	
	for index in slot_datas.size():
		if not slot_datas[index]:
			slot_datas[index] = slot_data
			inventory_updated.emit(self)
			SignalBus.item_added_to_inventory.emit(slot_data.item_data.name, slot_data.quantity)
			return true
	return false

func get_total_item_count(target_item: ItemData) -> int:
	var total: int = 0
	for slot in slot_datas:
		if slot and slot.item_data == target_item:
			total += slot.quantity
	return total

func remove_items_by_data(target_item: ItemData, amount_to_remove: int) -> bool:
	if get_total_item_count(target_item) < amount_to_remove:
		return false
	
	var remaining_needed = amount_to_remove
	
	for i in range(slot_datas.size()):
		var slot = slot_datas[i]
		if slot and slot.item_data == target_item:
			if slot.quantity > remaining_needed:
				slot.quantity -= remaining_needed
				remaining_needed = 0
			else:
				remaining_needed -= slot.quantity
				slot_datas[i] = null
		
		if remaining_needed == 0:
			break
			
	inventory_updated.emit(self)
	return true


func on_slot_clicked(index: int, button: int) -> void:
	inventory_interact.emit(self, index, button)

func inventory_cache(idx:int):
	if slot_datas[idx] && slot_datas[idx].quantity <= 0: slot_datas[idx] = null
	inventory_updated.emit(self)

func add_item(item: ItemData, quantity: int) -> bool:
	var new_slot_data = SlotData.new()
	new_slot_data.item_data = item
	new_slot_data.quantity = quantity
	
	return pick_up_slot_data(new_slot_data)

func has_item(_item:ItemData) -> bool:
	return slot_datas.filter(func(x): return x!=null).map(func(x:SlotData): return x.item_data).has(_item)

func get_slot_from_item(_item:ItemData) -> SlotData:
	if !has_item(_item): return null
	return slot_datas.filter(func(x:SlotData): return x!=null && x.item_data == _item)[0]

func contains(_inv:InventoryData) -> bool:
	for i:SlotData in _inv.slot_datas.filter(func(x:SlotData): return x!=null):
		if !has_item(i.item_data): return false
		if get_slot_from_item(i.item_data).quantity < i.quantity: return false
	return true

func clear():
	var _size = slot_datas.size()
	slot_datas.clear()
	slot_datas.resize(_size)
	inventory_updated.emit(self)

func is_full():
	return slot_datas.filter(func(x): return x == null).is_empty()

func remove_slot(sd:SlotData):
	if !has_item(sd.item_data): return
	slot_datas[slot_datas.find(sd)] = null
	inventory_updated.emit(self)

func reduce_quantity(_item: ItemData, ammount: int = 1):
	if !has_item(_item): return
	
	var sd = get_slot_from_item(_item)
	sd.quantity -= ammount
	
	if sd.quantity < 1:
		var index = slot_datas.find(sd)
		if index != -1:
			slot_datas[index] = null
			
	inventory_updated.emit(self)

func refresh():
	inventory_updated.emit(self)

func add_item_at_index(item: ItemData, quantity: int, index: int) -> bool:
	if index < 0 or index >= slot_datas.size():
		return false
	
	var slot = slot_datas[index]
	if not slot:
		var new_slot = SlotData.new()
		new_slot.item_data = item
		new_slot.quantity = quantity
		slot_datas[index] = new_slot
	elif slot.item_data == item:
		if slot.quantity + quantity <= 99:
			slot.quantity += quantity
		else:
			return false
	else:
		return false
		
	inventory_updated.emit(self)
	return true

func grab_split_items(index: int, grabbed_slot_data: SlotData) -> SlotData:
	var slot_data = slot_datas[index]
	
	if not slot_data: 
		return grabbed_slot_data
	
	if not grabbed_slot_data:
		grabbed_slot_data = slot_data.create_single_slot_data()
		
		if slot_data.quantity < 1:
			slot_datas[index] = null
			
		inventory_updated.emit(self)
		return grabbed_slot_data
	
	if grabbed_slot_data.can_merge_with(slot_data):
		var single_slice = slot_data.create_single_slot_data()
		grabbed_slot_data.fully_merge_with(single_slice)
		
		if slot_data.quantity < 1:
			slot_datas[index] = null
			
		inventory_updated.emit(self)
	
	return grabbed_slot_data


func get_save_data() -> Array:
	var data = []
	for slot in slot_datas:
		if slot and slot.item_data:
			data.append({
				"item_path": slot.item_data.resource_path,
				"quantity": slot.quantity
			})
		else:
			data.append(null)
	return data

func load_save_data(data: Array):
	if data.size() != slot_datas.size():
		slot_datas.resize(data.size())
		
	for i in range(data.size()):
		var slot_info = data[i]
		if slot_info:
			var item_res = load(slot_info.item_path)
			if item_res:
				var new_slot = SlotData.new()
				new_slot.item_data = item_res
				new_slot.quantity = slot_info.quantity
				slot_datas[i] = new_slot
		else:
			slot_datas[i] = null
			
	inventory_updated.emit(self)
