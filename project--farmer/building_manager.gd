extends Node3D
class_name BuildingManager

@export var ground_gen: GroundGenerator
@export var buildings_container: Node3D
@export var all_building_resources: Array[BuildingData]

var current_building_preview: Node3D
var current_building_data: BuildingData
var can_place: bool = false
var _resource_map: Dictionary = {}

var current_rot_index: int = 0 

func _process(delta):
	if current_building_preview and GState.is_build():
		var world_mouse_pos = _get_mouse_position_on_ground()
		
		if world_mouse_pos != Vector3.ZERO:
			update_preview_position(world_mouse_pos)
		else:
			can_place = false
			
func _get_mouse_position_on_ground() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera: return Vector3.ZERO
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	return Vector3.ZERO

func _ready():
	if not buildings_container:
		buildings_container = Node3D.new()
		buildings_container.name = "Buildings"
		add_child(buildings_container)
	
	for res in all_building_resources:
		if res: _resource_map[res.id] = res

func get_rotated_size() -> Vector2i:
	if current_rot_index % 2 == 1:
		return Vector2i(current_building_data.size.y, current_building_data.size.x)
	return current_building_data.size

func start_placing_building(data: BuildingData):
	if current_building_preview:
		current_building_preview.queue_free()
	
	current_rot_index = 0
	current_building_data = data
	current_building_preview = data.scene.instantiate()
	current_building_preview.scale = data.scale
	add_child(current_building_preview)
	
	_set_collision_enabled(current_building_preview, false)

func rotate_preview():
	if not current_building_preview: return
	
	current_rot_index = (current_rot_index + 1) % 4
	var angle = current_rot_index * 90.0
	current_building_preview.rotation_degrees.y = angle
	
	var world_mouse_pos = _get_mouse_position_on_ground()
	if world_mouse_pos != Vector3.ZERO:
		update_preview_position(world_mouse_pos)

func update_preview_position(mouse_pos_3d: Vector3):
	if not current_building_preview: return
	
	var grid_pos = ground_gen.get_grid_pos_from_world(mouse_pos_3d)
	var used_size = get_rotated_size()
	
	can_place = check_can_place(grid_pos, used_size)
	
	_update_preview_color(can_place)
	
	var world_pos = ground_gen.get_world_pos_from_grid(grid_pos)
	var spacing = ground_gen.renderer.spacing
	
	var center_offset_x = (used_size.x * spacing) / 2.0 - (spacing / 2.0)
	var center_offset_z = (used_size.y * spacing) / 2.0 - (spacing / 2.0)
	
	current_building_preview.global_position = world_pos + Vector3(center_offset_x, 0, center_offset_z) + current_building_data.offset

func place_building():
	if not current_building_preview: return
	if not can_place: return
	
	var used_size = get_rotated_size()
	var spacing = ground_gen.renderer.spacing
	var center_offset_x = (used_size.x * spacing) / 2.0 - (spacing / 2.0)
	var center_offset_z = (used_size.y * spacing) / 2.0 - (spacing / 2.0)
	
	var raw_pos = current_building_preview.global_position - Vector3(center_offset_x, 0, center_offset_z) - current_building_data.offset
	var grid_pos = ground_gen.get_grid_pos_from_world(raw_pos)
	
	spawn_building_node(current_building_data, grid_pos, current_building_preview.rotation, used_size)
	
	current_building_preview.queue_free()
	current_building_preview = null
	current_building_data = null

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
		real_building.scale = data.scale
	
	mark_grid_occupied(grid_pos, final_size, true)

func check_can_place(start_grid: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var check_pos = start_grid + Vector2i(x, y)
			
			# Case 1: Nằm trong lưới chính -> Check Block Data
			if ground_gen.is_valid_grid_pos(check_pos):
				var block = ground_gen.block_data[check_pos.x][check_pos.y]
				if block.has_building: return false
				if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE: return false
			
			elif ground_gen.is_in_padding_bounds(check_pos):
				continue
				
			else:
				return false
				
	return true

func mark_grid_occupied(start_grid: Vector2i, size: Vector2i, is_occupied: bool):
	for x in range(size.x):
		for y in range(size.y):
			var pos = start_grid + Vector2i(x, y)
			if ground_gen.is_valid_grid_pos(pos):
				var block = ground_gen.block_data[pos.x][pos.y]
				block.has_building = is_occupied

func _set_collision_enabled(node: Node, enabled: bool):
	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.disabled = !enabled
	for child in node.get_children():
		_set_collision_enabled(child, enabled)

func _update_preview_color(allowed: bool):
	pass

func cancel_build():
	if current_building_preview:
		current_building_preview.queue_free()
		current_building_preview = null
	current_building_data = null
	can_place = false

func _unhandled_input(event):
	if not GState.is_build() or not current_building_preview:
		return

	if event.is_action_pressed("click"):
		place_building()
		get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		rotate_preview()
		get_viewport().set_input_as_handled()
		
	if event.is_action_pressed("ui_cancel"):
		cancel_build()
		get_viewport().set_input_as_handled()
	
func clear_all_buildings():
	for child in buildings_container.get_children():
		child.queue_free()
		
func restore_building(id: String, grid_pos: Vector2i, rot: Vector3, scale_override: Vector3 = Vector3.ZERO):
	if _resource_map.has(id):
		var data = _resource_map[id]
		var restore_size = data.size
		var deg_y = int(round(rad_to_deg(rot.y))) % 360
		if deg_y == 90 or deg_y == 270 or deg_y == -90 or deg_y == -270:
			restore_size = Vector2i(data.size.y, data.size.x)
			
		spawn_building_node(data, grid_pos, rot, restore_size, scale_override)
	else:
		printerr("⚠️ Không tìm thấy BuildingData cho ID: ", id)
