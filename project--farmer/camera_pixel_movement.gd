extends Camera3D

# Cấu hình chiều cao màn hình ảo (game pixel thường là 180, 240, 270, 360...)
@export var target_virtual_height: float = 180.0

# Biến để SubViewportContainer đọc
var snap_error: Vector2 = Vector2.ZERO
var texel_size: float = 1.0

func _process(delta: float) -> void:
	# 1. Tính kích thước 1 pixel trong thế giới 3D
	# SỬA LỖI: dùng size (float) trực tiếp, không dùng size.y
	texel_size = size / target_virtual_height
	
	# 2. Lấy vị trí toàn cục hiện tại (đang mượt do SpringArm điều khiển)
	var current_global_pos = global_position
	
	# 3. Tính vị trí Snap (làm tròn theo lưới texel_size)
	var snapped_pos = current_global_pos.snapped(Vector3.ONE * texel_size)
	
	# 4. Tính độ lệch (Error) để gửi cho ViewportContainer
	# Lấy phần lẻ bị mất đi khi làm tròn
	var diff_v3 = current_global_pos - snapped_pos
	snap_error = Vector2(diff_v3.x, diff_v3.y)
	
	# 5. ÉP CAMERA VÀO LƯỚI
	# Ghi đè vị trí render của camera thành vị trí đã snap
	global_position = snapped_pos
