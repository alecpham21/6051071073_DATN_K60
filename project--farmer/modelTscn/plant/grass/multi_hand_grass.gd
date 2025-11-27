@tool
extends MultiMeshInstance3D

enum Shape { SQUARE, CIRCLE }
@export var spawn_shape: Shape = Shape.SQUARE

# Kéo cái Mesh (cỏ/đá) vào đây
@export var mesh_mau: Mesh 

@export var instance_count: int = 1000
@export var extents: Vector2 = Vector2(10, 10)
@export var radius: float = 10.0
@export var scale_min: float = 0.8
@export var scale_max: float = 1.2

@export var update: bool = false:
	set(value):
		if value:
			_spawn()
			update = false

func _ready():
	if not Engine.is_editor_hint():
		_spawn()

func _spawn():
	# 1. Tự tạo MultiMesh resource nếu chưa có (đỡ phải tạo tay)
	if not multimesh:
		multimesh = MultiMesh.new()

	# 2. QUAN TRỌNG NHẤT: Reset về 0 trước để mở khóa chỉnh sửa
	multimesh.instance_count = 0
	
	# 3. Nạp Mesh vào (Tránh lỗi is_null)
	if mesh_mau:
		multimesh.mesh = mesh_mau
	else:
		print("⚠️ Chưa kéo Mesh Mẫu vào inspector!")
		return

	# 4. Cài đặt thông số (Lúc này an toàn vì count đang là 0)
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = false
	multimesh.use_custom_data = false
	
	# 5. Bây giờ mới được set số lượng instance
	multimesh.instance_count = instance_count
	
	# --- LOGIC CŨ CỦA ÔNG ---
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(instance_count):
		var x = 0.0
		var z = 0.0
		
		match spawn_shape:
			Shape.SQUARE:
				x = rng.randf_range(-extents.x, extents.x)
				z = rng.randf_range(-extents.y, extents.y)
			Shape.CIRCLE:
				var angle = rng.randf_range(-PI, PI)
				var dist = sqrt(rng.randf()) * radius
				x = cos(angle) * dist
				z = sin(angle) * dist

		var trans := Transform3D()
		
		# Xoay
		var random_angle = rng.randf_range(-PI, PI)
		trans = trans.rotated(Vector3.UP, random_angle)
		
		# Scale
		var random_scale = rng.randf_range(scale_min, scale_max)
		trans = trans.scaled(Vector3(random_scale, random_scale, random_scale))

		# Vị trí
		trans.origin = Vector3(x, 0, z)

		multimesh.set_instance_transform(i, trans)
