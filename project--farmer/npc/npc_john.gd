extends CharacterBody3D

@export var timeline_name: String = "timeline_npc_john"
@export_group("Teleport Settings")
@export_file("*.tscn") var target_farm_scene: String
@export var target_spawn_pos: Vector3
@export_group("Unlock Door Interaction")
@export var door_to_unlock: InteractArea

var is_cutscene_moving: bool = false
var cutscene_target_pos: Vector3
var timeline_to_play_after_walk: String = ""
var move_speed: float = 5



@onready var anim_player: AnimationPlayer = $UncleJohn/AnimationPlayer

var player_in_range: bool = false

func _ready():
	
	if GameData.john_has_left:
		queue_free()
		return

	var area = $InteractArea
	
	if area:
		area.body_entered.connect(_on_interact_area_body_entered)
		area.body_exited.connect(_on_interact_area_body_exited)
	else:
		printerr("Lỗi: Không tìm thấy node InteractArea!")

	anim_player.play("IdlePose")
	
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _input(event):
	if player_in_range and Input.is_action_just_pressed("interact"):
		
		if Dialogic.current_timeline == null:
			Dialogic.start(timeline_name)
			anim_player.play("Interacted")
			get_viewport().set_input_as_handled()

func _on_interact_area_body_entered(body):
	if body is Player:
		player_in_range = true
		print("Gặp bác John! Bấm E để nói chuyện.")

func start_cutscene_approach(target_pos: Vector3, tl_name: String):
	cutscene_target_pos = target_pos
	# Giữ độ cao Y của NPC bằng độ cao hiện tại (tránh bị chúi xuống đất hoặc bay lên)
	cutscene_target_pos.y = global_position.y 
	
	timeline_to_play_after_walk = tl_name
	is_cutscene_moving = true
	
	# Đổi animation sang đi bộ (Nhớ đảm bảo bạn có anim tên "Walk" hoặc đổi tên ở đây)
	if anim_player.has_animation("john_walk"):
		anim_player.play("john_walk")
	else:
		print("⚠️ NPC thiếu animation 'Walk', đang dùng tạm IdlePose")

func _on_interact_area_body_exited(body):
	if body is Player:
		player_in_range = false

func _physics_process(delta):
	if is_cutscene_moving:
		var direction = (cutscene_target_pos - global_position).normalized()
		var distance = global_position.distance_to(cutscene_target_pos)
		
		# Nếu khoảng cách còn xa (> 0.1m) thì đi tiếp
		if distance > 0.1:
			velocity = direction * move_speed
			look_at(cutscene_target_pos, Vector3.UP)
			rotation.x = 0 
			rotation.z = 0
			move_and_slide()
		else:
			# Đã đến nơi -> Dừng lại
			is_cutscene_moving = false
			velocity = Vector3.ZERO
			anim_player.play("IdlePose")
			
			player_in_range = true 
			# ---------------------
			
			if Dialogic.current_timeline == null:
				Dialogic.start(timeline_to_play_after_walk)
				anim_player.play("Interacted")

func _on_timeline_ended():
	if GState.is_ui():
		GState.play()

func _on_dialogic_signal(argument: String):
	if not player_in_range and not GState.is_ui(): return
	match argument:
		"action1":
			anim_player.play("Interacted_End")
			
		"end_talk":
			anim_player.play("Idle_Pose_ver2")
			print("🚌Lên xe!")
			
			if target_farm_scene != "":
				SceneTransition.change_scene(target_farm_scene, target_spawn_pos)
			if door_to_unlock:
				door_to_unlock.unlock()
				print("🏡 Bác John: Chìa khóa đây, cháu vào nhà đi.")
				
