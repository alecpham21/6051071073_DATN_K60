extends Camera3D

@export var target_virtual_height: float = 270
@export var snap_group_name: String = "snap" 

# Biến public để Container đọc
var snap_error: Vector2 = Vector2.ZERO
var texel_size: float = 1.0

# Biến nội bộ
var _snap_nodes: Array[Node] = []
var _pre_snapped_positions: Array[Vector3] = []
var _snap_space: Transform3D

func _ready() -> void:
	process_priority = -1
	# Đăng ký hàm trả vị trí cũ sau khi vẽ xong frame
	RenderingServer.frame_post_draw.connect(_revert_snap_objects)

func _process(delta: float) -> void:
	# 1. Tính toán Texel Size
	texel_size = size / target_virtual_height
	
	# 2. Xác định không gian Snap (Dựa trên transform của Camera)
	# Trong Godot, phép nhân Vector3 * Transform3D tương đương việc chuyển sang Local Space
	_snap_space = global_transform
	
	# 3. Snap bản thân Camera trước
	var current_pos = global_position
	# Chuyển vị trí camera sang không gian lưới của chính nó
	var pos_in_snap_space = current_pos * _snap_space
	var snapped_pos_in_snap_space = pos_in_snap_space.snapped(Vector3.ONE * texel_size)
	
	# Tính lỗi (Error) trong không gian 2D của camera
	var diff = snapped_pos_in_snap_space - pos_in_snap_space
	snap_error = Vector2(diff.x, -diff.y) # Đảo Y cho khớp màn hình
	
	# Áp dụng vị trí đã snap cho Camera
	global_position = _snap_space * snapped_pos_in_snap_space
	
	# 4. Snap các vật thể trong Group (Quan trọng)
	_snap_objects()

# Hàm xử lý Group "snap"
func _snap_objects() -> void:
	# Lấy danh sách node trong group
	_snap_nodes = get_tree().get_nodes_in_group(snap_group_name)
	_pre_snapped_positions.resize(_snap_nodes.size())
	
	for i in _snap_nodes.size():
		var node = _snap_nodes[i] as Node3D
		if node:
			# A. Lưu vị trí gốc (để tí nữa trả lại)
			var original_pos = node.global_position
			_pre_snapped_positions[i] = original_pos
			
			# B. Tính toán vị trí snap
			# 1. Chuyển vị trí vật thể sang không gian Camera
			var pos_in_space = original_pos * _snap_space
			
			# 2. Làm tròn theo lưới texel (Snap)
			# Chỉ làm tròn X và Y, giữ nguyên Z (độ sâu)
			var snapped_in_space = pos_in_space.snapped(Vector3(texel_size, texel_size, 0.0))
			# Giữ nguyên độ sâu Z thực tế để tránh lỗi Z-fighting
			snapped_in_space.z = pos_in_space.z 
			
			# 3. Chuyển ngược lại thế giới thực
			node.global_position = _snap_space * snapped_in_space

# Hàm trả lại vị trí cũ (Revert)
func _revert_snap_objects() -> void:
	for i in _snap_nodes.size():
		var node = _snap_nodes[i] as Node3D
		if is_instance_valid(node):
			node.global_position = _pre_snapped_positions[i]
	
	_snap_nodes.clear()
