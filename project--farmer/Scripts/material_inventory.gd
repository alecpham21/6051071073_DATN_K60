extends PanelContainer

const Slot = preload("res://Inventory_ui/slot.tscn")

@onready var item_grid: GridContainer = $MarginContainer/ItemGrid

var current_filter_func: Callable = func(item_data): return true 
var current_click_action: Callable = Callable() 

func _ready() -> void:
	pass

func setup_custom_mode(filter: Callable, action: Callable):
	current_filter_func = filter
	current_click_action = action

func reset_to_default_mode():
	current_filter_func = func(item_data): return true
	current_click_action = Callable()

func set_inventory_data(inventory_data: InventoryData) -> void:
	if not inventory_data.inventory_updated.is_connected(populate_item_grid):
		inventory_data.inventory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)

func clear_inventory_data(inventory_data: InventoryData) -> void:
	if inventory_data.inventory_updated.is_connected(populate_item_grid):
		inventory_data.inventory_updated.disconnect(populate_item_grid)

func populate_item_grid(inventory_data: InventoryData) -> void:
	for child in item_grid.get_children():
		child.queue_free()
		
	for slot_data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)


		if not slot_data or not slot_data.item_data:
			slot.set_slot_data(null)
			continue

		var passes_filter = true
		if current_filter_func.is_valid():
			passes_filter = current_filter_func.call(slot_data.item_data)
			
		if not passes_filter:
			slot.set_slot_data(null)
			continue 

		var player_has_item = PlayerData.player_inventory_data.has_item(slot_data.item_data)
		
		if player_has_item:
			slot.modulate.a = 1.0
			
			var player_slot = PlayerData.player_inventory_data.get_slot_from_item(slot_data.item_data)
			slot_data.quantity = player_slot.quantity
			
			# Connect Click
			if current_click_action.is_valid():
				slot.slot_clicked.connect(func(_arg=null): current_click_action.call(slot_data))
			else:
				slot.slot_clicked.connect(inventory_data.on_slot_clicked)
				
		else:
			# --- KHÔNG CÓ ĐỒ ---
			slot.modulate.a = 0.5 # Tối (Dim)
			slot_data.quantity = 0 # Hoặc giữ số lượng yêu cầu tùy bạn
			
			# KHÔNG connect click -> Không bấm được
			# (Lưu ý: Không set null ở đây, vẫn hiện hình item để biết là thiếu cái gì)

		# Update giao diện Slot
		slot_data.locked = true
		slot.set_slot_data(slot_data)
