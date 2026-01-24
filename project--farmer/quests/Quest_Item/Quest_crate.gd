extends Node3D
class_name ContractCrate

signal dropped

@onready var static_body = $StaticBody3D
@onready var interact_area = $InteractArea

@export var inventory_data: InventoryData
@export var visual_map: Dictionary = {} 
@export var max_capacity: int = 20

var allowed_item: ItemData = null
var is_being_carried: bool = false
var last_stable_pos: Vector3
var last_stable_rot: Vector3


func _ready():
	add_to_group("crates")
	
	last_stable_pos = global_position
	last_stable_rot = global_rotation
	
	if inventory_data:
		inventory_data = inventory_data.duplicate()
		inventory_data.inventory_updated.connect(_on_inventory_updated)
	
	_hide_all_meshes()
			
	if interact_area:
		interact_area.interacted.connect(_on_interact)

func _on_interact():
	if is_being_carried: return
	if QuestManager.active_contract_item != null:
		self.allowed_item = QuestManager.active_contract_item
	
	if SignalBus.has_signal("inventory_opened"):
		SignalBus.inventory_opened.emit(self)
	GState.ui()

func is_full() -> bool:
	var slot = inventory_data.slot_datas[0] if inventory_data.slot_datas.size() > 0 else null
	return slot != null and slot.quantity >= max_capacity

func _on_inventory_updated(inv: InventoryData):
	var slot = inv.slot_datas[0] if inv.slot_datas.size() > 0 else null
	
	_hide_all_meshes()
	
	if slot and is_instance_valid(slot.item_data):
		var item_name_key = slot.item_data.name.strip_edges().to_lower()
		print("Visual Update: Detected [", item_name_key, "] x", slot.quantity)
		
		var mesh_node = find_child(item_name_key.capitalize(), true, false)
		
		if is_instance_valid(mesh_node) and mesh_node is Node3D:
			mesh_node.visible = true
			print("Visual Success: Mesh [", mesh_node.name, "] is now VISIBLE")
			
			if mesh_node.get_parent() is Node3D:
				mesh_node.get_parent().visible = true
		else:
			print("Visual Error: Cannot find mesh node named [", item_name_key.capitalize(), "] in scene!")

func _hide_all_meshes():
	var frujt = find_child("Frujt", true, false)
	if frujt:
		for child in frujt.get_children():
			if child is Node3D:
				child.visible = false

func try_add_item(item_data: ItemData, quantity: int) -> bool:
	if not can_accept_item(item_data): return false
	var slot = inventory_data.slot_datas[0]
	var current_qty = slot.quantity if slot and slot.item_data else 0
	var space_left = max_capacity - current_qty
	if space_left <= 0: return false
	return inventory_data.add_item(item_data, min(quantity, space_left))

func can_accept_item(item_data: ItemData) -> bool:
	if not is_instance_valid(item_data) or not item_data is ItemDataMaterial: return false
	if item_data.material_type != ItemDataMaterial.MaterialType.RAW_MATERIAL: return false
	var s_type = item_data.selling_type
	if not (s_type == ItemDataMaterial.SellingType.FRUJT or s_type == ItemDataMaterial.SellingType.VEGETABLE): return false
	if is_instance_valid(allowed_item) and item_data.name != allowed_item.name: return false
	return true

func set_carried(is_carried: bool):
	is_being_carried = is_carried
	
	if is_instance_valid(static_body):
		static_body.get_node("CollisionShape3D").disabled = is_carried
		
	if is_instance_valid(interact_area):
		interact_area.monitorable = true
		interact_area.monitoring = !is_carried
	
	if not is_carried:
		last_stable_pos = global_position
		last_stable_rot = global_rotation
		dropped.emit()
		print("[DEBUG] Crate: Dropped signal emitted once.")

func close_chest():
	GState.play()


func get_save_data() -> Dictionary:
	return {
		"pos": var_to_str(global_position),
		"rot": var_to_str(global_rotation),
		"scale": var_to_str(scale),
		"inv": inventory_data.get_save_data()
	}

func load_save_data(data: Dictionary):
		if data.has("scale"):
			scale = str_to_var(data.scale)
			
		global_position = str_to_var(data.pos)
		global_rotation = str_to_var(data.rot)
		
		if data.has("inv"):
			inventory_data.load_save_data(data.inv)
