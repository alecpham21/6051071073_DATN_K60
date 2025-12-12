extends Area3D

@export var npc_john: CharacterBody3D
@export var timeline_name: String = "timeline_npc_john"

var has_triggered: bool = false

func _ready():
	# Kết nối tín hiệu khi có vật thể bước vào vùng này
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if has_triggered or not body is Player:
		return
	
	print("Cutscene bắt đầu!")
	has_triggered = true # Đánh dấu để không lặp lại
	
	GState.ui()
	body.velocity = Vector3.ZERO 
	if body.anim: body.anim.play("IdlePose")
	
	var target_pos = body.global_position
	var direction_to_npc = (npc_john.global_position - body.global_position).normalized()
	target_pos += direction_to_npc * 1.5 
	
	if npc_john.has_method("start_cutscene_approach"):
		npc_john.start_cutscene_approach(target_pos, timeline_name)
	else:
		printerr("Lỗi: NPC John chưa có hàm start_cutscene_approach!")
