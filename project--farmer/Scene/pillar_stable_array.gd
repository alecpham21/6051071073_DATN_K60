@tool
extends Node3D

## Scene của vật thể bạn muốn tạo array (kéo file .tscn vào đây)
@export var item_scene: PackedScene

## Số lượng vật thể muốn tạo
@export var count: int = 5:
	set(value):
		count = max(0, value) # Đảm bảo count không bị âm
		_generate_array()

## Khoảng cách (offset) giữa mỗi vật thể
@export var offset: Vector3 = Vector3(0, 0, 5.0):
	set(value):
		offset = value
		_generate_array()

func _ready():
	# Chạy một lần nữa khi game bắt đầu để đảm bảo
	_generate_array()

func _generate_array():
	# 1. Xóa hết các con (trụ) cũ đi để tạo lại
	# Dùng vòng lặp ngược để xóa cho an toàn
	for i in range(get_child_count() - 1, -1, -1):
		var child = get_child(i)
		child.queue_free() # queue_free() an toàn hơn free()

	# 2. Kiểm tra xem đã gán scene khuôn mẫu chưa
	if not item_scene:
		return # Nếu chưa gán thì không làm gì cả

	# 3. Tạo array
	for i in range(count):
		var instance = item_scene.instantiate()
		instance.position = offset * i # Tính toán vị trí
		add_child(instance)
