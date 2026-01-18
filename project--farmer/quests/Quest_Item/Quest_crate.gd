extends Node3D
class_name ContractCrate

signal toggle_inventory(external_inventory_owner)
signal dropped

@onready var static_body = $StaticBody3D
@onready var interact_area = $InteractArea

@export var inventory_data: InventoryData
@export var visual_map: Dictionary = {} 

var allowed_item: ItemData = null
var is_being_carried: bool = false

func _ready():
	if inventory_data:
		inventory_data = inventory_data.duplicate()
		inventory_data.inventory_updated.connect(_on_inventory_updated)
	
	for key in visual_map.keys():
		var val = visual_map[key]
		if val is NodePath:
			visual_map[key] = get_node(val)
		
		if visual_map[key] is Node3D:
			visual_map[key].visible = false
	if interact_area:
		interact_area.interacted.connect(_on_interact)
func _on_interact():
	if is_being_carried: return

	if QuestManager.active_contract_item != null:
		self.allowed_item = QuestManager.active_contract_item
	
	if SignalBus.has_signal("inventory_opened"):
		SignalBus.inventory_opened.emit(self)
	
	GState.ui()

func open_crate_inventory():
	_on_interact()

func can_accept_item(item_data: ItemData) -> bool:
	if not is_instance_valid(item_data) or not item_data is ItemDataMaterial:
		return false
	
	if item_data.material_type != ItemDataMaterial.MaterialType.RAW_MATERIAL:
		return false
	
	var valid_type = (item_data.selling_type == ItemDataMaterial.SellingType.FRUJT or \
					  item_data.selling_type == ItemDataMaterial.SellingType.VEGETABLE)
	if not valid_type:
		return false
	
	if is_instance_valid(allowed_item):
		if item_data != allowed_item:
			return false
			
	return true

func try_add_item(item_data: ItemData, quantity: int) -> bool:
	if not can_accept_item(item_data):
		return false
	
	var current_qty = 0
	var slot = inventory_data.slot_datas[0]
	if slot and slot.item_data:
		current_qty = slot.quantity
	
	var needed = QuestManager.contract_amount_needed - current_qty
	if needed <= 0:
		print("Crate: Đã đủ số lượng yêu cầu!")
		return false
	
	var amount_to_take = min(quantity, needed)
	
	print("Crate: Quest cần ", needed, " | Chỉ lấy ", amount_to_take)
	
	return inventory_data.add_item(item_data, amount_to_take)

func _on_inventory_updated(inv: InventoryData):
	var slot = inv.slot_datas[0] if inv.slot_datas.size() > 0 else null
	
	if slot and is_instance_valid(slot.item_data):
		if QuestManager.has_method("update_contract_progress"):
			QuestManager.update_contract_progress(slot.item_data.name, slot.quantity)
		
		var item_name = slot.item_data.name
		for key in visual_map:
			var mesh = visual_map[key]
			if is_instance_valid(mesh) and mesh is Node3D:
				mesh.visible = (key == item_name)
	else:
		if QuestManager.has_method("update_contract_progress") and is_instance_valid(allowed_item):
			QuestManager.update_contract_progress(allowed_item.name, 0)
			
		for key in visual_map:
			var mesh = visual_map[key]
			if is_instance_valid(mesh) and mesh is Node3D:
				mesh.visible = false



func set_carried(is_carried: bool):
	is_being_carried = is_carried
	
	if is_instance_valid(static_body):
		static_body.get_node("CollisionShape3D").disabled = is_carried
	
	if is_instance_valid(interact_area):
		interact_area.monitorable = true 
		interact_area.monitoring = !is_carried
	
	if not is_carried:
		dropped.emit()


func close_chest():
	print("Crate UI closed")
