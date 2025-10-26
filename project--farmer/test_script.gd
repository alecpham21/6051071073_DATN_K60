extends Node3D

func _ready() -> void:
	add_child(TimerKit.generate_timer(1, func():
		var temp:Array = GridKit.get_at_pos(global_position, get_world_3d().direct_space_state)
		if !temp.is_empty(): print(temp[0].collider.get_parent()), false))
