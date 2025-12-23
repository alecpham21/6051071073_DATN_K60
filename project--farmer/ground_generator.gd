extends Node3D
class_name GroundGenerator

@onready var renderer: GroundRenderer = $GroundRenderer
@export var ground_extents : Vector2i = Vector2i(10, 10)

# Scene cỏ WindGrass (Quest)
@export var wind_grass_scene: PackedScene
@export var wind_grass_amount: int = 5

const GROWTH_PER_MINUTE: float = 0.2

var block_data: Array = []
var is_initialized: bool = false

func _ready() -> void:
	pass 

func _ensure_setup():
	if is_initialized: return
	
	await get_tree().physics_frame
	await get_tree().process_frame
	
	renderer.setup(ground_extents.x, ground_extents.y)
	_create_ground_collision()
	is_initialized = true

func generate_new_map():
	await _ensure_setup()
	
	print("✨ Generator: Tạo map mới...")
	setup_data_array()
	
	# [SỬA LẠI]: Trả về GRASS để hiện cỏ trang trí (Decorative Grass)
	for x in range(ground_extents.x):
		for z in range(ground_extents.y):
			block_data[x][z].mode = BlockGroundData.Mode.GRASS
			renderer.set_mode(x, z, BlockGroundData.Mode.GRASS)

	# Sau đó mới rải WindGrass lên trên nền GRASS
	if wind_grass_amount > 0:
		spawn_random_grass(wind_grass_amount)

func load_from_data(data: Dictionary):
	await _ensure_setup()
	
	if not data.has("grid"):
		await generate_new_map()
		return

	print("📂 Generator: Load map cũ...")


	for child in get_children():
		if child.has_method("harvest") or child.get("current_grid_pos") != null or child.name.contains("WindGrass"):
			child.queue_free()

	# ... (Giữ nguyên đoạn load GridData ở giữa) ...
	var last_saved_time = data.get("saved_total_minutes", TimeManager.get_total_minutes_played())
	var current_time = TimeManager.get_total_minutes_played()
	var growth_bonus = int((current_time - last_saved_time) * GROWTH_PER_MINUTE)
	
	var grid_info = data["grid"]
	block_data.resize(ground_extents.x)
	
	for x in range(ground_extents.x):
		block_data[x] = []
		for z in range(ground_extents.y):
			var saved_tile = grid_info[x][z]
			var d = BlockGroundData.new()
			if saved_tile is Dictionary:
				d.mode = saved_tile["mode"]
				d.plant_type = saved_tile.get("plant_type", PlantDatabase.PLANT_VARIANT.NONE)
				d.crop_ready = saved_tile.get("crop_ready", false)
				d.is_watered = saved_tile.get("is_watered", false)
				var saved_growth = saved_tile.get("growth", 0)
				
				block_data[x].append(d)
				renderer.set_mode(x, z, d.mode)
				
				if d.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
					_respawn_crop(x, z, d, saved_growth + growth_bonus)
			
			elif saved_tile is BlockGroundData:
				d.mode = saved_tile.mode
				block_data[x].append(d)
				renderer.set_mode(x, z, d.mode)

	# [CHỈNH SỬA ĐOẠN CUỐI NÀY]
	if data.has("grass_list"):
		print("🌿 Đang phục hồi ", data["grass_list"].size(), " bụi cỏ...")
		for pos in data["grass_list"]:
			var grid_pos = Vector2i.ZERO
			
			if pos is Dictionary and pos.has("x") and pos.has("y"):
				grid_pos = Vector2i(int(pos.x), int(pos.y))
			elif pos is Vector2 or pos is Vector2i:
				grid_pos = Vector2i(pos)
			else:
				continue 
			
			if grid_pos == Vector2i.ZERO:
				print("⚠️ Bỏ qua 1 bụi cỏ bị lỗi tọa độ (0,0)")
				continue
			# ------------------------------------------------------------
				
			_spawn_single_grass(grid_pos)
			

func get_current_state() -> Dictionary:
	var save_dict = {}
	save_dict["saved_total_minutes"] = TimeManager.get_total_minutes_played()
	
	var plant_map = {}
	var grass_list = []
	
	for child in get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			
			if child.name.contains("WindGrass"): 
				if child.get("current_grid_pos") != null:
					grass_list.append({
						"x": child.current_grid_pos.x, 
						"y": child.current_grid_pos.y
					})
			
			elif child.has_method("harvest"):
				if child.get("current_grid_pos") != null:
					plant_map[child.current_grid_pos] = child
				else:
					var grid_pos = get_grid_pos_from_world(child.global_position)
					plant_map[grid_pos] = child

	save_dict["grass_list"] = grass_list
	
	var grid_data = []
	for x in range(ground_extents.x):
		var row_data = []
		for z in range(ground_extents.y):
			var block = block_data[x][z]
			var pos = Vector2i(x, z)
			
			var tile_info = {
				"mode": block.mode,
				"plant_type": block.plant_type,
				"crop_ready": block.crop_ready,
				"growth": 0,
				"is_watered": block.is_watered
			}
			
			if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
				if not plant_map.has(pos):
					tile_info["plant_type"] = PlantDatabase.PLANT_VARIANT.NONE
					tile_info["crop_ready"] = false
					tile_info["growth"] = 0
					if tile_info["mode"] == BlockGroundData.Mode.PLANTED:
						tile_info["mode"] = BlockGroundData.Mode.TILLED
				else:
					tile_info["growth"] = plant_map[pos].get("current_growth")
			
			row_data.append(tile_info)
		grid_data.append(row_data)
	
	save_dict["grid"] = grid_data
	return save_dict

func _respawn_crop(x, z, block_data_item, final_growth):
	var world_pos = get_world_pos_from_grid(Vector2i(x, z))
	var plant_scene = PlantDatabase.get_plant_scene(block_data_item.plant_type)
	
	if plant_scene:
		var plant = plant_scene.instantiate()
		add_child(plant)
		plant.global_position = world_pos + Vector3(0, -0.04, 0)
		
		if "current_grid_pos" in plant:
			plant.current_grid_pos = Vector2i(x, z)
		
		if plant.get("current_growth") != null:
			plant.current_growth = final_growth
			
			if plant.get("max_growth") != null and plant.current_growth >= plant.max_growth:
				plant.current_growth = plant.max_growth
				plant.is_harvestable = true
				block_data_item.crop_ready = true
			
			if plant.has_method("update_visuals"):
				plant.update_visuals()

func setup_data_array():
	block_data.resize(ground_extents.x)
	for x in range(ground_extents.x):
		block_data[x] = []
		for z in range(ground_extents.y):
			var d = BlockGroundData.new()
			d.mode = BlockGroundData.Mode.GRASS
			block_data[x].append(d)

func _create_ground_collision() -> void:
	var static_body = StaticBody3D.new()
	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	var real_width = ground_extents.x * renderer.spacing
	var real_height = ground_extents.y * renderer.spacing
	shape.size = Vector3(real_width, 0.2, real_height)
	collider.shape = shape
	static_body.add_child(collider)
	static_body.position = Vector3(0, 0, 0)
	add_child(static_body)

func get_grid_pos_from_world(world_pos: Vector3) -> Vector2i:
	var spacing := renderer.spacing
	var half_x := ground_extents.x * spacing / 2.0
	var half_z := ground_extents.y * spacing / 2.0
	var gx = int(floor((world_pos.x + half_x) / spacing))
	var gz = int(floor((world_pos.z + half_z) / spacing))
	return Vector2i(clamp(gx, 0, ground_extents.x - 1), clamp(gz, 0, ground_extents.y - 1))

func get_world_pos_from_grid(grid_pos: Vector2i) -> Vector3:
	var spacing := renderer.spacing
	var half_x := ground_extents.x * spacing / 2.0
	var half_z := ground_extents.y * spacing / 2.0
	var world_x = grid_pos.x * spacing - half_x + spacing / 2.0
	var world_z = grid_pos.y * spacing - half_z + spacing / 2.0
	return Vector3(world_x, 0.0, world_z)

func is_valid_grid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < ground_extents.x and pos.y < ground_extents.y

func on_crop_ready(crop_node: Node):
	var grid_pos = get_grid_pos_from_world(crop_node.global_position)
	if is_valid_grid_pos(grid_pos):
		block_data[grid_pos.x][grid_pos.y].crop_ready = true

func reset_block_after_harvest(grid_pos: Vector2i, keep_tilled: bool = true):
	if not is_valid_grid_pos(grid_pos): return
	var block = block_data[grid_pos.x][grid_pos.y]
	block.plant_type = PlantDatabase.PLANT_VARIANT.NONE
	block.crop_ready = false
	if keep_tilled:
		block.mode = BlockGroundData.Mode.TILLED
		renderer.set_mode(grid_pos.x, grid_pos.y, BlockGroundData.Mode.TILLED)
	else:
		block.mode = BlockGroundData.Mode.CUT
		renderer.set_mode(grid_pos.x, grid_pos.y, BlockGroundData.Mode.CUT)

func get_plant_node(grid_pos: Vector2i) -> Node3D:
	for child in get_children():
		if child.get("current_grid_pos") != null and child.current_grid_pos == grid_pos:
			if child.has_method("grow"):
				return child
	return null

# GroundGenerator.gd

func spawn_random_grass(amount: int):
	await _ensure_setup()
	
	if not wind_grass_scene:
		printerr("⚠️ Chưa gắn WindGrassScene vào GroundGenerator!")
		return

	var count = 0
	var tries = 0
	var max_tries = amount * 20
	
	while count < amount and tries < max_tries:
		tries += 1
		var x = randi_range(0, ground_extents.x - 1)
		var z = randi_range(0, ground_extents.y - 1)
		
		var block = block_data[x][z]
		
		if block.mode == BlockGroundData.Mode.GRASS and block.plant_type == PlantDatabase.PLANT_VARIANT.NONE:
			
			var grass_obj = wind_grass_scene.instantiate()
			add_child(grass_obj)
			
			grass_obj.global_position = get_world_pos_from_grid(Vector2i(x, z)) + Vector3(0, -0.1, 0)
			
			if "current_grid_pos" in grass_obj:
				grass_obj.current_grid_pos = Vector2i(x, z)
			
			grass_obj.name = "WindGrass_" + str(x) + "_" + str(z)
			# ---------------------------
			
			count += 1
			
	print("🌱 Đã spawn ", count, " bụi cỏ WindGrass (Quest).")


func _spawn_single_grass(grid_pos: Vector2i):
	if not wind_grass_scene: return
	
	var block = block_data[grid_pos.x][grid_pos.y]
	if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
		return
		
	var grass_obj = wind_grass_scene.instantiate()
	add_child(grass_obj)
	
	grass_obj.global_position = get_world_pos_from_grid(grid_pos) + Vector3(0, -0.1, 0)
	
	if "current_grid_pos" in grass_obj:
		grass_obj.current_grid_pos = grid_pos
		
	# Đặt tên để dễ nhận diện khi lưu
	if not grass_obj.name.contains("WindGrass"):
		grass_obj.name = "WindGrass_" + str(grid_pos.x) + "_" + str(grid_pos.y)
