extends Node3D
class_name GroundRenderer

@export var mesh: Mesh
@export var mat_grass: Material
@export var mat_cut: Material
@export var mat_tilled: Material
@export var spacing := 1.0

var grid_size_x := 0
var grid_size_z := 0

var mm_grass: MultiMesh
var mm_cut: MultiMesh
var mm_tilled: MultiMesh

var inst_grass: MultiMeshInstance3D
var inst_cut: MultiMeshInstance3D
var inst_tilled: MultiMeshInstance3D

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
##Old Set_mode but Function
#func set_mode(x: int, z: int, mode: int):
	#if grid_size_x == 0 or grid_size_z == 0:
		#return
#
	#var idx = x * grid_size_z + z
	#var center_offset = Vector3(grid_size_x * spacing / 2, 0, grid_size_z * spacing / 2)
#
	## vị trí cơ bản
	#var base_pos = Vector3(x * spacing + mesh.size.x / 2, 0, z * spacing + mesh.size.z / 2) - center_offset
#
	## chỉnh độ cao tùy mode
	#var y_offset := 0.0
	#match mode:
		#0: y_offset = 0.1           # grass bình thường
		#1: y_offset = -0.02         # cut lún nhẹ
		#2: y_offset = -0.04  
		#_: 0.0
## tilled lún sâu hơn
#
	## set transform mới
	#var t = Transform3D(Basis(), base_pos + Vector3(0, y_offset, 0))
#
	## clear 3 cái multimesh kia để tránh block hiển thị chồng nhau
	#mm_grass.set_instance_transform(idx, Transform3D()) 
	#mm_cut.set_instance_transform(idx, Transform3D()) 
	#mm_tilled.set_instance_transform(idx, Transform3D())
#
	#match mode:
		#0: mm_grass.set_instance_transform(idx, t)
		#1: mm_cut.set_instance_transform(idx, t)
		#2: mm_tilled.set_instance_transform(idx, t)

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
