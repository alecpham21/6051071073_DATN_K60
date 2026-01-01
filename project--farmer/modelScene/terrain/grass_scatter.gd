@tool
extends Node3D

@export_category("Thiết Lập Cơ Bản")
@export var grass_mesh: Mesh
@export var amount: int = 1000

@export_group("Mục Tiêu (Kéo Node vào đây)")
@export var spawn_area: Area3D  # Cái hộp giới hạn phạm vi
@export var target_ground: StaticBody3D # Cái mặt đất cụ thể muốn trồng lên

@export_group("Biến thiên")
@export var min_scale: float = 0.8
@export var max_scale: float = 1.2
@export var random_rotation: bool = true

@export_group("Hành động")
@export var generate: bool = false : set = _on_generate_pressed
@export var clear: bool = false : set = _on_clear_pressed

var multimesh_instance: MultiMeshInstance3D

func _ready():
	if has_node("GrassMultiMesh"):
		multimesh_instance = get_node("GrassMultiMesh")
	else:
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "GrassMultiMesh"
		add_child(multimesh_instance)
		multimesh_instance.owner = get_tree().edited_scene_root

func _on_generate_pressed(value):
	if value == false: return
	_generate_grass()
	generate = false

func _on_clear_pressed(value):
	if value == false: return
	if multimesh_instance:
		multimesh_instance.multimesh = null
	print("🗑️ Đã xóa sạch cỏ.")
	clear = false

func _generate_grass():
	# --- 1. KIỂM TRA ĐẦU VÀO (Không check layer nữa, check Node) ---
	if !spawn_area:
		printerr("❌ Chưa kéo Area3D vào ô Spawn Area!")
		return
	if !target_ground:
		printerr("❌ Chưa kéo StaticBody3D (Mặt đất) vào ô Target Ground!")
		return
	if !grass_mesh:
		printerr("❌ Chưa có Grass Mesh!")
		return

	# Lấy cái hộp Collision bên trong Area
	var collision_node = null
	for child in spawn_area.get_children():
		if child is CollisionShape3D:
			collision_node = child
			break
	
	if !collision_node or !collision_node.shape is BoxShape3D:
		printerr("❌ Area3D cần phải có con là CollisionShape3D dạng BOX!")
		return

	print("------------------------------------------------")
	print("🌱 Đang trồng ", amount, " cây lên: ", target_ground.name)

	# --- 2. CHUẨN BỊ MULTIMESH ---
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = grass_mesh
	mm.instance_count = amount
	multimesh_instance.multimesh = mm
	
	var box_size = collision_node.shape.size
	# Lấy transform toàn cầu của Area để tính toán vị trí tương đối
	var area_transform = collision_node.global_transform
	
	var space_state = get_world_3d().direct_space_state
	var success_count = 0
	
	# --- 3. VÒNG LẶP SPAWN ---
	for i in range(amount):
		# A. Chọn 1 điểm ngẫu nhiên TRONG HỘP (Theo hệ Local của cái hộp)
		var random_pos_local = Vector3(
			randf_range(-box_size.x / 2, box_size.x / 2),
			0, # Tạm thời Y = 0, lát nữa Raycast sẽ tìm độ cao thật
			randf_range(-box_size.z / 2, box_size.z / 2)
		)
		
		# B. Chuyển điểm đó ra tọa độ thế giới (Global)
		# Để đảm bảo dù Area xoay hay dịch chuyển thế nào, điểm rải vẫn nằm trong đó
		var ray_origin_global = area_transform * random_pos_local
		
		# C. Setup Raycast: Bắn từ trên cao xuống thấp tại đúng tọa độ X, Z đó
		# Nâng điểm bắt đầu lên cao (trên trời) và điểm kết thúc xuống thấp (dưới vực)
		var ray_from = Vector3(ray_origin_global.x, ray_origin_global.y + 100.0, ray_origin_global.z)
		var ray_to = Vector3(ray_origin_global.x, ray_origin_global.y - 100.0, ray_origin_global.z)
		
		var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		# D. Bắn tia!
		var result = space_state.intersect_ray(query)
		
		if result:
			# E. KIỂM TRA MỤC TIÊU: Có trúng đúng cái Ground mình muốn không?
			# Đây là bước thay thế cho Layer Mask
			if result.collider == target_ground:
				var t = Transform3D()
				
				# QUAN TRỌNG: Lấy điểm va chạm (trên dốc, dưới hố) chuyển về Local của MultiMesh
				t.origin = multimesh_instance.to_local(result.position)
				
				# Xoay ngẫu nhiên
				if random_rotation:
					t = t.rotated(Vector3.UP, randf_range(0, TAU))
				
				# Scale ngẫu nhiên
				var s = randf_range(min_scale, max_scale)
				t = t.scaled(Vector3(s, s, s))
				
				mm.set_instance_transform(i, t)
				success_count += 1
			else:
				# Bắn trúng cái gì đó không phải Ground (ví dụ tảng đá, nhà cửa...) -> Bỏ qua
				mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -9999, 0)))
		else:
			# Không trúng gì cả -> Bỏ qua
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -9999, 0)))

	if success_count == 0:
		printerr("❌ Vẫn không trồng được cây nào!")
		printerr("👉 Gợi ý: Kiểm tra xem cái StaticBody3D Ground có CollisionShape chưa?")
	else:
		print("✅ XONG! Đã trồng ", success_count, " cây chính xác trên bề mặt ", target_ground.name)
