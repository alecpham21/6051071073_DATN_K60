extends Node3D

@onready var cast: RayCast3D = $"../SeedCast3D"
@onready var player_inventory = $"../../../../PlayerInventory"
@onready var anim: AnimationPlayer = $"../Jordax/AnimationPlayer"
var item_active := true


func plant_seed(seed_name: String) -> void:
	cast.force_raycast_update()
	if cast.is_colliding():
		var hit = cast.get_collider()
		var block = BlockGround.get_block_from_hit(hit)
		print(hit)
		if block and block.mode == BlockGround.Mode.TILLED and block.plant_type == PlantDatabase.PLANT_VARIANT.NONE:
			var slot_index = player_inventory.active_item_slot
			var item_data = player_inventory.inventory[slot_index]
			var inv_seed_name = item_data["item_name"]
			
			var plant_variant = PlantDatabase.get_variant_from_seed(inv_seed_name)
			var plant = PlantDatabase.get_plant_node(plant_variant)

			if plant == null:
				push_error("Plant is NULL, không instance được!")
			else:
				block.add_child(plant)
				plant.position = Vector3(0, 0.2, 0)
				block.plant_type = plant_variant
				print("Planted seed name 🌴:", inv_seed_name)
		else:
			print("Cannot plant here!")
	else:
		print("Raycast miss")
		


func is_holding_seed() -> bool:
	if player_inventory == null:
		return false
	var slot_index = player_inventory.active_item_slot
	var item_data = player_inventory.inventory[slot_index]
	var item_name = item_data["item_name"]
	print("Is Holding Seed")
	print("Active slot:", slot_index, "Item:", item_name)
	return item_name != "null" and item_name.ends_with("_seed")
