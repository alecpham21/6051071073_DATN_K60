extends Node

var player_inventory_data: InventoryData
var player_equip_data: InventoryData 
var player_outfit_data: InventoryDataOutfit

var next_spawn_position: Vector3
var used_spawn_position: bool = true

func _ready():
	if player_inventory_data == null:
		player_inventory_data = load("res://inventory_script/inventory_data/player_inventory.tres") 

	if player_equip_data == null:
		player_equip_data = load("res://inventory_script/inventory_data/player_quick_item.tres") 

	if player_outfit_data == null:
		player_outfit_data = load("res://inventory_script/inventory_data/player_outfit.tres")
