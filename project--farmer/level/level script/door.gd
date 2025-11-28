extends InteractArea

@export var target_scene_path: String
@export var target_spawn_position: Vector3

func _ready():
	self.interacted.connect(on_player_interact)
	
func on_player_interact():
	if target_scene_path.is_empty():
		push_error("Door target scene is empty bitch")
		return

	# --- [MỚI] BƯỚC QUAN TRỌNG NHẤT: LƯU GAME TRƯỚC KHI ĐI ---
	# 1. Lấy cái scene hiện tại (Chính là cái node World/Level)
	var current_level = get_tree().current_scene
	
	# 2. Kiểm tra xem nó có chức năng save không (tránh crash nếu quên gắn script)
	if current_level.has_method("save_level_state"):
		print("🚪 Door: Đang yêu cầu World lưu dữ liệu...")
		current_level.save_level_state()
	else:
		push_warning("⚠️ Scene hiện tại không có hàm save_level_state! Dữ liệu sẽ không được lưu.")
	# ---------------------------------------------------------

	# Setup vị trí spawn cho màn kế tiếp
	PlayerData.next_spawn_position = target_spawn_position
	PlayerData.used_spawn_position = false
	
	# Chuyển cảnh
	get_tree().change_scene_to_file(target_scene_path)
