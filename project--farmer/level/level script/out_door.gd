extends Area3D

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn_position: Vector3

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is Player:
		var current_state = body.limbo_hsm.get_active_state()
		
		if current_state is BikingState:
			PlayerData.is_transitioning_with_bike = true
			print("🚲 Đang đi xe đạp qua cửa -> Lưu trạng thái!")
		else:
			PlayerData.is_transitioning_with_bike = false
		
		
		change_level()
		

func change_level():
	if target_scene_path.is_empty():
		push_error("⚠️ Door target scene is empty!")
		return

	var current_level = get_tree().current_scene
	if current_level.has_method("save_level_state"):
		print("🚪 Auto Door: Đang lưu data trước khi chuyển cảnh...")
		current_level.save_level_state()
	
	print("🚪 Auto Door: Đang chuyển sang ", target_scene_path)
	SceneTransition.change_scene(target_scene_path, target_spawn_position)
