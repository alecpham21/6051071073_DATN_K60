extends Control

signal drop_slot_data(slot_data: SlotData)
signal force_close

var grabbed_slot_data: SlotData
var external_inventory_owner
var washing_machine_ui: Control

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $ExternalInventory
@onready var equip_inventory: PanelContainer = $EquipInventory
@onready var outfit_inventory: PanelContainer = $OutfitInventory


func _ready():
	washing_machine_ui = get_node_or_null("WashingMachineUI")

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
