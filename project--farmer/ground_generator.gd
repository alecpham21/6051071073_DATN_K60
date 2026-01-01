extends Node3D
class_name GroundGenerator

@onready var renderer: GroundRenderer = $GroundRenderer
@onready var tree_renderer: TreeRenderer = $TreeRenderer
@onready var fence_generator: FenceGenerator = $FenceGenerator

@export var ground_extents : Vector2i = Vector2i(10, 10)

@export_group("Gameplay Settings")
@export var wind_grass_scene: PackedScene
@export var wind_grass_amount: int = 5
@export var building_manager: BuildingManager

@export_group("Visuals")
@export var show_border: bool = true
@export var border_color: Color = Color(0.35, 0.25, 0.15) # Màu nâu đất đậm cho viền
@export var padding_base_color: Color = Color(0.1, 0.12, 0.1) # Màu xanh đen tối cho nền padding

const GROWTH_PER_MINUTE: float = 0.2
const PADDING_RATIO: float = 8

const MAX_PADDING_DEPTH: int = 50

var block_data: Array = []
var is_initialized: bool = false
var current_padding: int = 0

func _ready() -> void:
	pass

func _ensure_setup():
	if is_initialized: return
	
	await get_tree().physics_frame
	await get_tree().process_frame
	
	var max_side = max(ground_extents.x, ground_extents.y)
	
	var calc_padding = int(ceil(max_side * PADDING_RATIO))
	current_padding = clamp(calc_padding, 2, MAX_PADDING_DEPTH)
	
	renderer.setup(ground_extents.x, ground_extents.y, current_padding)
	
	_create_ground_collision()
	
	if fence_generator:
		fence_generator.generate_fences(self, ground_extents)
	else:
		printerr("⚠️nonode FenceGenerator in Scene")
	
	if show_border:
		_create_visual_boundary() # <--- Tạo viền phân chia
	
	is_initialized = true

func _create_visual_boundary():
	var spacing = renderer.spacing
	var width = ground_extents.x * spacing
	var height = ground_extents.y * spacing
	
	var bg_plane = MeshInstance3D.new()
	var bg_mesh = PlaneMesh.new()
	var total_w = (ground_extents.x + current_padding * 2) * spacing
	var total_h = (ground_extents.y + current_padding * 2) * spacing
	bg_mesh.size = Vector2(total_w, total_h)
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = padding_base_color
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mesh.material = bg_mat
	bg_plane.mesh = bg_mesh
	bg_plane.position = Vector3(0, -0.15, 0)
	add_child(bg_plane)

	if fence_generator:
		var fence_pad = fence_generator.padding_expansion
		var fence_width = (ground_extents.x + fence_pad * 2) * spacing
		var fence_height = (ground_extents.y + fence_pad * 2) * spacing
		
		var border_node = Node3D.new()
		border_node.name = "PlayAreaBorder"
		add_child(border_node)
		
		var thickness = 0.2
		var border_mat_inst = StandardMaterial3D.new()
		border_mat_inst.albedo_color = border_color
		
		var pos_offsets = [
			Vector3(0, 0, -(ground_extents.y + fence_pad * 2) * spacing / 2.0 / 2.0), # Sai logic tí, để đơn giản ta vẽ border theo logic cũ nhưng rộng hơn chút
		]

func generate_new_map():
	await _ensure_setup()
	print("✨ Generator: Tạo map mới...")
	setup_data_array()
	for x in range(ground_extents.x):
		for z in range(ground_extents.y):
			block_data[x][z].mode = BlockGroundData.Mode.GRASS
			renderer.set_mode(x, z, BlockGroundData.Mode.GRASS)
	
	if building_manager:
		_spawn_initial_buildings()
	
	if wind_grass_amount > 0:
		spawn_random_grass(wind_grass_amount)
	if tree_renderer:
		tree_renderer.generate_forest()

func _spawn_initial_buildings():
	print("🏗️ Đang đặt các công trình mặc định...")
	
	var house_id = "first_house"
	var house_world_pos = Vector3(-21.217, 0, 0)
	var house_grid = get_grid_pos_from_world(house_world_pos)
	var house_rot = Vector3(0, deg_to_rad(90.0), 0)
	var house_scale = Vector3(1.49, 1.49, 1.49)
	building_manager.restore_building(house_id, house_grid, house_rot, house_scale)
	
	var well_id = "well"
	var well_world_pos = Vector3(-20.848, 0, -6.554)
	var well_grid = get_grid_pos_from_world(well_world_pos)
	var well_rot = Vector3(0, deg_to_rad(90.0), 0)
	var well_scale = Vector3(0.685, 0.685, 0.685)
	building_manager.restore_building(well_id, well_grid, well_rot, well_scale)


func load_from_data(data: Dictionary):
	await _ensure_setup()
	if not data.has("grid"):
		await generate_new_map()
		return
	print("📂 Generator: Load map cũ...")
	for child in get_children():
		if child.name == "PaddingDecor": continue 
		if child.has_method("harvest") or child.get("current_grid_pos") != null or child.name.contains("WindGrass"):
			child.queue_free()
	
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
				continue
			_spawn_single_grass(grid_pos)
	if building_manager:
		building_manager.clear_all_buildings() # Xóa nhà cũ
		if data.has("buildings"):
			print("🏠 Loading ", data["buildings"].size(), " buildings...")
			for b_info in data["buildings"]:
				var b_pos = Vector2i(b_info["x"], b_info["y"])
				var b_rot = Vector3(b_info["rot_x"], b_info["rot_y"], b_info["rot_z"])
				building_manager.restore_building(b_info["id"], b_pos, b_rot)


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
	var building_list = []
	if building_manager and building_manager.buildings_container:
		for child in building_manager.buildings_container.get_children():
			if child.has_meta("build_id"):
				var grid_pos = child.get_meta("grid_pos")
				var rot = child.global_rotation
				building_list.append({
					"id": child.get_meta("build_id"),
					"x": grid_pos.x,
					"y": grid_pos.y,
					"rot_x": rot.x,
					"rot_y": rot.y,
					"rot_z": rot.z
				})
	save_dict["buildings"] = building_list
	
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
	
	var total_width_tiles = ground_extents.x + (current_padding * 2)
	var total_height_tiles = ground_extents.y + (current_padding * 2)
	
	var real_width = total_width_tiles * renderer.spacing
	var real_height = total_height_tiles * renderer.spacing
	
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
	
	return Vector2i(gx, gz)

func get_world_pos_from_grid(grid_pos: Vector2i) -> Vector3:
	var spacing := renderer.spacing
	var half_x := ground_extents.x * spacing / 2.0
	var half_z := ground_extents.y * spacing / 2.0
	var world_x = grid_pos.x * spacing - half_x + spacing / 2.0
	var world_z = grid_pos.y * spacing - half_z + spacing / 2.0
	return Vector3(world_x, 0.0, world_z)

func is_valid_grid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < ground_extents.x and pos.y < ground_extents.y

func is_in_padding_bounds(pos: Vector2i) -> bool:
	var limit_pad = current_padding
	
	if fence_generator:
		limit_pad = fence_generator.padding_expansion
	
	var min_limit = -limit_pad
	var max_limit_x = ground_extents.x + limit_pad
	var max_limit_y = ground_extents.y + limit_pad
	
	
	var inside_x = pos.x > min_limit and pos.x < max_limit_x
	var inside_y = pos.y > min_limit and pos.y < max_limit_y
	
	return inside_x and inside_y

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
	if not grass_obj.name.contains("WindGrass"):
		grass_obj.name = "WindGrass_" + str(grid_pos.x) + "_" + str(grid_pos.y)
