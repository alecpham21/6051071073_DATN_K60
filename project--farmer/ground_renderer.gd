extends Node3D
class_name GroundRenderer

@onready var ground_gen: Node = $".."

@export var mesh: Mesh
@export var mat_grass: Material
@export var mat_cut: Material
@export var mat_tilled: Material
@export var mat_padding: Material
@export var spacing := 1.0

@export_group("Infinite Background")
@export var enable_infinite_bg: bool = true
@export var bg_plane_size: float = 2000.0
@export var bg_y_offset: float = -0.5

@export_group("Grass")
@export var dark_grass_mesh: Mesh
@export var light_grass_mesh: Mesh
@export var grass_mesh: Mesh
@export var grass_scale_min: float = 0.8
@export var grass_scale_max: float = 1.2
@export var grass_count_per_block := 3
@export var grass_spawn_chance := 0.4
@export var grass_spacing := 0.5
@export var max_grass_per_block := 4
@export var spawn_grass_decorative: bool = true
@export var decorative_grass_chance := 0.25

# Chỉ lưu kích thước logic (vùng chơi), không cần visual_size nữa
var logic_size_x := 0
var logic_size_z := 0
var padding := 0

var mm_grass: MultiMesh
var mm_cut: MultiMesh
var mm_tilled: MultiMesh
var mm_dark_grass: MultiMesh
var mm_light_grass: MultiMesh
var mm_grass_decor: MultiMesh

var inst_grass: MultiMeshInstance3D
var inst_cut: MultiMeshInstance3D
var inst_tilled: MultiMeshInstance3D
var inst_dark_grass: MultiMeshInstance3D
var inst_light_grass: MultiMeshInstance3D
var inst_grass_decor: MultiMeshInstance3D
var inst_bg_plane: MeshInstance3D

# Container chứa 4 cạnh viền
var padding_border_container: Node3D 

var dark_grass_index_per_block: Array
var light_grass_index_per_block: Array
var grass_index_per_block: Array

var hidden_transform = Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)

func setup(x_count: int, z_count: int, p_padding: int) -> void:
	# Xóa hết các node con cũ
	for child in get_children():
		child.queue_free()
		
	logic_size_x = x_count
	logic_size_z = z_count
	padding = p_padding
	
	if mat_grass == null: mat_grass = StandardMaterial3D.new()
	if mat_cut == null: mat_cut = StandardMaterial3D.new()
	if mat_tilled == null: mat_tilled = StandardMaterial3D.new()
	if mat_padding == null: 
		mat_padding = StandardMaterial3D.new()
		mat_padding.albedo_color = Color(0.15, 0.15, 0.15)

	# 1. Tạo Grid chính (Chỉ vùng chơi)
	_create_multimeshes()
	
	# 2. Tạo viền Padding (4 khối lớn) thay vì MultiMesh
	_create_padding_borders()
	
	# 3. Tạo nền vô tận
	if enable_infinite_bg:
		_create_background_plane()
	
	# 4. Spawn cỏ (Chỉ trên vùng chơi)
	if spawn_grass_decorative:
		spawn_decorative_grass()

func _create_multimeshes():
	var mesh_height = 0.1
	if mesh: mesh_height = mesh.get_aabb().size.y
	else:
		var box = BoxMesh.new()
		box.size = Vector3(1, 0.1, 1)
		mesh = box
		spacing = box.size.x
		mesh_height = box.size.y

	# SỐ LƯỢNG INSTANCE GIỜ CHỈ BẰNG ĐÚNG SỐ Ô CHƠI (Không cộng padding)
	var total_count = logic_size_x * logic_size_z 
	
	# Tạo AABB lớn để tránh lỗi tự tắt khi ra xa
	var huge_aabb = AABB(Vector3(-1000, -50, -1000), Vector3(2000, 100, 2000))

	# Setup MultiMesh cho đất
	mm_grass = MultiMesh.new(); mm_grass.mesh = mesh; mm_grass.transform_format = MultiMesh.TRANSFORM_3D; mm_grass.instance_count = total_count; mm_grass.custom_aabb = huge_aabb
	mm_cut = MultiMesh.new(); mm_cut.mesh = mesh; mm_cut.transform_format = MultiMesh.TRANSFORM_3D; mm_cut.instance_count = total_count; mm_cut.custom_aabb = huge_aabb
	mm_tilled = MultiMesh.new(); mm_tilled.mesh = mesh; mm_tilled.transform_format = MultiMesh.TRANSFORM_3D; mm_tilled.instance_count = total_count; mm_tilled.custom_aabb = huge_aabb

	# Setup MultiMesh cho cỏ trang trí (Nếu có mesh)
	if dark_grass_mesh:
		mm_dark_grass = MultiMesh.new(); mm_dark_grass.mesh = dark_grass_mesh; mm_dark_grass.transform_format = MultiMesh.TRANSFORM_3D
		mm_dark_grass.instance_count = total_count * max_grass_per_block
		mm_dark_grass.custom_aabb = huge_aabb
		inst_dark_grass = MultiMeshInstance3D.new(); inst_dark_grass.multimesh = mm_dark_grass; add_child(inst_dark_grass)
		for i in range(mm_dark_grass.instance_count): mm_dark_grass.set_instance_transform(i, hidden_transform)

	if light_grass_mesh:
		mm_light_grass = MultiMesh.new(); mm_light_grass.mesh = light_grass_mesh; mm_light_grass.transform_format = MultiMesh.TRANSFORM_3D
		mm_light_grass.instance_count = total_count * max_grass_per_block
		mm_light_grass.custom_aabb = huge_aabb
		inst_light_grass = MultiMeshInstance3D.new(); inst_light_grass.multimesh = mm_light_grass; add_child(inst_light_grass)
		for i in range(mm_light_grass.instance_count): mm_light_grass.set_instance_transform(i, hidden_transform)

	if grass_mesh:
		mm_grass_decor = MultiMesh.new(); mm_grass_decor.mesh = grass_mesh; mm_grass_decor.transform_format = MultiMesh.TRANSFORM_3D
		mm_grass_decor.instance_count = total_count * grass_count_per_block
		mm_grass_decor.custom_aabb = huge_aabb
		inst_grass_decor = MultiMeshInstance3D.new(); inst_grass_decor.multimesh = mm_grass_decor; add_child(inst_grass_decor)
		for i in range(mm_grass_decor.instance_count): mm_grass_decor.set_instance_transform(i, hidden_transform)

	# Tạo Instance
	inst_grass = MultiMeshInstance3D.new(); inst_grass.multimesh = mm_grass; inst_grass.material_override = mat_grass; add_child(inst_grass)
	inst_cut = MultiMeshInstance3D.new(); inst_cut.multimesh = mm_cut; inst_cut.material_override = mat_cut; add_child(inst_cut)
	inst_tilled = MultiMeshInstance3D.new(); inst_tilled.multimesh = mm_tilled; inst_tilled.material_override = mat_tilled; add_child(inst_tilled)

	# Hạ độ cao xuống một chút
	inst_grass.position.y = -mesh_height / 2
	inst_cut.position.y = -mesh_height / 2
	inst_tilled.position.y = -mesh_height / 2
	
	# Khởi tạo toàn bộ đất về vị trí ẩn
	for i in range(total_count):
		mm_grass.set_instance_transform(i, hidden_transform)
		mm_cut.set_instance_transform(i, hidden_transform)
		mm_tilled.set_instance_transform(i, hidden_transform)

func _create_padding_borders():
	if padding <= 0: return
	
	padding_border_container = Node3D.new()
	padding_border_container.name = "PaddingBorders"
	add_child(padding_border_container)
	
	# Tính toán kích thước
	var map_width = logic_size_x * spacing
	var map_depth = logic_size_z * spacing
	var border_thick = padding * spacing
	var mesh_h = 0.1
	if mesh: mesh_h = mesh.get_aabb().size.y
	
	# 1. Cạnh Trên (North) - Bao phủ cả bề ngang + 2 góc
	var top = _create_single_border_block(Vector3(map_width + border_thick * 2, mesh_h, border_thick))
	top.position = Vector3(0, -mesh_h/2, -map_depth/2 - border_thick/2)
	
	# 2. Cạnh Dưới (South)
	var bottom = _create_single_border_block(Vector3(map_width + border_thick * 2, mesh_h, border_thick))
	bottom.position = Vector3(0, -mesh_h/2, map_depth/2 + border_thick/2)
	
	# 3. Cạnh Trái (West) - Chỉ phần giữa
	var left = _create_single_border_block(Vector3(border_thick, mesh_h, map_depth))
	left.position = Vector3(-map_width/2 - border_thick/2, -mesh_h/2, 0)
	
	# 4. Cạnh Phải (East)
	var right = _create_single_border_block(Vector3(border_thick, mesh_h, map_depth))
	right.position = Vector3(map_width/2 + border_thick/2, -mesh_h/2, 0)

func _create_single_border_block(size: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat_padding
	padding_border_container.add_child(mi)
	return mi

func _create_background_plane():
	inst_bg_plane = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(bg_plane_size, bg_plane_size)
	
	inst_bg_plane.mesh = plane
	inst_bg_plane.material_override = mat_grass
	
	inst_bg_plane.name = "InfiniteBackgroundPlane"
	add_child(inst_bg_plane)
	inst_bg_plane.position.y = bg_y_offset

func spawn_decorative_grass():
	var total_blocks = logic_size_x * logic_size_z
	
	# Reset mảng quản lý
	dark_grass_index_per_block = []; light_grass_index_per_block = []; grass_index_per_block = []
	dark_grass_index_per_block.resize(total_blocks)
	light_grass_index_per_block.resize(total_blocks)
	grass_index_per_block.resize(total_blocks)
	
	for i in range(total_blocks):
		dark_grass_index_per_block[i] = []; light_grass_index_per_block[i] = []; grass_index_per_block[i] = []

	var idx_dark := 0; var idx_light := 0; var idx_grass := 0
	var center_offset = Vector3(logic_size_x * spacing / 2, 0, logic_size_z * spacing / 2)

	for lx in range(logic_size_x):
		for lz in range(logic_size_z):
			var block_idx = lx * logic_size_z + lz
			if randf() > decorative_grass_chance: continue

			var rot_y = randf_range(0.0, TAU)
			var basis_pair = Basis(Vector3.UP, rot_y)

			for variant in ["dark", "light"]:
				var pos_instance = Vector3(
					lx * spacing + randf() * grass_spacing, 0.0,
					lz * spacing + randf() * grass_spacing
				) - center_offset + Vector3(spacing/2, 0, spacing/2) # Căn lại center cho chuẩn

				var scale_vec: Vector3
				if variant == "dark": scale_vec = Vector3(randf_range(0.3, 0.5), 0.7, 0.8)
				else: scale_vec = Vector3(randf_range(0.2, 0.4), 0.4, 0.7)

				var transform_instance = Transform3D(basis_pair.scaled(scale_vec), pos_instance)

				if variant == "dark" and mm_dark_grass:
					mm_dark_grass.set_instance_transform(idx_dark, transform_instance)
					dark_grass_index_per_block[block_idx].append(idx_dark)
					idx_dark += 1
				elif variant == "light" and mm_light_grass:
					mm_light_grass.set_instance_transform(idx_light, transform_instance)
					light_grass_index_per_block[block_idx].append(idx_light)
					idx_light += 1
					
			if grass_mesh and mm_grass_decor and randf() <= grass_spawn_chance:
				var num = randi_range(1, grass_count_per_block)
				for k in range(num):
					var pos = Vector3(
						lx * spacing + randf_range(0, spacing), 0,
						lz * spacing + randf_range(0, spacing)
					) - center_offset + Vector3(spacing/2, 0, spacing/2)
					
					var b = Basis(Vector3.UP, randf_range(0, TAU)).scaled(Vector3.ONE * randf_range(grass_scale_min, grass_scale_max))
					mm_grass_decor.set_instance_transform(idx_grass, Transform3D(b, pos))
					grass_index_per_block[block_idx].append(idx_grass)
					idx_grass += 1

func set_mode(logic_x: int, logic_z: int, mode: int, _variant: int = 0):
	# Code mới đơn giản hơn: Logic X/Z chính là index luôn, không cần cộng padding nữa
	if logic_x < 0 or logic_z < 0 or logic_x >= logic_size_x or logic_z >= logic_size_z: return
	
	var idx = logic_x * logic_size_z + logic_z
	var center_offset = Vector3(logic_size_x * spacing / 2, 0, logic_size_z * spacing / 2)
	var mesh_sz = spacing
	if mesh and mesh is BoxMesh: mesh_sz = mesh.size.x
		
	# Tính vị trí world
	var base_pos = Vector3(
		logic_x * spacing + mesh_sz/2, 
		0, 
		logic_z * spacing + mesh_sz/2
	) - center_offset

	var y_offset := 0.0
	if mode == BlockGroundData.Mode.TILLED: y_offset = -0.04

	var t = Transform3D(Basis(), base_pos + Vector3(0, y_offset, 0))

	# Reset về ẩn trước
	mm_grass.set_instance_transform(idx, hidden_transform)
	mm_cut.set_instance_transform(idx, hidden_transform)
	mm_tilled.set_instance_transform(idx, hidden_transform)

	# Xóa cỏ nếu đất bị cuốc
	if mode == BlockGroundData.Mode.TILLED or mode == BlockGroundData.Mode.CUT:
		_clear_decor_at_visual(logic_x, logic_z)

	match mode:
		BlockGroundData.Mode.GRASS: mm_grass.set_instance_transform(idx, t)
		BlockGroundData.Mode.CUT: mm_cut.set_instance_transform(idx, t)
		BlockGroundData.Mode.TILLED: mm_tilled.set_instance_transform(idx, t)

func _clear_decor_at_visual(lx, lz):
	# Hàm này giờ nhận Logic X/Z
	var idx = lx * logic_size_z + lz
	if dark_grass_index_per_block.size() <= idx: return
	
	if mm_dark_grass:
		for slot in dark_grass_index_per_block[idx]: mm_dark_grass.set_instance_transform(slot, hidden_transform)
		dark_grass_index_per_block[idx].clear()
	if mm_light_grass:
		for slot in light_grass_index_per_block[idx]: mm_light_grass.set_instance_transform(slot, hidden_transform)
		light_grass_index_per_block[idx].clear()
	if mm_grass_decor:
		for slot in grass_index_per_block[idx]: mm_grass_decor.set_instance_transform(slot, hidden_transform)
		grass_index_per_block[idx].clear()
