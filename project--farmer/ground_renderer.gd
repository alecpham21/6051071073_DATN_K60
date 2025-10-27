extends Node3D
class_name GroundRenderer

@export var mesh: Mesh
@export var mat_grass: Material
@export var mat_cut: Material
@export var mat_tilled: Material
@export var spacing := 1.0

@export var dark_grass_mesh: Mesh
@export var light_grass_mesh: Mesh
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

var inst_grass: MultiMeshInstance3D
var inst_cut: MultiMeshInstance3D
var inst_tilled: MultiMeshInstance3D
var inst_dark_grass: MultiMeshInstance3D
var inst_light_grass: MultiMeshInstance3D
var scale_x: float
var scale_y: float
var scale_z: float


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
	var idx_dark := 0
	var idx_light := 0
	var center_offset = Vector3(grid_size_x * spacing / 2, 0, grid_size_z * spacing / 2)

	for x in range(grid_size_x):
		for z in range(grid_size_z):
			if randf() > decorative_grass_chance:
				continue

			# Spawn 1 cặp dark + light grass
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
					scale_vec = Vector3(randf_range(0.5, 0.8), 1, 0.8)
				else:
					scale_vec = Vector3(randf_range(0.4, 0.7), 0.6, 0.7)

				var basis_instance = basis_pair.scaled(scale_vec)
				var transform_instance = Transform3D(basis_instance, pos_instance)

				if variant == "dark":
					mm_dark_grass.set_instance_transform(idx_dark, transform_instance)
					idx_dark += 1
				else:
					mm_light_grass.set_instance_transform(idx_light, transform_instance)
					idx_light += 1



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
		var start_idx = idx * max_grass_per_block
		for i in range(max_grass_per_block):
			if mm_dark_grass:
				mm_dark_grass.set_instance_transform(start_idx + i, Transform3D())
			if mm_light_grass:
				mm_light_grass.set_instance_transform(start_idx + i, Transform3D())
			


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
