extends Node

signal money_changed(new_value: int)

var player: Player
var stats: CharacterStats
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
	
	if stats == null:
		stats = load("res://player/Basic_stats.tres").duplicate()
	if player_inventory_data == null:
		player_inventory_data = load("res://inventory_script/inventory_data/player_inventory.tres")

	if player_equip_data == null:
		player_equip_data = load("res://inventory_script/inventory_data/player_quick_item.tres")

	if player_outfit_data == null:
		player_outfit_data = load("res://inventory_script/inventory_data/player_outfit.tres")

	material_data = load("res://inventory_script/inventory_data/material_inventory.tres") as MaterialInventoryData
	if board_data == null:
			board_data = InventoryData.new()
			board_data.slot_datas.resize(1)
			board_data.slot_datas[0] = null
	
	if QuestManager.has_signal("reward_distributed"):
		QuestManager.reward_distributed.connect(_on_reward_received)


func get_global_posotion() -> Vector3:
	return player.global_position

func add_dirt_to_outfit(amount: float):
	if not player_outfit_data: return
	
	var is_dirty_updated = false
	
	for slot in player_outfit_data.slot_datas:
		if slot and slot.item_data is ItemDataOutfit:
			slot.add_dirt(amount)
			is_dirty_updated = true
			print("Dirty make: ", slot.item_data.name)
	
	if is_dirty_updated:
		player_outfit_data.inventory_updated.emit(player_outfit_data)

func get_total_dirt_level() -> float:
	var total_dirt: float = 0.0
	
	if not player_outfit_data: 
		return 0.0
	
	for slot in player_outfit_data.slot_datas:
		if slot and slot.item_data is ItemDataOutfit:
			total_dirt += slot.get_stat("dirt")
			
	return total_dirt

func is_player_stinky(threshold: float = 50.0) -> bool:
	return get_total_dirt_level() >= threshold

func _on_reward_received(type: String, data: Variant, amount: int):
	match type:
		"GOLD":
			money += amount
			print("💰 PlayerData: Added ", amount, " Gold")
			
		"XP":
			# stats.experience += amount
			print("✨ PlayerData: Added ", amount, " XP")
			
		"ITEM":
			if data is ItemData:
				# 1. Thử nhét vào túi trước
				var success = player_inventory_data.add_item(data, amount)
				
				if success:
					print("🎒 PlayerData: Added ", amount, " ", data.name)
				else:
					# 2. TÚI ĐẦY -> GỌI HÀM RỚT ĐỒ
					print("⚠️ Inventory Full! Dropping ", data.name, " on ground.")
					_trigger_drop_item(data, amount)

func _trigger_drop_item(item_data: ItemData, amount: int):
	
	if SignalBus.has_signal("item_dropped"):
		var drop_pos = player.global_position + Vector3(0, 1.0, 0)
		
		SignalBus.item_dropped.emit(item_data, amount, drop_pos)
		
	elif player.has_method("drop_item"):
		player.drop_item(item_data, amount)
		
	else:
		print("❌ Error: Cannot find 'item_dropped' signal or 'drop_item' method!")

func _on_reward_received_backup_fix(_v = null):
	pass
