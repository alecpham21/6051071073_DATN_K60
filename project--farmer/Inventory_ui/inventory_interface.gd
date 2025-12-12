extends Control

signal drop_slot_data(slot_data: SlotData)
signal click_slot_data(slot_data: SlotData, inventory: InventoryData, btn:int)
signal force_close

var grabbed_slot_data: SlotData
var external_inventory_owner
var washing_machine_ui: Control
var active_kitchen: Kitchen

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $ExternalInventory
@onready var equip_inventory: PanelContainer = $EquipInventory
@onready var outfit_inventory: PanelContainer = $OutfitInventory
@export var craft_bar: PanelContainer
@export var material_inventory: PanelContainer



func _ready():
	if craft_bar:
		click_slot_data.connect(func(sd:SlotData, inv:InventoryData, btn:int):
			var target_inv: InventoryData = active_kitchen.inventory_data if active_kitchen else null
			
			if target_inv == null: return 

			if inv == PlayerData.material_data && btn == MOUSE_BUTTON_LEFT:
				if sd == null: return
				
				if target_inv.is_full() && !target_inv.has_item(sd.item_data): return
				
				if target_inv.has_item(sd.item_data)\
				&& target_inv.get_slot_from_item(sd.item_data).quantity >= PlayerData.player_inventory_data.get_slot_from_item(sd.item_data).quantity: return
				
				sd = sd.duplicate()
				sd.quantity = 1
				target_inv.pick_up_slot_data(sd)
			
			if inv == target_inv && btn == MOUSE_BUTTON_RIGHT:
				if sd: target_inv.remove_slot(sd)
			)
	washing_machine_ui = get_node_or_null("WashingMachineUI")
	GameData.open_kitchen_interface.connect(set_kitchen_inventory)

	GameData.game_state_changed.connect(func(old, new):
		if new == GState.state_enum.PLAYING:
				close_kitchen()
		)
func _physics_process(delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)
	if external_inventory_owner \
			and external_inventory_owner.global_position.distance_to(PlayerData.get_global_posotion()) > 2:
		force_close.emit()
	
func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func set_equip_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory.set_inventory_data(inventory_data)

func set_outfit_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	outfit_inventory.set_inventory_data(inventory_data)

func set_material_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_click)
	material_inventory.set_inventory_data(inventory_data)

func set_craft_bar_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_click)
	craft_bar.set_inventory_data(inventory_data)

func set_kitchen_inventory(kitchen_node: Kitchen) -> void:
	active_kitchen = kitchen_node
	var inventory_data = kitchen_node.inventory_data
	
	if not inventory_data.inventory_interact.is_connected(on_inventory_click):
		inventory_data.inventory_interact.connect(on_inventory_click)
	
	craft_bar.set_inventory_data(inventory_data)

	player_inventory.visible = false 
	outfit_inventory.visible = false
	equip_inventory.visible = false
	material_inventory.set_inventory_data(PlayerData.material_data)

	self.visible = true
	craft_bar.show()
	material_inventory.show()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_kitchen() -> void:
	if active_kitchen:
		var inventory_data = active_kitchen.inventory_data
		if inventory_data.inventory_interact.is_connected(on_inventory_click):
			inventory_data.inventory_interact.disconnect(on_inventory_click)
		
		craft_bar.clear_inventory_data(inventory_data)
		
		craft_bar.hide()
		material_inventory.hide()
		
		player_inventory.show()
		
		active_kitchen = null
		
		# Tắt UI tổng và khóa chuột lại
		self.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_external_inventory(_external_inventory_owner) -> void:
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	
	if not force_close.is_connected(external_inventory_owner.close_chest):
		force_close.connect(external_inventory_owner.close_chest)
	
	if external_inventory_owner is WashingMachine:
		external_inventory.hide()
		
		if washing_machine_ui: 
			washing_machine_ui.show()
			if washing_machine_ui.has_method("setup_machine_ui"):
				washing_machine_ui.setup_machine_ui(external_inventory_owner)
		else:
			print("Cảnh báo: Đang ở level không có UI Máy Giặt!")
			
	else:
		if washing_machine_ui:
			washing_machine_ui.hide()
			
		external_inventory.show()
		external_inventory.set_inventory_data(inventory_data)


func clear_external_inventory() -> void:
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
		if inventory_data.inventory_interact.is_connected(on_inventory_interact):
			inventory_data.inventory_interact.disconnect(on_inventory_interact)
		
		if force_close.is_connected(external_inventory_owner.close_chest):
			force_close.disconnect(external_inventory_owner.close_chest)
		
		external_inventory.clear_inventory_data(inventory_data)
		external_inventory.hide()
		
		if washing_machine_ui:
			washing_machine_ui.hide()
		
		external_inventory_owner = null
	
func on_inventory_interact(invetory_data: InventoryData, 
		index: int, button: int) -> void:
	
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = invetory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = invetory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			invetory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = invetory_data.drop_single_slot_data(grabbed_slot_data, index)
	update_grabbed_slot()
	
	

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

func on_inventory_click(inventory_data: InventoryData, 
		index: int, button: int) -> void:
	
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			click_slot_data.emit(inventory_data.slot_datas[index], inventory_data, MOUSE_BUTTON_LEFT)
		[null, MOUSE_BUTTON_RIGHT]:
			click_slot_data.emit(inventory_data.slot_datas[index], inventory_data, MOUSE_BUTTON_RIGHT)


func _on_gui_input(event: InputEvent) -> void:
	if not is_inside_tree(): 
		return
	if event is InputEventMouseButton \
			and event.is_pressed() \
			and grabbed_slot_data:
		
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
		update_grabbed_slot()


func _on_visibility_changed() -> void:
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
