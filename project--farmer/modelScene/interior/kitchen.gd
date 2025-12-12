extends Node3D
class_name Kitchen

@export var inventory_data: InventoryData

func _ready() -> void:
	# Load data riêng cho bếp
	if inventory_data == null:
		inventory_data = load("res://inventory_script/inventory_data/craft_bar_inventory.tres").duplicate()
	
	$InteractArea.interacted.connect(on_interact)

func on_interact():
	GameData.open_kitchen_interface.emit(self) 
	GState.cook()
