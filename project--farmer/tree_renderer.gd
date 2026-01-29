@tool
extends Node3D
class_name TreeRenderer

@export_group("Debug & Actions")
@export var test_generate: bool = false:
	set(value):
		if value:
			generate_forest()
		test_generate = false
@export var clear_forest: bool = false:
	set(value):
		if value:
			_clear_all()
		clear_forest = false

@export_group("Tree Assets")
@export var tree_scene: PackedScene 
@export var scale_min: float = 1.0
@export var scale_max: float = 1.5
@export var rotation_correction: Vector3 = Vector3(0, 0, 0) 

@export_group("Forest Settings")
@export var tree_count: int = 2000 
@export var spawn_radius_min: float = 60.0 
@export var spawn_radius_max: float = 300.0 
@export var y_offset: float = 0.0

func _clear_all():
	for child in get_children():
		child.queue_free()
	print("🗑️ Đã xóa sạch rừng cây cũ.")

func generate_forest():
	_clear_all()
	if not tree_scene:
		print("❌ LỖI: Chưa gắn 'Tree Scene'!")
		return

	print("🌲 Bắt đầu trồng ", tree_count, " cây (Sao chép chính xác)...")
	_spawn_complex_forest()

func _spawn_complex_forest():
	var temp_instance = tree_scene.instantiate()
	add_child(temp_instance)
	
	temp_instance.global_position = Vector3(99999, 99999, 99999)
	
	var render_nodes = []
	_find_render_nodes_recursive(temp_instance, render_nodes)
	
	if render_nodes.is_empty():
		print("❌ LỖI: Không tìm thấy Mesh/MultiMesh nào!")
		temp_instance.queue_free()
		return
	
	print("✅ Tìm thấy ", render_nodes.size(), " bộ phận.")

	var tree_base_transforms = []
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var correction_rad = rotation_correction * (PI / 180.0)
	var correction_basis = Basis.from_euler(correction_rad)
	
	for i in range(tree_count):
		var angle = rng.randf() * TAU
		var dist = sqrt(rng.randf_range(pow(spawn_radius_min, 2), pow(spawn_radius_max, 2)))
		
		var x = cos(angle) * dist
		var z = sin(angle) * dist
		var pos = Vector3(x, y_offset, z)
		
		var rot_y = rng.randf_range(0, TAU)
		var s = rng.randf_range(scale_min, scale_max)
		
		var basis = Basis(Vector3.UP, rot_y) * correction_basis
		basis = basis.scaled(Vector3(s, s, s))
		
		tree_base_transforms.append(Transform3D(basis, pos))

	var node_count = 0
	
	var root_inverse = temp_instance.global_transform.affine_inverse()
	
	for node in render_nodes:
		var final_transforms = []
		var source_mesh: Mesh = null
		var material_to_use: Material = null
		
		var relative_transform = root_inverse * node.global_transform
		
		if node is MeshInstance3D:
			source_mesh = node.mesh
			material_to_use = node.material_override
			if !material_to_use and source_mesh.get_surface_count() > 0:
				material_to_use = node.get_active_material(0)
				
			for t_base in tree_base_transforms:
				# Vị trí Cuối = Vị trí Gốc Cây Mới * Vị trí Tương Đối Cũ
				final_transforms.append(t_base * relative_transform)
		
		elif node is MultiMeshInstance3D:
			if node.multimesh and node.multimesh.mesh:
				source_mesh = node.multimesh.mesh
				material_to_use = node.material_override
				
				# Lấy vị trí của từng lá bên trong MultiMesh cũ
				var leaf_locals = []
				for k in range(node.multimesh.instance_count):
					leaf_locals.append(node.multimesh.get_instance_transform(k))
				
				for t_base in tree_base_transforms:
					# Tính vị trí của "Cụm lá" mới
					var bush_world = t_base * relative_transform
					
					# Nhân bản từng chiếc lá ra
					for t_leaf in leaf_locals:
						final_transforms.append(bush_world * t_leaf)
			else:
				print("⚠️ Cảnh báo: MultiMesh rỗng ở node ", node.name)

		# --- TẠO MULTIMESH MỚI ---
		if source_mesh and final_transforms.size() > 0:
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = source_mesh
			mm.instance_count = final_transforms.size()
			mm.custom_aabb = AABB(Vector3(-10000, -500, -10000), Vector3(20000, 1000, 20000))
			
			var mmi = MultiMeshInstance3D.new()
			mmi.name = "Forest_" + str(node_count) + "_" + node.name
			mmi.multimesh = mm
			if material_to_use: mmi.material_override = material_to_use
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			
			add_child(mmi)
			if Engine.is_editor_hint():
				mmi.owner = get_tree().edited_scene_root
			
			for k in range(final_transforms.size()):
				mm.set_instance_transform(k, final_transforms[k])
			node_count += 1

	temp_instance.queue_free()
	print("✨ Xong! Đã sao chép chính xác cấu trúc cây.")

func _find_render_nodes_recursive(node: Node, result_array: Array):
	if node is MeshInstance3D:
		if node.visible: result_array.append(node)
	elif node is MultiMeshInstance3D:
		if node.visible: result_array.append(node)
			
	for child in node.get_children():
		_find_render_nodes_recursive(child, result_array)
