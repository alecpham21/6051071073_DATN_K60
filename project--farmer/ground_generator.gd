@tool
extends Node3D
class_name GroundGenerator

var renderer: GroundRenderer:
	get: return get_node_or_null("GroundRenderer") as GroundRenderer
var tree_renderer: Node3D:
	get: return get_node_or_null("TreeRenderer")
var fence_generator: Node3D:
	get: return get_node_or_null("FenceGenerator")
var nav_region: NavigationRegion3D:
	get: return get_node_or_null("NavRegion")

@export var ground_extents : Vector2i = Vector2i(10, 10)
@export_group("Editor Tools")
@export var btn_generate: bool = false:
	set(value):
		if value:
			generate_new_map()
			btn_generate = false

@export var btn_clear: bool = false:
	set(value):
		if value:
			clear_map()
			btn_clear = false


@export_group("Gameplay Settings")
@export var wind_grass_scene: PackedScene
@export var wind_grass_amount: int = 5
@export var building_manager: BuildingManager

@export_group("Visuals")
@export var show_border: bool = true
@export var border_color: Color = Color(0.35, 0.25, 0.15)
@export var padding_base_color: Color = Color(0.1, 0.12, 0.1)

const GROWTH_PER_MINUTE: float = 0.2
const PADDING_RATIO: float = 8

const MAX_PADDING_DEPTH: int = 50

var block_data: Array = []
var is_initialized: bool = false
var current_padding: int = 0

var is_nav_dirty: bool = false

func _ready() -> void:
	add_to_group("ground_generator")
	if Engine.is_editor_hint():
		return
		
	if nav_region:
		nav_region.bake_finished.connect(_on_bake_finished)

func _on_bake_finished():
	print("✅ NavMesh Bake Hoàn tất.")
	
	if is_nav_dirty:
		print("🔄 Phát hiện thay đổi trong lúc bake, đang bake lại...")
		is_nav_dirty = false
		bake_nav_mesh()

func _ensure_setup():
	if is_initialized: return
	
	if not Engine.is_editor_hint():
		await get_tree().physics_frame
		await get_tree().process_frame
	
	var max_side = max(ground_extents.x, ground_extents.y)
	current_padding = clamp(int(ceil(max_side * PADDING_RATIO)), 2, MAX_PADDING_DEPTH)
	
	if renderer: renderer.setup(ground_extents.x, ground_extents.y, current_padding)
	_create_ground_collision()
	if fence_generator: fence_generator.generate_fences(self, ground_extents)
	if show_border: _create_visual_boundary()
	
	is_initialized = true

func _create_visual_boundary():
	var old_border = get_node_or_null("PlayAreaBorder")
	if old_border: old_border.free()
	
	for child in get_children():
		if child is MeshInstance3D and child.mesh is PlaneMesh and child.name != "GroundRenderer":
			if abs(child.position.y - (-0.15)) < 0.01: child.free()

	if not renderer: return
	var spacing: float = renderer.spacing
	
	var bg_plane = MeshInstance3D.new()
	bg_plane.name = "PaddingBG"
	var bg_mesh = PlaneMesh.new()
	bg_mesh.size = Vector2((ground_extents.x + current_padding * 2) * spacing, (ground_extents.y + current_padding * 2) * spacing)
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = padding_base_color
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_plane.mesh = bg_mesh
	bg_plane.position = Vector3(0, -0.15, 0)
	
	_add_child_editor(bg_plane)

	if fence_generator:
		var border_node = Node3D.new()
		border_node.name = "PlayAreaBorder"
		_add_child_editor(border_node)
		

func clear_map():
	print("🧹 [Tool] Đang dọn dẹp triệt để...")
	
	for child in get_children():
		if "WindGrass" in child.name or "PlayAreaBorder" in child.name or "PaddingBG" in child.name:
			child.free()
	
	if renderer:
		for child in renderer.get_children():
			child.free()
	
	if fence_generator:
		for child in fence_generator.get_children(): child.free()
	if building_manager:
		building_manager.clear_all_buildings()
	
	var targets = nav_region.get_children() if nav_region else get_children()
	for child in targets:
		if child is StaticBody3D: child.free()
			
	block_data.clear()
	is_initialized = false
	print("✨ [Tool] Map đã được clear sạch sẽ!")

func generate_new_map():
	print("🏗️ [Tool] Bắt đầu tạo map...")
	
	clear_map()
	
	if Engine.is_editor_hint():
		_ensure_setup_internal()
	else:
		await _ensure_setup()
	
	setup_data_array()
	
	if renderer:
		for x in range(ground_extents.x):
			for z in range(ground_extents.y):
				block_data[x][z].mode = BlockGroundData.Mode.GRASS
				renderer.set_mode(x, z, BlockGroundData.Mode.GRASS)
	
	if building_manager: _spawn_initial_buildings()
	if wind_grass_amount > 0: spawn_random_grass(wind_grass_amount)
	
	if tree_renderer and tree_renderer.has_method("generate_forest"):
		tree_renderer.generate_forest()
	
	bake_nav_mesh()
	print("✅ [Tool] Tạo map xong.")

func _ensure_setup_internal():
	var max_side = max(ground_extents.x, ground_extents.y)
	current_padding = clamp(int(ceil(max_side * PADDING_RATIO)), 2, MAX_PADDING_DEPTH)
	
	if renderer: renderer.setup(ground_extents.x, ground_extents.y, current_padding)
	_create_ground_collision()
	if fence_generator: fence_generator.generate_fences(self, ground_extents)
	if show_border: _create_visual_boundary()


func _add_child_editor(node: Node):
	add_child(node)
	if Engine.is_editor_hint():
		node.owner = get_tree().edited_scene_root




func can_dig(grid_pos: Vector2i) -> bool:
	if not is_valid_grid_pos(grid_pos): return false
	var block = block_data[grid_pos.x][grid_pos.y]
	if block.has_building: return false
	if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE: return false
	return true



func _spawn_initial_buildings():
	if not building_manager: return
	print("Placing default Building")
	
	var house_id = "first_house"
	var house_world_pos = Vector3(-21.217, 0, 0)
	var house_grid = get_grid_pos_from_world(house_world_pos)
	var house_rot = Vector3(0, deg_to_rad(90.0), 0)
	var house_scale = Vector3(1.5, 1.5, 1.5)
	var house_node = building_manager.restore_building(house_id, house_grid, house_rot, house_scale)
	if house_node: house_node.set_meta("is_initial", true)
	
	var well_id = "well"
	var well_world_pos = Vector3(-20.848, 0, -6.554)
	var well_grid = get_grid_pos_from_world(well_world_pos)
	var well_rot = Vector3(0, deg_to_rad(90.0), 0)
	var well_node = building_manager.restore_building(well_id, well_grid, well_rot, Vector3.ZERO)
	if well_node: well_node.set_meta("is_initial", true)
	
	var tree_id_1 = "tree_ver_1"
	var tree_world_pos = Vector3(-9.267, 0, -20.396)
	var tree_grid = get_grid_pos_from_world(tree_world_pos)
	var tree_node1 = building_manager.restore_building(tree_id_1, tree_grid, house_rot, Vector3.ZERO)
	if tree_node1: tree_node1.set_meta("is_initial", true)

	var tree_id_2 = "tree_ver_2"
	var tree2_world_pos = Vector3(6.803, 0, -20.396)
	var tree2_grid = get_grid_pos_from_world(tree2_world_pos)
	var tree_node2 = building_manager.restore_building(tree_id_2, tree2_grid, house_rot, Vector3.ZERO)
	if tree_node2: tree_node2.set_meta("is_initial", true)

func load_from_data(data: Dictionary, minutes_away: float = 0.0):
	await _ensure_setup()
	
	# 1. GLOBAL CLEANUP: Quét sạch group 'crates' nhưng LOẠI TRỪ Player
	var all_crates = get_tree().get_nodes_in_group("crates")
	print("[DEBUG] GroundGen: Global cleanup. Nodes in 'crates' group: ", all_crates.size())
	
	for crate in all_crates:
		# BẢO VỆ PLAYER: Tuyệt đối không xóa nếu là CharacterBody3D hoặc thuộc group player
		if crate is CharacterBody3D or crate.is_in_group("player") or crate == PlayerData.player:
			print("[DEBUG] GroundGen: Shielding player node from cleanup: ", crate.name)
			continue
			
		# Bảo vệ cái đang cầm trên tay
		if crate.get("is_being_carried"): 
			continue
		
		print("[DEBUG] GroundGen: Nuking crate: ", crate.name)
		crate.queue_free()
	
	# Dọn dẹp các node con khác nhưng vẫn phải check bảo vệ Player
	for child in get_children():
		if child is CharacterBody3D or child.is_in_group("player") or child == PlayerData.player:
			continue
		if child.has_method("harvest") or child.get("current_grid_pos") != null or child.name.contains("WindGrass"):
			child.queue_free()

	if not data.has("grid"):
		await generate_new_map()
		return
	
	var last_saved_time = data.get("saved_total_minutes", TimeManager.get_total_minutes_played())
	var current_time = TimeManager.get_total_minutes_played()
	var minutes_passed = current_time - last_saved_time
	var grid_info = data["grid"]
	
	block_data.clear()
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
				d.growth = saved_tile.get("growth", 0)
			block_data[x].append(d)

	print("🌱 Generator: Calculating offline growth and spawning nodes...")
	for x in range(ground_extents.x):
		for z in range(ground_extents.y):
			var d = block_data[x][z]
			
			renderer.set_mode(x, z, d.mode)
			
			if d.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
				var final_growth = d.growth
				
				if d.is_watered:
					var max_g = 15
					var current_stage = _calculate_stage_id(d.growth, max_g)
					
					var limit = 0
					if current_stage == 0: limit = int(max_g * 0.2) + 1
					elif current_stage == 1: limit = int(max_g * 0.5) + 1
					elif current_stage == 2: limit = max_g
					else: limit = max_g + 1
					
					var bonus = int(minutes_passed * GROWTH_PER_MINUTE)
					var potential = d.growth + bonus
					
					if potential >= limit:
						final_growth = limit
						d.is_watered = false
						print("📏 Plant at ", Vector2i(x,z), " reached Stage ", current_stage + 1, " and consumed water.")
					else:
						final_growth = potential
				
				_respawn_crop(x, z, d, final_growth)
				
	if data.has("grass_list"):
		for pos in data["grass_list"]:
			var g_pos = Vector2i(int(pos.x), int(pos.y))
			_spawn_single_grass(g_pos)
	
	if data.has("crates"):
		print("[DEBUG] GroundGen: Spawning ", data["crates"].size(), " crates from data.")
		var crate_scene = load("res://quests/Quest_Item/crate.tscn")
		for c_data in data["crates"]:
			var new_crate = crate_scene.instantiate()
			add_child(new_crate)
			new_crate.load_save_data(c_data)
			if not new_crate.is_in_group("crates"):
				new_crate.add_to_group("crates")
	
	
	if building_manager:
		building_manager.clear_all_buildings() 
		if data.has("buildings"):
			for b_info in data["buildings"]:
				var b_pos = Vector2i(b_info["x"], b_info["y"])
				var b_rot = Vector3(b_info["rot_x"], b_info["rot_y"], b_info["rot_z"])
				var b_scale = Vector3(b_info.get("sc_x", 0), b_info.get("sc_y", 0), b_info.get("sc_z", 0))
				
				var b_node = building_manager.restore_building(b_info["id"], b_pos, b_rot, b_scale)
				if b_node and b_node.has_method("load_machine_data") and b_info.has("machine_data"):
					b_node.load_machine_data(b_info["machine_data"], minutes_away)
	
	if data.has("truck_data"):
		var truck_node = get_tree().get_first_node_in_group("truck")
		
		if is_instance_valid(truck_node) and truck_node.has_method("load_save_data"):
			truck_node.load_save_data(data["truck_data"])
			print("[DEBUG] GroundGen: Truck state restored.")
		else:
			print("[DEBUG] GroundGen Error: Cannot find node in group 'truck' during load!")
	
	bake_nav_mesh()
	print("✅ Generator: Map load completed.")

func get_current_state() -> Dictionary:
	var save_dict = {}
	
	var crate_list = []
	for child in get_tree().get_nodes_in_group("crates"):
		if child is ContractCrate and is_ancestor_of(child): 
			crate_list.append(child.get_save_data())
	save_dict["crates"] = crate_list
	
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
				if child is ContractCrate or child.is_in_group("crates"):
					continue
					
				var b_dict = {
					"id": child.get_meta("build_id"),
					"x": child.get_meta("grid_pos").x,
					"y": child.get_meta("grid_pos").y,
					"rot_x": child.global_rotation.x,
					"rot_y": child.global_rotation.y,
					"rot_z": child.global_rotation.z,
					"sc_x": child.scale.x,
					"sc_y": child.scale.y,
					"sc_z": child.scale.z
				}
				if child.has_method("get_machine_data"):
					b_dict["machine_data"] = child.get_machine_data()
				building_list.append(b_dict)
	
	save_dict["buildings"] = building_list
	
	var truck_node = get_tree().get_first_node_in_group("truck")
	if is_instance_valid(truck_node) and truck_node.has_method("get_save_data"):
		save_dict["truck_data"] = truck_node.get_save_data()
		print("[DEBUG] GroundGen: Truck state saved.")
		
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
	
	if nav_region:
		nav_region.add_child(static_body)
	else:
		add_child(static_body)

func bake_nav_mesh():
	if not nav_region: return
	
	if nav_region.is_baking():
		print("⚠️ NavMesh đang bận, đánh dấu bake lại sau!")
		is_nav_dirty = true
		return

	nav_region.bake_navigation_mesh()

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

func _calculate_stage_id(growth: int, max_g: int) -> int:
	if growth > max_g: return 4
	
	var progress = float(growth) / float(max_g)
	if progress >= 1.0: return 3
	if progress > 0.5: return 2
	if progress > 0.2: return 1
	return 0
