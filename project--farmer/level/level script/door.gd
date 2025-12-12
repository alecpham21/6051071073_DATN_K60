extends InteractArea

@export var door_id: String = ""
@export var target_scene_path: String
@export var target_spawn_position: Vector3
@export var is_locked: bool = false
@export var locked_message: String = "Cửa khóa rồi!"

@export_group("Special Events")
@export var trigger_john_leave: bool = false

func _ready():

	interacted.connect(on_player_interact)
	
	if door_id != "" and GameData.check_door_unlocked(door_id):
		is_locked = false
	
func on_player_interact():
	if is_locked:
		print(locked_message) 
		return
	
	if trigger_john_leave:
		GameData.john_has_left = true
		print("👋 Đã đánh dấu: Bác John sẽ rời đi.")
	
	
	if target_scene_path.is_empty():
		push_error("Door target scene is empty")
		return

	#Save Game before doing it
	var current_level = get_tree().current_scene
	if current_level.has_method("save_level_state"):
		print("🚪 Door: Đang lưu data trước khi chuyển cảnh...")
		current_level.save_level_state()
	
	#Call AUTOLOAD
	SceneTransition.change_scene(target_scene_path, target_spawn_position)


func unlock():
	is_locked = false
	print("🔓 Cửa đã mở!")
	if door_id != "":
		GameData.save_door_unlocked(door_id)
