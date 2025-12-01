extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var anim = $AnimationPlayer

func _ready():
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Hàm đóng màn hình (Giữ nguyên)
func change_scene(target_path: String, spawn_pos: Vector3):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	get_tree().paused = true
	
	anim.play("fade_in")
	await anim.animation_finished
	
	PlayerData.next_spawn_position = spawn_pos
	PlayerData.used_spawn_position = false
	
	# Đợi 1 xíu giả vờ load (nếu thích), ko thì bỏ dòng này cũng đc
	await get_tree().create_timer(0.5, true, false, true).timeout
	
	get_tree().change_scene_to_file(target_path)

# Hàm mở màn hình (SỬA LẠI LOGIC TẠI ĐÂY)
func reveal_scene():
	# 1. UNPAUSE NGAY LẬP TỨC
	# Để game chạy, vật lý chạy, camera tự bay về đúng chỗ
	get_tree().paused = false 
	
	# 2. Vẫn giữ màn hình đen, chờ 0.2s cho camera ổn định
	# (Lúc này màn đen che hết cái cảnh camera đang giật)
	await get_tree().create_timer(0.2).timeout 
	
	# 3. Fade Out từ từ
	anim.play("fade_out")
	await anim.animation_finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
