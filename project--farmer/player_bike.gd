extends CharacterBody3D

# --- KHAI BÁO ---
# Chú ý: Sau khi bật Editable Children, ông kiểm tra xem node AnimationPlayer nằm ở đâu
# Thường nó sẽ là $Bike1/AnimationPlayer
@onready var anim_bike = $Bike1/AnimationPlayer
@onready var anim_char = $FarmerVer2/AnimationPlayer

const SPEED = 5.0
const ACCEL = 10.0

func _physics_process(delta):
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		# --- DI CHUYỂN ---
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCEL * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCEL * delta)
		
		# Xoay mặt theo hướng đi (nếu muốn)
		if direction.length() > 0.1:
			var target_pos = position + direction
			look_at(Vector3(target_pos.x, position.y, target_pos.z), Vector3.UP)
		
		# --- GỌI ANIMATION ---
		# Thay "Cycling_Bike" và "Human_Cycling" bằng tên thật ông đặt trong Blender
		play_anim("Cycling", "Human_Cycling") 
		
	else:
		# --- DỪNG LẠI ---
		velocity.x = move_toward(velocity.x, 0, ACCEL * delta)
		velocity.z = move_toward(velocity.z, 0, ACCEL * delta)
		
		play_anim("RESET", "RESET") # Hoặc "Idle"

	move_and_slide()

func play_anim(bike_anim, char_anim):
	# Code này giúp animation không bị reset lại liên tục mỗi frame
	if anim_bike.has_animation(bike_anim) and anim_bike.current_animation != bike_anim:
		anim_bike.play(bike_anim)
	
	if anim_char.has_animation(char_anim) and anim_char.current_animation != char_anim:
		anim_char.play(char_anim)
