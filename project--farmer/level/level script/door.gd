extends InteractArea

@export var target_scene_path: String
@export var target_spawn_position: Vector3

func _ready():
	self.interacted.connect(on_player_interact)
	
func on_player_interact():
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
