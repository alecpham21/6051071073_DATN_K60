extends CharacterBody3D

@export var timeline_name: String = "timeline_npc_jack"

@export_group("Behavior Settings")
@export var is_auto_approach_enabled: bool = false # <--- Ở Farm thì KHÔNG tích cái này. Ở Level đầu thì TÍCH vào.

@export_group("Quest Settings")
@export var quest_to_complete_id: String = "talk_to_jack"
@export var quest_to_start_id: String = ""

@export_group("Teleport Settings")
@export_file("*.tscn") var target_farm_scene: String
@export var target_spawn_pos: Vector3

@export_group("Unlock Door Interaction")
@export var door_id_to_unlock: String = ""

var is_cutscene_moving: bool = false
var cutscene_target_pos: Vector3
var timeline_to_play_after_walk: String = ""
var move_speed: float = 3

@onready var anim_player: AnimationPlayer = $UncleJack/AnimationPlayer
var player_in_range: bool = false
var has_auto_triggered: bool = false # Để đảm bảo chỉ tự lao tới 1 lần duy nhất

func _ready():
	if GameData.john_has_left:
		queue_free()
		return
	
	if quest_to_complete_id != "" and QuestManager.check_status(quest_to_complete_id) == "available":
		QuestManager.start_quest(quest_to_complete_id)
	
	var area = $InteractArea
	if area:
		area.body_entered.connect(_on_interact_area_body_entered)
		area.body_exited.connect(_on_interact_area_body_exited)
		if area.has_signal("interacted"):
			area.interacted.connect(_on_interacted)
	
	anim_player.play("IdlePose")
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _input(event):
	# QUAN TRỌNG: Chỉ nhận lệnh khi người chơi bấm nút "interact" (ví dụ: E, Enter, Space...)
	# Bạn cần vào Project Settings -> Input Map để đảm bảo đã có action tên là "interact"
	if player_in_range and not is_cutscene_moving and Dialogic.current_timeline == null:
		if event.is_action_pressed("interact"): 
			_start_dialogue()
			get_viewport().set_input_as_handled()

func _on_interacted():
	# Dành cho trường hợp dùng nút UI hoặc Raycast
	if not is_cutscene_moving and Dialogic.current_timeline == null:
		_start_dialogue()

func _on_interact_area_body_entered(body):
	if body is Player:
		player_in_range = true
		
		# Chỉ tự lao tới nếu CÓ bật trong Inspector và CHƯA từng làm vậy trước đây
		if is_auto_approach_enabled and not has_auto_triggered:
			start_cutscene_approach(body.global_position, timeline_name)
			has_auto_triggered = true

func _on_interact_area_body_exited(body):
	if body is Player:
		player_in_range = false

func start_cutscene_approach(target_pos: Vector3, tl_name: String):
	if Dialogic.current_timeline != null: return
	
	cutscene_target_pos = target_pos
	cutscene_target_pos.y = global_position.y
	timeline_to_play_after_walk = tl_name
	is_cutscene_moving = true
	
	if anim_player.has_animation("Walk"):
		anim_player.play("Walk")

func _physics_process(delta):
	if is_cutscene_moving:
		var direction = (cutscene_target_pos - global_position).normalized()
		var distance = global_position.distance_to(cutscene_target_pos)
		
		if distance > 1.5:
			velocity = direction * move_speed
			look_at(cutscene_target_pos, Vector3.UP)
			rotate_y(PI) # Giữ nguyên fix lỗi nhìn ngược
			rotation.x = 0
			rotation.z = 0
			move_and_slide()
		else:
			is_cutscene_moving = false
			velocity = Vector3.ZERO
			anim_player.play("IdlePose")
			_start_dialogue(timeline_to_play_after_walk)

func _start_dialogue(tl: String = ""):
	var target_tl = tl if tl != "" else timeline_name
	if Dialogic.current_timeline == null:
		Dialogic.start(target_tl)
		anim_player.play("Interacted")

func _on_timeline_ended():
	if GState.is_ui():
		GState.play()

func _on_dialogic_signal(argument: String):
	if not player_in_range and not GState.is_ui(): return
	
	match argument:
		"action1":
			anim_player.play("Interacted_End")
		"end_talk", "end_talk_farm":
			if quest_to_complete_id != "":
				QuestManager.complete_quest(quest_to_complete_id)
			
			anim_player.play("Idle_Pose_ver2")
			
			if quest_to_start_id != "":
				QuestManager.start_quest(quest_to_start_id)
				QuestManager.start_trade_contract("corn", 3, 2)

			if door_id_to_unlock != "":
				GameData.save_door_unlocked(door_id_to_unlock)
				GameData.request_unlock_door.emit(door_id_to_unlock)
				return
			
			if target_farm_scene != "":
				SceneTransition.change_scene(target_farm_scene, target_spawn_pos)
