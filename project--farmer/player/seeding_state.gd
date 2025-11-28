extends GardeningState

@onready var inventory_data: InventoryData
@onready var cast: RayCast3D = $"../../SeedCast3D"
@onready var anim: AnimationPlayer = $"../../Farmer/AnimationPlayer"
@onready var ground_gen = get_tree().get_first_node_in_group("ground_generator")

var item_active := true
var last_grid_pos: Vector2i = Vector2i(-1, -1)
var seed:SlotData

func _enter() -> void:
	super()
	seed = HotBar.active_slot
	character.ani.animation_finished.connect(func(a):
		plant_seed(HotBar.active_item.name.strip_edges().to_lower().replace(" ", "_"))
		dispatch("idle")
		, CONNECT_ONE_SHOT)


func plant_seed(seed_name: String) -> void:
	if not is_inside_tree():
		await ready
	cast.force_raycast_update()
	
	if cast.is_colliding():
		var hit_pos = cast.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
		
		# 1. Check xem có click ra ngoài map không để tránh crash
		if not ground_gen.is_valid_grid_pos(grid_pos):
			return

		var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
		# print(hit_pos)
		
		if block.mode != BlockGroundData.Mode.TILLED: # Lưu ý: BlockGroundData (theo class name)
			print("Not tilled yet")
			return
		if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
			print("Already planted")
			return
			
		var plant_variant = PlantDatabase.get_variant_from_seed(seed_name)
		
		# 2. Lấy Scene
		var plant_scene = PlantDatabase.get_plant_scene(plant_variant)
		
		if plant_scene:
			# 3. [FIX LỖI ADD CHILD] Tạo Node từ Scene
			var plant_node = plant_scene.instantiate()
			
			ground_gen.add_child(plant_node)
			
			var world_pos = ground_gen.get_world_pos_from_grid(grid_pos)
			
			# 4. [GIỮ NGUYÊN OFFSET CỦA ÔNG]
			plant_node.global_position = world_pos + Vector3(0, -0.04, 0)
			
			# 5. [FIX LỖI THU HOẠCH] Gán địa chỉ lưới cho cây nhớ
			if "current_grid_pos" in plant_node:
				plant_node.current_grid_pos = grid_pos
			
			# Cập nhật Data đất
			block.plant_type = plant_variant
			block.crop_ready = false
			block.mode = BlockGroundData.Mode.PLANTED
			
			# Trừ item
			var index = PlayerData.player_inventory_data.slot_datas.find(HotBar.active_slot)
			if index != -1:
				PlayerData.player_inventory_data.actual_use_slot_data(index)

func is_holding_seed():
	print("Is Holding Seed")
