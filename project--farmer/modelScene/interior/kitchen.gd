extends Node3D
class_name Kitchen


@export var inventory_data: InventoryData


@export var board_input_inv: InventoryData 

@onready var stove_area: Area3D = $StoveArea
@onready var board_area: Area3D = $BoardArea

func _ready() -> void:
	if inventory_data == null:
		inventory_data = load("res://inventory_script/inventory_data/craft_bar_inventory.tres").duplicate()
	
	board_input_inv = InventoryData.new()
	board_input_inv.slot_datas = [null]


	if stove_area:
		stove_area.interacted.connect(on_interact_stove)
	if board_area:
		board_area.interacted.connect(on_interact_board)

func on_interact_stove():
	GameData.open_kitchen_interface.emit(self, "stove") 
	GState.cook()

func on_interact_board():
	GameData.open_kitchen_interface.emit(self, "board")
	GState.cook()
