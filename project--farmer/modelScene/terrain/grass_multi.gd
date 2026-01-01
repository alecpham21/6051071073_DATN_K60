@tool
extends MultiMeshInstance3D

@export_group("Thiết lập")
# THAY ĐỔI: Giờ là chọn Node MeshInstance3D trong Scene, không kéo file nữa
@export var target_surface: MeshInstance3D 
@export var scatter_mesh: Mesh 

@export_group("Thông số")
@export var instance_count: int = 1000
@export var min_scale: float = 0.8
@export var max_scale: float = 1.2

@export_group("Hành động")
@export var update: bool = false:
	set(value):
		if value:
			_spawn()
			update = false

func _ready():
	if not Engine.is_editor_hint():
		_spawn()

func _spawn():
	# 1. Validate
	if not target_surface:
		print("⚠️ Chưa assign Node mặt đất (Target Surface)!")
		return
	if not target_surface.mesh:
		print("⚠️ Node mặt đất không chứa Mesh Resource nào!")
		return
	if not scatter_mesh:
		print("⚠️ Chưa assign Mesh cỏ (Scatter Mesh)!")
		return

	# 2. Setup MultiMesh
	if not multimesh:
		multimesh = MultiMesh.new()
	
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = scatter_mesh
	multimesh.instance_count = instance_count
	
	# 3. Lấy data từ Node được assign
	# get_faces() lấy toạ độ Local của Mesh gốc
	var faces = target_surface.mesh.get_faces()
	var face_count = faces.size() / 3
	
	if face_count == 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(instance_count):
		# A. Chọn tam giác ngẫu nhiên
		var tri_idx = rng.randi_range(0, face_count - 1) * 3
		var a = faces[tri_idx]
		var b = faces[tri_idx + 1]
		var c = faces[tri_idx + 2]
		
		# B. Random điểm trong tam giác (Barycentric)
		var r1 = rng.randf()
		var r2 = rng.randf()
		if r1 + r2 > 1.0:
			r1 = 1.0 - r1
			r2 = 1.0 - r2
			
		var local_pos = a + (b - a) * r1 + (c - a) * r2
		
		# C. QUAN TRỌNG: Chuyển đổi hệ toạ độ
		# Mesh -> World -> Spawner Local
		# Giúp cỏ bám đúng vị trí dù đất bị xoay hay dịch chuyển
		var world_pos = target_surface.to_global(local_pos)
		var final_pos = to_local(world_pos)
		
		# D. Tạo Transform
		var t = Transform3D()
		t.origin = final_pos
		
		# Xoay & Scale ngẫu nhiên
		t = t.rotated(Vector3.UP, rng.randf_range(-PI, PI))
		var s = rng.randf_range(min_scale, max_scale)
		t = t.scaled(Vector3(s, s, s))
		
		multimesh.set_instance_transform(i, t)
		
	print("✅ Đã rải ", instance_count, " cây lên node ", target_surface.name)
