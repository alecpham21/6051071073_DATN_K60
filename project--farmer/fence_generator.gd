extends Node3D
class_name FenceGenerator

enum Side { TOP, BOTTOM, LEFT, RIGHT }

@export var fence_scene: PackedScene
@export var gate_scene: PackedScene
@export var fence_offset: Vector3 = Vector3(0, 0, 0)
@export var gate_side = Side.BOTTOM
@export var padding_expansion: int = 3

@export_group("Settings")
@export var fence_scale_y: float = 1.0
@export var tiles_per_fence: float = 3.0
@export var gate_size_in_tiles: float = 3.0

func generate_fences(ground_gen: Node, extents: Vector2i):
	for child in get_children():
		child.queue_free()
		
	if not fence_scene: return
	
	var spacing = ground_gen.renderer.spacing
	

	var grid_min_x = -padding_expansion
	var grid_max_x = extents.x + padding_expansion
	var grid_min_z = -padding_expansion
	var grid_max_z = extents.y + padding_expansion
	

	var center_x = (grid_min_x + grid_max_x) / 2.0
	var center_z = (grid_min_z + grid_max_z) / 2.0
	

	var fill_gap = func(from_t: float, to_t: float, fixed_t: float, is_horz: bool):
		var total_len = to_t - from_t
		if total_len <= 0.01: return
		
		var count = max(1, round(total_len / tiles_per_fence))
		
		var segment_len = total_len / count

		var scale_factor = segment_len / tiles_per_fence * fence_scene.instantiate().scale.x # Lấy scale gốc nếu có
		var final_scale_x = segment_len 
		
		for i in range(count):
			var t_center = from_t + (i * segment_len) + (segment_len / 2.0)
			
			var f = fence_scene.instantiate()
			add_child(f)
			
			var wx = 0.0
			var wz = 0.0
			
			var offset_x = (extents.x * spacing) / 2.0 - (spacing / 2.0)
			var offset_z = (extents.y * spacing) / 2.0 - (spacing / 2.0)
			
			if is_horz:
				wx = (t_center * spacing) - offset_x
				wz = (fixed_t * spacing) - offset_z
				f.rotation_degrees.y = 90 if fixed_t < 0 else -90 # Quay mặt vào trong
			else:
				wx = (fixed_t * spacing) - offset_x
				wz = (t_center * spacing) - offset_z
				f.rotation_degrees.y = 0 if fixed_t < 0 else 180
				
			f.global_position = Vector3(wx, 0, wz) + fence_offset
			

			f.scale = Vector3(segment_len, fence_scale_y, 1)

	var process_side = func(start_t, end_t, fixed_t, is_horz, side_enum):
		if gate_side == side_enum and gate_scene:
			var gate_center_t = center_x if is_horz else center_z
			var half_gate = gate_size_in_tiles / 2.0
			
			var gate_start = gate_center_t - half_gate
			var gate_end = gate_center_t + half_gate
			
			fill_gap.call(start_t, gate_start, fixed_t, is_horz)
			
			var g = gate_scene.instantiate()
			add_child(g)
			var offset_x = (extents.x * spacing) / 2.0 - (spacing / 2.0)
			var offset_z = (extents.y * spacing) / 2.0 - (spacing / 2.0)
			var gx = 0.0
			var gz = 0.0
			if is_horz:
				gx = (gate_center_t * spacing) - offset_x
				gz = (fixed_t * spacing) - offset_z
				g.rotation_degrees.y = 90 if fixed_t < 0 else -90
			else:
				gx = (fixed_t * spacing) - offset_x
				gz = (gate_center_t * spacing) - offset_z
				g.rotation_degrees.y = 0 if fixed_t < 0 else 180
			g.global_position = Vector3(gx, 0, gz) + fence_offset
			g.scale = Vector3(1, 1, 1) 
			
			fill_gap.call(gate_end, end_t, fixed_t, is_horz)
			
		else:
			fill_gap.call(start_t, end_t, fixed_t, is_horz)

	process_side.call(grid_min_x, grid_max_x, grid_min_z, true, Side.TOP)
	

	process_side.call(grid_min_x, grid_max_x, grid_max_z, true, Side.BOTTOM)
	
	
	process_side.call(grid_min_z, grid_max_z, grid_min_x, false, Side.LEFT)
	
	process_side.call(grid_min_z, grid_max_z, grid_max_x, false, Side.RIGHT)

	print("🚧 FenceGenerator: Đã xây xong (Auto Scale & Gate Cut)")
