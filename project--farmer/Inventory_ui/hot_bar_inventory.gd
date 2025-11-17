extends PanelContainer

signal hot_bar_use(index: int)
signal active_slot_changed(slot_data: SlotData)

const Slot = preload("res://Inventory_ui/slot.tscn")

@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer

var active_index: int = 0
var current_inventory_data: InventoryData

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	
	if range(KEY_1, KEY_7).has(event.keycode):
		var index_pressed = event.keycode - KEY_1
		hot_bar_use.emit(index_pressed)
		set_active_slot(index_pressed)

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)
	set_active_slot(0)
	

func populate_hot_bar(inventory_data: InventoryData) -> void:
	var children = h_box_container.get_children()
	for i in range(children.size() - 1, -1, -1): 
		var child = children[i]
		h_box_container.remove_child(child) 
		child.free() 
		
	var i = 0 
	for slot_data in inventory_data.slot_datas.slice(0, 7):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		# CODE MỚI: Kết nối signal "slot_clicked" từ Slot.tscn
		slot.slot_clicked.connect(on_slot_clicked.bind(i))
		
		if slot_data:
			slot.set_slot_data(slot_data)
		
		i += 1 
	
	update_active_slot_visuals()
	
func on_slot_clicked(index: int, button: int):
	if button == MOUSE_BUTTON_LEFT:
		set_active_slot(index)

# HÀM MỚI: Thay đổi active slot
func set_active_slot(index: int):
	active_index = index
	update_active_slot_visuals()
	
	if current_inventory_data:
		var active_slot_data = current_inventory_data.slot_datas[active_index]
		active_slot_changed.emit(active_slot_data)

func update_active_slot_visuals():
	if not h_box_container: # Đảm bảo h_box_container đã sẵn sàng
		return
		
	var i = 0
	for slot in h_box_container.get_children():
		var selected_visual = slot.get_node_or_null("MarginContainer/Selected")
		if selected_visual:
			selected_visual.visible = (i == active_index)
		i += 1


func get_active_item() -> SlotData:
	if current_inventory_data:
		return current_inventory_data.slot_datas[active_index]
	return null
