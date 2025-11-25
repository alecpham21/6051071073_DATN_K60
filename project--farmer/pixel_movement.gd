extends SubViewportContainer

@onready var camera_node: Camera3D = $SubViewport/SpringArm3D/Camera3D

@onready var original_pos: Vector2 = position

func _process(delta: float) -> void:
	if not camera_node:
		return
		
	var error_in_world = camera_node.snap_error
	var one_pixel_world = camera_node.texel_size
	
	if one_pixel_world > 0:
		var pixel_shift = error_in_world / one_pixel_world
		
		position = original_pos - pixel_shift
