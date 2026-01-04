extends PanelContainer

signal hot_bar_use(index: int)
signal active_slot_changed(slot_data: SlotData)
signal hot_bar_action(index: int)

const Slot = preload("res://Inventory_ui/slot.tscn")

@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer

var active_index: int = 0
var current_inventory_data: InventoryData
var active_tool:Array[Node3D] = []
var is_locked: bool = false


func _ready() -> void:
	add_to_group("hotbar_ui")
	
	GameData.game_state_changed.connect(func(old, new):
		match new:
			GState.state_enum.SHOP:
				visible = false
				set_locked(true)
			
			GState.state_enum.DIALOG:
				visible = false
				set_locked(true)
			
			GState.state_enum.UI, GState.state_enum.COOK, GState.state_enum.RECIPE:
				visible = true
				set_locked(true)
				
			GState.state_enum.PLAYING:
				visible = true
				set_locked(false)
	)
	
	active_slot_changed.connect(func(_slot:SlotData):
		tool_cache()
		if _slot && _slot.item_data is ItemDataTool:
			var tool:Node3D = _slot.item_data.equip_scene.instantiate()
			match(_slot.item_data.name.to_lower()):
				"hoe": PlayerData.player.hoe.add_child(tool)
				"sickle":
					PlayerData.player.sickle.add_child(tool)
					tool.scale *= 0.3
				"watering can":
					PlayerData.player.watering.add_child(tool)
			active_tool.append(tool)
	)
	
	if PlayerData.player_inventory_data:
		PlayerData.player_inventory_data.inventory_updated.connect(populate_hot_bar)

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_inside_tree(): 
		return
	if is_locked:
		return
	if not visible or not event.is_pressed():
		return
	
	if event.is_action_pressed("use_item"):
		hot_bar_action.emit(active_index)
	
	if range(KEY_1, KEY_7).has(event.keycode):
		var index_pressed = event.keycode - KEY_1
		if index_pressed == active_index:
			index_pressed = -1
		active_index = index_pressed
		HotBar.select_item(PlayerData.player_inventory_data.slot_datas[index_pressed])
		hot_bar_use.emit(index_pressed)
		active_slot_changed.emit(PlayerData.player_inventory_data.slot_datas[index_pressed])
		set_active_slot(index_pressed)

func set_inventory_data(inventory_data: InventoryData) -> void:
	if not inventory_data.inventory_updated.is_connected(populate_hot_bar):
		inventory_data.inventory_updated.connect(populate_hot_bar)
		
	populate_hot_bar(inventory_data)
	
	if not hot_bar_use.is_connected(inventory_data.use_slot_data):
		hot_bar_use.connect(inventory_data.use_slot_data)
		
	set_active_slot(0)
	

func populate_hot_bar(inventory_data: InventoryData) -> void:
	var children = h_box_container.get_children()
	for i in range(children.size() - 1, -1, -1): 
		var child = children[i]
		h_box_container.remove_child(child) 
		child.free() 
		
	var i = 0 
	for slot_data in inventory_data.slot_datas.slice(0, 6):
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

func tool_cache():
	for i:Node3D in active_tool:
		i.queue_free()
		active_tool.erase(i)

func set_locked(state: bool) -> void:
	is_locked = state
	
	if is_locked:
		modulate.a = 0.5 
		
		tool_cache() 
		active_tool.clear()
	else:
		# Trả lại độ sáng bình thường
		modulate.a = 1.0
		
