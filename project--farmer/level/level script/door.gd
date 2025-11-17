extends InteractArea 

@export var target_scene_path: String
@export var target_spawn_position: Vector3


func _ready():
	self.interacted.connect(on_player_interact)
	
func on_player_interact():
	if target_scene_path.is_empty():
		push_error("Door target scene is empty bitch")
		return
		
	# 1. Báo cho Singleton (PlayerData) biết vị trí spawn mới
	PlayerData.next_spawn_position = target_spawn_position
	PlayerData.used_spawn_position = false # Đặt cờ "chưa dùng"
	
	# 2. Thay đổi scene
	get_tree().change_scene_to_file(target_scene_path)
