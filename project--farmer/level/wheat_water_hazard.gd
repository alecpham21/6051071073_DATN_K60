extends Area3D


func _ready():
	body_entered.connect(_on_body_entered)

# WaterHazard.gd
func _on_body_entered(body: Node3D):
	if body is Player:
		print("Tõm! Té mương!")
		
		var safe_x = body.last_safe_position.x
		var safe_y = body.last_safe_position.y
		
		var fixed_respawn_pos = Vector3(safe_x, safe_y + 1.0, 0.0) 
		
		body.global_position = fixed_respawn_pos
		body.velocity = Vector3.ZERO
		
		PlayerData.add_dirt_to_outfit(100.0)
