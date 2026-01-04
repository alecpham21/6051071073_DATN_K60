extends Node3D
class_name BuildingManager

@export var ground_gen: GroundGenerator
@export var buildings_container: Node3D
@export var all_building_resources: Array[BuildingData]

var current_building_preview: Node3D
var current_building_data: BuildingData
var can_place: bool = false
var _resource_map: Dictionary = {}

var padding_occupied_map: Dictionary = {} 

var current_rot_index: int = 0 

func _ready():
	
	add_to_group("mgr_build")
	
	if not buildings_container:
		buildings_container = Node3D.new()
		buildings_container.name = "Buildings"
		add_child(buildings_container)
	
	for res in all_building_resources:
		if res: _resource_map[res.id] = res

func _process(delta):
	if not current_building_preview:
		return

	if GState.is_build():
		var world_mouse_pos = _get_mouse_position_on_ground()
		
		if world_mouse_pos != Vector3.ZERO:
			update_preview_position(world_mouse_pos)
		else:
			can_place = false
			current_building_preview.visible = false
	else:
		current_building_preview.visible = false

func start_placing_building(data: BuildingData):
	if current_building_preview:
		current_building_preview.queue_free()
	
	current_rot_index = 0
	current_building_data = data
	current_building_preview = data.scene.instantiate()
	
	add_child(current_building_preview)
	
	current_building_preview.scale = _calculate_auto_scale(current_building_preview, data.size)
	
	_apply_blueprint_style(current_building_preview, Color(0.2, 0.8, 0.2, 0.5)) 
	
	_set_collision_enabled(current_building_preview, false)

func place_building() -> bool:
	print("🏗️ Đang thử đặt nhà...")
	
	if not current_building_preview: 
		print("❌ Lỗi: Không có Preview (Building Preview = Null)")
		return false
	
	if not can_place: 
		print("❌ Lỗi: Vị trí không hợp lệ (can_place = False). Đang bị cấm xây!")
		return false
	
	var used_size = get_rotated_size()
	var spacing = ground_gen.renderer.spacing
	var center_offset_x = (used_size.x * spacing) / 2.0 - (spacing / 2.0)
	var center_offset_z = (used_size.y * spacing) / 2.0 - (spacing / 2.0)
	var raw_pos = current_building_preview.global_position - Vector3(center_offset_x, 0, center_offset_z) - current_building_data.offset
	var grid_pos = ground_gen.get_grid_pos_from_world(raw_pos)
	
	spawn_building_node(
		current_building_data, 
		grid_pos, 
		current_building_preview.rotation, 
		used_size, 
		current_building_preview.scale
	)
	
	current_building_preview.queue_free()
	current_building_preview = null
	current_building_data = null
	
	print("✅ Đặt thành công!")
	return true
	
func _calculate_auto_scale(node: Node3D, data_size: Vector2i) -> Vector3:
	var old_rot = node.rotation
	var old_scale = node.scale
	node.rotation = Vector3.ZERO
	node.scale = Vector3.ONE
	
	var model_aabb = _get_hierarchy_aabb(node)
	var model_w = model_aabb.size.x
	var model_d = model_aabb.size.z
	
	node.rotation = old_rot
	node.scale = old_scale
	
	var spacing = ground_gen.renderer.spacing
	var target_w = data_size.x * spacing
	var target_d = data_size.y * spacing
	
	var s_x = 1.0
	var s_z = 1.0
	
	if model_w > 0.01: s_x = target_w / model_w
	if model_d > 0.01: s_z = target_d / model_d
	
	var s_y = max(s_x, s_z)
	return Vector3(s_x, s_y, s_z)


func spawn_building_node(data: BuildingData, grid_pos: Vector2i, rot_rotation: Vector3, override_size: Vector2i = Vector2i.ZERO, scale_override: Vector3 = Vector3.ZERO):
	var real_building = data.scene.instantiate()
	var final_size = override_size if override_size != Vector2i.ZERO else data.size
	
	real_building.set_meta("build_id", data.id)
	real_building.set_meta("grid_pos", grid_pos)
	real_building.set_meta("size", final_size)
	
	buildings_container.add_child(real_building)
	
	var spacing = ground_gen.renderer.spacing
	var world_pos = ground_gen.get_world_pos_from_grid(grid_pos)
	
	var center_offset_x = (final_size.x * spacing) / 2.0 - (spacing / 2.0)
	var center_offset_z = (final_size.y * spacing) / 2.0 - (spacing / 2.0)
	
	real_building.global_position = world_pos + Vector3(center_offset_x, 0, center_offset_z) + data.offset
	real_building.global_rotation = rot_rotation
	
	if scale_override != Vector3.ZERO:
		real_building.scale = scale_override
	else:
		real_building.scale = _calculate_auto_scale(real_building, final_size)
	
	mark_grid_occupied(grid_pos, final_size, true)

func check_can_place(start_grid: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var check_pos = start_grid + Vector2i(x, y)
			
			# Case 1: Trong Grid chính -> Check Block Data
			if ground_gen.is_valid_grid_pos(check_pos):
				var block = ground_gen.block_data[check_pos.x][check_pos.y]
				if block.has_building: 
					# print("⛔ Cấm: Ô đất ", check_pos, " đã có nhà")
					return false
				if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE: 
					# print("⛔ Cấm: Ô đất ", check_pos, " đang trồng cây")
					return false
			
			# Case 2: Trong Padding -> Check Dictionary
			elif ground_gen.is_in_padding_bounds(check_pos):
				if padding_occupied_map.has(check_pos):
					# print("⛔ Cấm: Vùng padding ", check_pos, " bị chiếm")
					return false
			
			# Case 3: Ngoài vùng phủ sóng (Ra khỏi map)
			else:
				# print("⛔ Cấm: Ô ", check_pos, " nằm ngoài map")
				return false
				
	return true

func mark_grid_occupied(start_grid: Vector2i, size: Vector2i, is_occupied: bool):
	for x in range(size.x):
		for y in range(size.y):
			var pos = start_grid + Vector2i(x, y)
			
			if ground_gen.is_valid_grid_pos(pos):
				var block = ground_gen.block_data[pos.x][pos.y]
				block.has_building = is_occupied
			
			elif ground_gen.is_in_padding_bounds(pos):
				if is_occupied:
					padding_occupied_map[pos] = true
				else:
					padding_occupied_map.erase(pos)

func update_preview_position(mouse_pos_3d: Vector3):
	if not current_building_preview: return
	current_building_preview.visible = true
	
	var grid_pos = ground_gen.get_grid_pos_from_world(mouse_pos_3d)
	var used_size = get_rotated_size()
	
	can_place = check_can_place(grid_pos, used_size)
	
	# Đổi màu preview (Xanh/Đỏ)
	_update_preview_color(can_place)
	
	var world_pos = ground_gen.get_world_pos_from_grid(grid_pos)
	var spacing = ground_gen.renderer.spacing
	
	var center_offset_x = (used_size.x * spacing) / 2.0 - (spacing / 2.0)
	var center_offset_z = (used_size.y * spacing) / 2.0 - (spacing / 2.0)
	
	current_building_preview.global_position = world_pos + Vector3(center_offset_x, 0, center_offset_z) + current_building_data.offset


func get_rotated_size() -> Vector2i:
	if current_rot_index % 2 == 1:
		return Vector2i(current_building_data.size.y, current_building_data.size.x)
	return current_building_data.size

func rotate_preview():
	if not current_building_preview: return
	current_rot_index = (current_rot_index + 1) % 4
	current_building_preview.rotation_degrees.y = current_rot_index * 90.0
	var world_mouse_pos = _get_mouse_position_on_ground()
	if world_mouse_pos != Vector3.ZERO:
		update_preview_position(world_mouse_pos)

func _get_mouse_position_on_ground() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera: return Vector3.ZERO
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true; query.collide_with_bodies = true; query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	if result: return result.position
	return Vector3.ZERO

func _get_hierarchy_aabb(node: Node3D) -> AABB:
	var aabb = AABB()
	var first = true
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	for mesh_instance in meshes:
		if mesh_instance.visible and mesh_instance.mesh:
			var mesh_aabb = mesh_instance.get_aabb()
			var tr = node.global_transform.affine_inverse() * mesh_instance.global_transform
			mesh_aabb = tr * mesh_aabb
			if first:
				aabb = mesh_aabb; first = false
			else:
				aabb = aabb.merge(mesh_aabb)
	if first: return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	return aabb

func _set_collision_enabled(node: Node, enabled: bool):
	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.disabled = !enabled
	for child in node.get_children():
		_set_collision_enabled(child, enabled)

func _update_preview_color(allowed: bool):
	if not current_building_preview: return
	
	var color = Color(0.0, 0.6, 1.0, 0.4)
	if not allowed:
		color = Color(1.0, 0.2, 0.2, 0.4)
	
	_apply_blueprint_style(current_building_preview, color)

func cancel_build():
	if current_building_preview:
		current_building_preview.queue_free()
		current_building_preview = null
	current_building_data = null; can_place = false

# BuildingManager.gd

func _unhandled_input(event):
	if not GState.is_build() or not current_building_preview: return
	
	# --- XÓA HOẶC COMMENT ĐOẠN NÀY ĐI ---
	# Lý do: Player.gd đã lo phần này rồi. Nếu để ở đây nó sẽ chặn Player.
	# if event.is_action_pressed("click"):
	# 	place_building()
	# 	get_viewport().set_input_as_handled()
	# -------------------------------------
	
	# Giữ lại phần xoay (Chuột phải) vì Player không xử lý cái này
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		rotate_preview()
		get_viewport().set_input_as_handled()
		
	# Xóa luôn phần Cancel ở đây, vì Player cũng đã xử lý
	# if event.is_action_pressed("ui_cancel"):
	# 	cancel_build()
	# 	get_viewport().set_input_as_handled()

func clear_all_buildings():
	for child in buildings_container.get_children(): child.queue_free()
	padding_occupied_map.clear()

func restore_building(id: String, grid_pos: Vector2i, rot: Vector3, scale_override: Vector3 = Vector3.ZERO):
	if _resource_map.has(id):
		var data = _resource_map[id]
		var restore_size = data.size
		var deg_y = int(round(rad_to_deg(rot.y))) % 360
		if deg_y == 90 or deg_y == 270 or deg_y == -90 or deg_y == -270:
			restore_size = Vector2i(data.size.y, data.size.x)
		spawn_building_node(data, grid_pos, rot, restore_size, scale_override)
	else:
		printerr("⚠️ Không tìm thấy BuildingData ID: ", id)

func _apply_blueprint_style(node: Node, color: Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_recursive_set_material(node, mat)

func _recursive_set_material(node: Node, mat: Material):
	if node is MeshInstance3D:
		# Override toàn bộ bề mặt của mesh thành màu blueprint
		node.material_override = mat
		# Tắt bóng đổ của preview
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
	for child in node.get_children():
		_recursive_set_material(child, mat)
