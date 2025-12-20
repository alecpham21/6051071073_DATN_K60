extends Node

signal money_changed(new_value: int)

var player: Player
var player_inventory_data: InventoryData
var player_equip_data: InventoryData 
var player_outfit_data: InventoryDataOutfit
var chest_inventories: Dictionary = {}

var next_spawn_position: Vector3
var used_spawn_position: bool = true
var is_transitioning_with_bike: bool = false
var washing_machine_timers: Dictionary = {}

var material_data: MaterialInventoryData 
var craft_bin_data: Array[SlotData] = [null, null, null, null]
var board_data: InventoryData
var money: int = 3000:
	set(value):
		money = value
		money_changed.emit(money)

func _ready():
	if player_inventory_data == null:
		player_inventory_data = load("res://inventory_script/inventory_data/player_inventory.tres")

	if player_equip_data == null:
		player_equip_data = load("res://inventory_script/inventory_data/player_quick_item.tres")

	if player_outfit_data == null:
		player_outfit_data = load("res://inventory_script/inventory_data/player_outfit.tres")

	# Lưu ý: File material_inventory.tres phải có script MaterialInventoryData được gắn vào nó nhé
	material_data = load("res://inventory_script/inventory_data/material_inventory.tres") as MaterialInventoryData
	if board_data == null:
			board_data = InventoryData.new()
			board_data.slot_datas.resize(1) # Thớt chỉ cần 1 ô
			board_data.slot_datas[0] = null


func get_global_posotion() -> Vector3:
	return player.global_position

func add_dirt_to_outfit(amount: float):
	if not player_outfit_data: return
	
	var is_dirty_updated = false
	
	for slot in player_outfit_data.slot_datas:
		if slot and slot.item_data is ItemDataOutfit:
			slot.add_dirt(amount)
			is_dirty_updated = true
			print("Đã làm dơ: ", slot.item_data.name)
	
	if is_dirty_updated:
		player_outfit_data.inventory_updated.emit(player_outfit_data)
