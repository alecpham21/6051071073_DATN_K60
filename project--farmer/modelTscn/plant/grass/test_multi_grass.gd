@tool
extends MultiMeshInstance3D

@export_category("Cấu hình Cỏ")
@export var instance_count: int = 3000
@export var scale_min: float = 0.8
@export var scale_max: float = 1.2

@export_category("Công cụ")
# Tích vào đây để tạo lại cỏ (dùng khi bạn vừa scale mặt đất xong)
@export var update_grass: bool = false:
	set(value):
		spawn_grass()

func _ready():
	# Chờ 1 chút để các node load xong hết transform
	await get_tree().create_timer(0.1).timeout
	spawn_grass()

func spawn_grass():
	# 1. TÌM MESH CHA (LOGIC TỰ ĐỘNG)
	var target_node = get_parent()
	
	# Leo lên tìm cha là MeshInstance3D (đề phòng cấu trúc lồng nhau)
	var safety = 0
	while target_node and not target_node is MeshInstance3D and safety < 5:
		target_node = target_node.get_parent()
		safety += 1
	
	if not target_node or not target_node is MeshInstance3D:
		print("Chưa tìm thấy cha là MeshInstance3D!")
		return

	var target_mesh = target_node.mesh
	if not target_mesh:
		return

	# 2. TÍNH TOÁN DIỆN TÍCH (để rải đều không bị bu cục)
	# Lưu ý: get_faces trả về tọa độ cục bộ (Local) của Mesh gốc
	var faces = target_mesh.get_faces()
	var face_count = faces.size() / 3
	
	if face_count == 0: return

	# Tính diện tích các mặt để làm trọng số (Weighted Random)
	var cumulative_areas = []
	var total_area = 0.0
	
	# Lấy scale hiện tại của cha để tính diện tích thực tế chuẩn xác hơn
	var parent_scale = target_node.global_transform.basis.get_scale()
	
	for i in range(face_count):
		var a = faces[i*3] * parent_scale
		var b = faces[i*3+1] * parent_scale
		var c = faces[i*3+2] * parent_scale
		var area = (b - a).cross(c - a).length() * 0.5
		total_area += area
		cumulative_areas.append(total_area)

	# 3. TIẾN HÀNH RẢI CỎ
	multimesh.instance_count = 0
	multimesh.instance_count = instance_count
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(instance_count):
		# --- A. CHỌN VỊ TRÍ TRÊN MESH GỐC ---
		var random_area = rng.randf_range(0.0, total_area)
		var face_idx = _binary_search(cumulative_areas, random_area)
		
		var a = faces[face_idx * 3]
		var b = faces[face_idx * 3 + 1]
		var c = faces[face_idx * 3 + 2]
		
		# Random điểm trong tam giác
		var r1 = rng.randf()
		var r2 = rng.randf()
		if r1 + r2 > 1:
			r1 = 1 - r1
			r2 = 1 - r2
			
		var local_pos_on_mesh = a + r1 * (b - a) + r2 * (c - a)
		
		# --- B. CHUYỂN ĐỔI TỌA ĐỘ (QUAN TRỌNG NHẤT) ---
		# Bước 1: Chuyển điểm trên Mesh -> Tọa độ thế giới (Global)
		var global_pos = target_node.to_global(local_pos_on_mesh)
		
		# Bước 2: Chuyển từ Global -> Tọa độ cục bộ của Node Cỏ (Self)
		# Việc này giúp cỏ nằm đúng vị trí dù cha con có scale lệch nhau thế nào
		var final_pos = to_local(global_pos)
		
		# --- C. TRANSFORM ---
		var trans := Transform3D()
		
		# Xoay (Chỉ xoay trục Y)
		var random_angle = rng.randf_range(-PI, PI)
		trans = trans.rotated(Vector3.UP, random_angle)
		
		# Scale
		var random_scale = rng.randf_range(scale_min, scale_max)
		trans = trans.scaled(Vector3(random_scale, random_scale, random_scale))
		
		# Gán vị trí
		trans.origin = final_pos
		
		multimesh.set_instance_transform(i, trans)

# Hàm tìm kiếm nhị phân để chạy nhanh hơn
func _binary_search(arr, value) -> int:
	var low = 0
	var high = arr.size() - 1
	while low < high:
		var mid = (low + high) / 2
		if value > arr[mid]:
			low = mid + 1
		else:
			high = mid
	return low
