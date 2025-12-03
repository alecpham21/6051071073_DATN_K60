extends MeshInstance3D

@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@onready var interact_area: InteractArea = $InteractArea

# Biến trạng thái
var is_open: bool = false
# Biến ghi nhớ: Nãy mình đã mở cái cửa bằng animation nào?
var last_open_anim_name: String = "" 

func _ready() -> void:
	if interact_area:
		interact_area.interacted.connect(toggle_gate)

func toggle_gate():
	if anim_player.is_playing(): return

	if is_open:
		close_gate()
	else:
		open_gate()

func open_gate():
	if not PlayerData.player: return
	
	# 1. Tính toán hướng
	var player_pos = PlayerData.player.global_position
	var gate_pos = global_position
	var dot = gate_pos.direction_to(player_pos).dot(global_transform.basis.x)
	
	# 2. Chọn animation mở
	var anim_to_play = ""
	
	if dot < 0: 
		anim_to_play = "Open_front" # Mở ra trước
	else:
		anim_to_play = "Open_back" # Mở ra sau
	
	# 3. Chạy và GHI NHỚ lại
	anim_player.play(anim_to_play)
	last_open_anim_name = anim_to_play # <--- Lưu lại cái tên này để lát còn biết đường đóng
	is_open = true

func close_gate():
	# Lúc đóng, ta không cần tính toán vị trí người chơi nữa
	# Ta chỉ cần tua ngược lại cái animation nãy vừa mở là xong
	
	if last_open_anim_name == "Open_front":
		# Nếu nãy mở front -> Giờ đóng front (Tua ngược hoặc chạy anim Close tương ứng)
		anim_player.play_backwards("Open_front") 
		# Hoặc nếu ông có anim riêng: anim_player.play("Close_front")
		
	elif last_open_anim_name == "Open_back":
		# Nếu nãy mở back -> Giờ đóng back
		anim_player.play_backwards("Open_back")
		# Hoặc nếu ông có anim riêng: anim_player.play("Close_back")
	
	else:
		# Trường hợp dự phòng (ví dụ cửa mở sẵn từ đầu game)
		anim_player.play("Default") 
		
	is_open = false
