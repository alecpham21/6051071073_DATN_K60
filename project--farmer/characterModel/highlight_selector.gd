extends MeshInstance3D

@export var block_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var box_color: Color = Color(1, 1, 0, 0.25) # màu vàng nhẹ, hơi trong suốt

func _ready():
	# Nếu chưa có child box thì tạo thêm
	if not has_node("HighlightBox"):
		var box = MeshInstance3D.new()
		box.name = "HighlightBox"

		# Tạo mesh dạng box đúng kích thước block
		var box_mesh = BoxMesh.new()
		box_mesh.size = block_size
		box.mesh = box_mesh

		# Tạo material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = box_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.no_depth_test = true  # để không bị che
		box.material_override = mat

		# Đặt vị trí nó đúng ở giữa block (hơi nâng lên nếu cần)
		box.position = Vector3(0, block_size.y / 2.0, 0)

		add_child(box)
