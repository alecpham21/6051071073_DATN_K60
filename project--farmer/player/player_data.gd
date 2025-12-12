extends Node

var player:Player
var player_inventory_data: InventoryData
var player_equip_data: InventoryData 
var player_outfit_data: InventoryDataOutfit
var chest_inventories: Dictionary = {}

var next_spawn_position: Vector3
var used_spawn_position: bool = true
var is_transitioning_with_bike: bool = false
var washing_machine_timers: Dictionary = {}


var material_data:InventoryData

func _ready():
	if player_inventory_data == null:
		player_inventory_data = load("res://inventory_script/inventory_data/player_inventory.tres")

	if player_equip_data == null:
		player_equip_data = load("res://inventory_script/inventory_data/player_quick_item.tres")

	if player_outfit_data == null:
		player_outfit_data = load("res://inventory_script/inventory_data/player_outfit.tres")

	material_data = load("res://inventory_script/inventory_data/material_inventory.tres")

func get_global_posotion() -> Vector3:
	return player.global_position

# Call when in tilling or harvesting
func add_dirt_to_outfit(amount: float):
	if not player_outfit_data: return
	
	var is_dirty_updated = false
	
	for slot in player_outfit_data.slot_datas:
		#Only Outfit 
		if slot and slot.item_data is ItemDataOutfit:
			# call add_dirt in SlotData
			slot.add_dirt(amount)
			is_dirty_updated = true
			print("Đã làm dơ: ", slot.item_data.name)
	
	if is_dirty_updated:
		player_outfit_data.inventory_updated.emit(player_outfit_data)
