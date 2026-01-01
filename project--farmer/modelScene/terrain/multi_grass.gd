@tool
extends MultiMeshInstance3D

@export_category("Mục Tiêu")
# Kéo trực tiếp cái MeshInstance3D (Visual) vào đây. Không dùng StaticBody nữa.
@export var target_surface: MeshInstance3D : set = _set_surface

@export_category("Cấu Hình Spawn")
@export var count: int = 1000 : set = _set_count
@export var extents: Vector2 = Vector2(10, 10) : set = _set_extents
@export var align_to_normal: bool = true : set = _set_align

@export_category("Biến Thiên")
@export var min_scale: float = 0.8 : set = _set_min_scale
@export var max_scale: float = 1.2 : set = _set_max_scale
@export var height_offset: float = 0.0 : set = _set_offset # Chỉnh cái này nếu cỏ bị chìm hoặc nổi

@export_category("Hành Động")
@export var force_update: bool = false : set = _on_force_update

# --- SETTERS ---
func _set_surface(v): target_surface = v; _spawn()
func _set_count(v): count = v; _spawn()
func _set_extents(v): extents = v; _spawn()
func _set_min_scale(v): min_scale = v; _spawn()
func _set_max_scale(v): max_scale = v; _spawn()
func _set_offset(v): height_offset = v; _spawn()
func _set_align(v): align_to_normal = v; _spawn()
func _on_force_update(v): if v: _spawn(); force_update = false

func _ready():
	if not Engine.is_editor_hint():
		_spawn()

func _spawn():
	if not is_inside_tree() or not multimesh:
		return
	
	if not target_surface:
		print("⚠️ Chưa kéo MeshInstance3D (Mặt đất) vào ô Target Surface!")
		return

	# Lấy Mesh Resource từ Node
	var mesh_data = target_surface.mesh
	if not mesh_data:
		print("⚠️ Node mặt đất không có Mesh bên trong!")
		return

	# Chuẩn bị MultiMesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = count
	
	# Lấy danh sách các mặt tam giác (Faces) của Mesh đất
	# Hàm này trả về mảng các Vector3 (Local Space của Mesh đất)
	var faces = mesh_data.get_faces()
	var face_count = faces.size() / 3
	
	if face_count == 0:
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var valid_instances = 0
	var attempts = 0
	var max_attempts = count * 5 # Giới hạn số lần thử để không treo máy nếu Extents quá bé
	
	# Vòng lặp tìm điểm
	while valid_instances < count and attempts < max_attempts:
		attempts += 1
		
		# 1. Chọn ngẫu nhiên 1 tam giác trên bề mặt Mesh
		var tri_idx = rng.randi_range(0, face_count - 1) * 3
		var a = faces[tri_idx]
		var b = faces[tri_idx + 1]
		var c = faces[tri_idx + 2]
		
		# 2. Chọn ngẫu nhiên 1 điểm TRONG tam giác đó (Barycentric)
		var r1 = rng.randf()
		var r2 = rng.randf()
		if r1 + r2 > 1.0:
			r1 = 1.0 - r1
			r2 = 1.0 - r2
			
		var local_pos_on_mesh = a + (b - a) * r1 + (c - a) * r2
		
		# 3. Chuyển đổi tọa độ: Mesh Local -> Global -> Spawner Local
		# Để so sánh với Extents (vốn được tính từ tâm Spawner)
		var global_pos = target_surface.to_global(local_pos_on_mesh)
		var spawner_local_pos = to_local(global_pos)
		
		# 4. KIỂM TRA HÌNH VUÔNG (Logic quan trọng của bạn)
		# Chỉ lấy nếu X và Z nằm trong phạm vi Extents
		if abs(spawner_local_pos.x) <= extents.x and abs(spawner_local_pos.z) <= extents.y:
			
			# -- TÌM ĐƯỢC ĐIỂM HỢP LỆ --
			var t = Transform3D()
			
			# Chỉnh độ cao (Y)
			spawner_local_pos.y += height_offset
			t.origin = spawner_local_pos
			
			# Xoay theo pháp tuyến bề mặt (Normal)
			if align_to_normal:
				# Tính pháp tuyến của tam giác
				var normal = (b - a).cross(c - a).normalized()
				# Chuyển pháp tuyến sang hệ tọa độ của Spawner
				# (Cần dùng basis để xoay vector hướng)
				var global_normal = target_surface.global_transform.basis * normal
				var local_normal = global_transform.basis.inverse() * global_normal
				local_normal = local_normal.normalized()
				
				var up = Vector3.UP
				var axis = up.cross(local_normal).normalized()
				var angle = up.angle_to(local_normal)
				if axis.length() > 0.001:
					t = t.rotated(axis, angle)
			
			# Xoay ngẫu nhiên quanh trục Y
			t = t.rotated(Vector3.UP, rng.randf_range(-PI, PI))
			
			# Scale
			var s = rng.randf_range(min_scale, max_scale)
			t = t.scaled(Vector3(s, s, s))
			
			multimesh.set_instance_transform(valid_instances, t)
			valid_instances += 1
	
	# Nếu không tìm đủ điểm (do extents quá bé hoặc đặt lệch chỗ)
	if valid_instances < count:
		print("⚠️ Chỉ rải được ", valid_instances, "/", count, " cây. (Có thể do Extents quá nhỏ so với diện tích Mesh hoặc vị trí Spawner không nằm trùng Mesh)")
		# Ẩn các instance thừa
		for i in range(valid_instances, count):
			multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -9999, 0)))
	else:
		print("✅ Đã rải đủ ", count, " cây bám bề mặt Mesh trong vùng hình vuông.")
