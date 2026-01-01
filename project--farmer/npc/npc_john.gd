extends CharacterBody3D

@export var timeline_name: String = "timeline_npc_john"

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
		print("Player in range.")

func start_cutscene_approach(target_pos: Vector3, tl_name: String):
	cutscene_target_pos = target_pos
	cutscene_target_pos.y = global_position.y 
	
	timeline_to_play_after_walk = tl_name
	is_cutscene_moving = true
	
	if anim_player.has_animation("Moon_Walk"):
		anim_player.play("Moon_Walk")
	else:
		print("using IdlePose")

func _on_interact_area_body_exited(body):
	if body is Player:
		player_in_range = false

func _physics_process(delta):
	if is_cutscene_moving:
		var direction = (cutscene_target_pos - global_position).normalized()
		var distance = global_position.distance_to(cutscene_target_pos)
		
		if distance > 0.1:
			velocity = direction * move_speed
			look_at(cutscene_target_pos, Vector3.UP)
			rotation.x = 0 
			rotation.z = 0
			move_and_slide()
		else:
			is_cutscene_moving = false
			velocity = Vector3.ZERO
			anim_player.play("IdlePose")
			
			player_in_range = true 
			
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
			
		"end_talk", "end_talk_farm":
			
			if quest_to_complete_id != "":
				QuestManager.complete_quest(quest_to_complete_id)
			
			anim_player.play("Idle_Pose_ver2")
			
			if quest_to_start_id != "":
				QuestManager.start_quest(quest_to_start_id)
				print("📜 Đã nhận nhiệm vụ: ", quest_to_start_id)

			if door_id_to_unlock != "":
				# 1. Lưu vào data để lần sau load game cửa vẫn mở
				GameData.save_door_unlocked(door_id_to_unlock)
				
				# 2. Bắn tín hiệu để nếu cửa đang có trên màn hình thì mở ngay lập tức
				GameData.request_unlock_door.emit(door_id_to_unlock)
				
				print("NPC đã mở khóa cửa ID: ", door_id_to_unlock)
				return
			
			if target_farm_scene != "":
				SceneTransition.change_scene(target_farm_scene, target_spawn_pos)
				
