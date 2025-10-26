extends Node

@onready var cast: RayCast3D = $"../../../../../HoeCast3D"
@onready var player_inventory = get_node("/root/World/PlayerInventory")
var item_active := true

var last_highlighted_block: BlockGround = null

func _process(delta: float) -> void:
	cast.force_raycast_update()
	
	if cast.is_colliding():
		var hit = cast.get_collider()
		var block = BlockGround.get_block_from_hit(hit)
		##HightLight Box
		if block:
			if last_highlighted_block and last_highlighted_block != block:
				last_highlighted_block.set_highlighted(false)
			
			block.set_highlighted(true)
			last_highlighted_block = block
		else:
			_clear_highlight()
	else:
		_clear_highlight()


func _clear_highlight() -> void:
	if last_highlighted_block:
		last_highlighted_block.set_highlighted(false)
		last_highlighted_block = null

func is_holding_sickle() ->bool:
	if player_inventory == null:
		return false
	var slot_index = player_inventory.active_item_slot
	var item_data = player_inventory.inventory[slot_index]
	var item_name = item_data["item_name"]
	print("Active slot:", slot_index, "Item:", item_name)
	return item_name == "sickle"

func swing_sickle() -> void:
	cast.force_raycast_update()
	if not cast.is_colliding():
		print("Raycast miss")
		return

	var hit = cast.get_collider()
	var block = BlockGround.get_block_from_hit(hit)

	if not block:
		print("No valid block to hit")
		return

	# Nếu có cây thu hoạch được
	if block.crop_ready and block.has_method("harvest_plant"):
		block.harvest_plant()
		return

	# Nếu block là GRASS hoặc có windgrass thì cắt
	if block.mode == BlockGround.Mode.GRASS or (block.wind_grass_node and block.wind_grass_node.visible):
		block.cut_grass()
		if block.wind_grass_node:
			block.wind_grass_node.visible = false
			block.current_windgrass = max(0, block.current_windgrass - 1)
		print("Cut grass or windgrass at:", block.name)
		return

	print("No valid target to swing at")
