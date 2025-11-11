extends Node3D

@onready var inventory_data: InventoryData

@onready var cast: RayCast3D = $"../SeedCast3D"
@onready var player_inventory = get_node("/root/World/PlayerInventory")
@onready var anim: AnimationPlayer = $"../Farmer/AnimationPlayer"
@onready var ground_gen = get_tree().get_first_node_in_group("ground_generator")

var item_active := true
var last_grid_pos: Vector2i = Vector2i(-1, -1)

func plant_seed(seed_name: String) -> void:
	if not is_inside_tree():
		await ready
	cast.force_raycast_update()
	if cast.is_colliding():
		var hit_pos = cast.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
		var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
		print(hit_pos)
		
		if block.mode != BlockGround.Mode.TILLED:
			print("Not tilled yet")
			return
		if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
			print("Already planted")
			return
			
		## Active slot
		#var slot_index = Inventory.slots.find(HotBar.active_item)
		
		
		var plant_variant = PlantDatabase.get_variant_from_seed(seed_name)
		var plant= PlantDatabase.get_plant_node(plant_variant)
		
		ground_gen.add_child(plant)
		
		var world_pos = ground_gen.get_world_pos_from_grid(grid_pos)
		plant.global_position = world_pos + Vector3(0, -0.04, 0)
		
		
		
		block.plant_type = plant_variant
		block.crop_ready = false
		block.mode = BlockGroundData.Mode.PLANTED


func is_holding_seed():
	#if player_inventory == null:
		#return false
	print("Is Holding Seed")
