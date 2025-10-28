extends Node3D
class_name GroundRenderer

@onready var ground_gen: Node = $".."

@export var mesh: Mesh
@export var mat_grass: Material
@export var mat_cut: Material
@export var mat_tilled: Material
@export var spacing := 1.0

@export var dark_grass_mesh: Mesh
@export var light_grass_mesh: Mesh

@export var grass_mesh: Mesh
@export var grass_scale_min: float = 0.8
@export var grass_scale_max: float = 1.2

@export var grass_count_per_block := 3
@export var grass_spawn_chance := 0.4

@export var grass_spacing := 0.5   # random space
@export var max_grass_per_block := 4
@export var spawn_grass_decorative: bool = true
@export var decorative_grass_chance := 0.25

var grid_size_x := 0
var grid_size_z := 0

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



var scale_x: float
var scale_y: float
var scale_z: float
var dark_grass_index_per_block: Array
var light_grass_index_per_block: Array
var grass_index_per_block: Array

func setup(x_count: int, z_count: int) -> void:
	grid_size_x = x_count
	grid_size_z = z_count

	
	# Nếu export chưa có vật liệu thì tạo tạm
	if mat_grass == null:
		var grass_mat = StandardMaterial3D.new()
		grass_mat.albedo_color = Color(0.3, 0.8, 0.3)
		mat_grass = grass_mat

	if mat_cut == null:
		var cut_mat = StandardMaterial3D.new()
		cut_mat.albedo_color = Color(0.6, 0.4, 0.2)
		mat_cut = cut_mat

	if mat_tilled == null:
		var tilled_mat = StandardMaterial3D.new()
		tilled_mat.albedo_color = Color(0.4, 0.25, 0.1)
		mat_tilled = tilled_mat

	_create_multimeshes()
	
	if spawn_grass_decorative:
		spawn_decorative_grass()

func _create_multimeshes():
	if mesh == null:
		var box = BoxMesh.new()
		box.size = Vector3(1, 0.1, 1)
		mesh = box
		spacing = box.size.x

	mm_grass = MultiMesh.new()
	mm_grass.mesh = mesh
	mm_grass.transform_format = MultiMesh.TRANSFORM_3D
	mm_grass.instance_count = grid_size_x * grid_size_z

	mm_cut = MultiMesh.new()
	mm_cut.mesh = mesh
	mm_cut.transform_format = MultiMesh.TRANSFORM_3D
	mm_cut.instance_count = grid_size_x * grid_size_z

	mm_tilled = MultiMesh.new()
	mm_tilled.mesh = mesh
	mm_tilled.transform_format = MultiMesh.TRANSFORM_3D
	mm_tilled.instance_count = grid_size_x * grid_size_z

# Dark Grass
	if dark_grass_mesh:
		mm_dark_grass = MultiMesh.new()
		mm_dark_grass.mesh = dark_grass_mesh
		mm_dark_grass.transform_format = MultiMesh.TRANSFORM_3D
		mm_dark_grass.instance_count = grid_size_x * grid_size_z * max_grass_per_block

		inst_dark_grass = MultiMeshInstance3D.new()
		inst_dark_grass.multimesh = mm_dark_grass
		add_child(inst_dark_grass)

# Light Grass
	if light_grass_mesh:
		mm_light_grass = MultiMesh.new()
		mm_light_grass.mesh = light_grass_mesh
		mm_light_grass.transform_format = MultiMesh.TRANSFORM_3D
		mm_light_grass.instance_count = grid_size_x * grid_size_z * max_grass_per_block

		inst_light_grass = MultiMeshInstance3D.new()
		inst_light_grass.multimesh = mm_light_grass
		add_child(inst_light_grass)

# Decorative Grass
	if grass_mesh:
		mm_grass_decor = MultiMesh.new()
		mm_grass_decor.mesh = grass_mesh
		mm_grass_decor.transform_format = MultiMesh.TRANSFORM_3D
		mm_grass_decor.instance_count = grid_size_x * grid_size_z * grass_count_per_block

		inst_grass_decor = MultiMeshInstance3D.new()
		inst_grass_decor.multimesh = mm_grass_decor
		add_child(inst_grass_decor)


	inst_grass = MultiMeshInstance3D.new()
	inst_grass.multimesh = mm_grass
	inst_grass.material_override = mat_grass
	add_child(inst_grass)

	inst_cut = MultiMeshInstance3D.new()
	inst_cut.multimesh = mm_cut
	inst_cut.material_override = mat_cut
	add_child(inst_cut)

	inst_tilled = MultiMeshInstance3D.new()
	inst_tilled.multimesh = mm_tilled
	inst_tilled.material_override = mat_tilled
	add_child(inst_tilled)

	inst_grass.position.y = -mesh.size.y / 2
	inst_cut.position.y = -mesh.size.y / 2
	inst_tilled.position.y = -mesh.size.y / 2


	var center_offset = Vector3(grid_size_x * spacing / 2, 0, grid_size_z * spacing / 2)

	for x in range(grid_size_x):
		for z in range(grid_size_z):
			var idx = x * grid_size_z + z
			var pos = Vector3(x * spacing + mesh.size.x/2, -mesh.size.y/2, z * spacing + mesh.size.z/2) - center_offset
			var t = Transform3D(Basis(), pos)
			mm_grass.set_instance_transform(idx, t)

func spawn_decorative_grass():
	dark_grass_index_per_block = []
	light_grass_index_per_block = []
	grass_index_per_block = []


	for i in range(grid_size_x * grid_size_z):
		dark_grass_index_per_block.append([])
		light_grass_index_per_block.append([])
		grass_index_per_block.append([])

	
	var idx_dark := 0
	var idx_light := 0
	var center_offset = Vector3(grid_size_x * spacing / 2, 0, grid_size_z * spacing / 2)

	for x in range(grid_size_x):
		for z in range(grid_size_z):
			if randf() > decorative_grass_chance:
				continue

			# Spawn 1 cặp dark + light grass
			var block_idx = x * grid_size_z + z
			var rot_y = randf_range(0.0, TAU)  # rotation chung cho cặp
			var basis_pair = Basis(Vector3.UP, rot_y)

			for variant in ["dark", "light"]:
				var pos_instance = Vector3(
					x * spacing + randf() * grass_spacing,
					0.0,
					z * spacing + randf() * grass_spacing
				) - center_offset

				# scale khác nhau cho dark/light
				var scale_vec: Vector3
				if variant == "dark":
					scale_vec = Vector3(randf_range(0.4, 0.6), 0.7, 0.8)
				else:
					scale_vec = Vector3(randf_range(0.2, 0.5), 0.4, 0.7)

				var basis_instance = basis_pair.scaled(scale_vec)
				var transform_instance = Transform3D(basis_instance, pos_instance)

				if variant == "dark" and mm_dark_grass:
					mm_dark_grass.set_instance_transform(idx_dark, transform_instance)
					dark_grass_index_per_block[block_idx].append(idx_dark)
					idx_dark += 1
				elif variant == "light" and mm_light_grass:
					mm_light_grass.set_instance_transform(idx_light, transform_instance)
					light_grass_index_per_block[block_idx].append(idx_light)
					idx_light += 1
	# Spawn random grass (độc lập)
	if grass_mesh and mm_grass_decor:
		var idx_grass := 0
		for x in range(grid_size_x):
			for z in range(grid_size_z):
				if randf() > grass_spawn_chance:
					continue  # bỏ qua block này theo tỉ lệ spawn
				
				var block_idx = x * grid_size_z + z
				var num_in_block = randi_range(1, grass_count_per_block)
				
				for i in range(num_in_block):
					var pos = ground_gen.get_world_pos_from_grid(Vector2i(x, z))
					pos.x += randf_range(-grass_spacing, grass_spacing)
					pos.z += randf_range(-grass_spacing, grass_spacing)


					var rot_y = randf_range(0.0, TAU)
					var basis = Basis(Vector3.UP, rot_y)
					var uniform_scale = randf_range(grass_scale_min, grass_scale_max)
					var scale_vec = Vector3.ONE * uniform_scale



					basis = basis.scaled(scale_vec)
					var transform_instance = Transform3D(basis, pos)

					mm_grass_decor.set_instance_transform(idx_grass, transform_instance)
					grass_index_per_block[block_idx].append(idx_grass)
					idx_grass += 1



func set_mode(x: int, z: int, mode: int, variant: int = 0):
	if grid_size_x == 0 or grid_size_z == 0:
		return

	var idx = x * grid_size_z + z
	var center_offset = Vector3(grid_size_x * spacing / 2, 0, grid_size_z * spacing / 2)
	var base_pos = Vector3(x * spacing + mesh.size.x/2, 0, z * spacing + mesh.size.z/2) - center_offset

	var y_offset := 0.0
	match mode:
		BlockGroundData.Mode.GRASS:
			y_offset = 0.1
		BlockGroundData.Mode.CUT:
			y_offset = -0.02
		BlockGroundData.Mode.TILLED:
			y_offset = -0.04

	# Tạo transform mới
	var t = Transform3D(Basis(), base_pos + Vector3(0, y_offset, 0))

	# Xóa vị trí cũ để tránh chồng
	mm_grass.set_instance_transform(idx, Transform3D())
	mm_cut.set_instance_transform(idx, Transform3D())
	mm_tilled.set_instance_transform(idx, Transform3D())

	if mode == BlockGroundData.Mode.TILLED:
		var block_idx = x * grid_size_z + z
		if  mm_dark_grass:
			for slot in dark_grass_index_per_block[block_idx]:
				mm_dark_grass.set_instance_transform(slot, Transform3D())
			dark_grass_index_per_block[block_idx].clear()
		if  mm_light_grass:
			for slot in light_grass_index_per_block[block_idx]:
				mm_light_grass.set_instance_transform(slot, Transform3D())
			light_grass_index_per_block[block_idx].clear()
		if mm_grass_decor:
			for slot in grass_index_per_block[block_idx]:
				mm_grass_decor.set_instance_transform(slot, Transform3D())
			grass_index_per_block[block_idx].clear()


	# Chọn màu/material dựa trên variant
	if variant == 1 and mode == BlockGroundData.Mode.GRASS:
		inst_grass.material_override.albedo_color = Color(0.2, 0.7, 0.2) # dark
	elif variant == 2 and mode == BlockGroundData.Mode.GRASS:
		inst_grass.material_override.albedo_color = Color(0.4, 0.9, 0.4) # light
	else:
		inst_grass.material_override.albedo_color = Color(0.3, 0.8, 0.3)

	match mode:
		BlockGroundData.Mode.GRASS:
			mm_grass.set_instance_transform(idx, t)
		BlockGroundData.Mode.CUT:
			mm_cut.set_instance_transform(idx, t)
		BlockGroundData.Mode.TILLED:
			mm_tilled.set_instance_transform(idx, t)
