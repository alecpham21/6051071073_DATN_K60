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

@export_group("Precision Fix")
@export var fence_mesh_native_width: float = 1.0 
@export var gate_mesh_native_width: float = 1.0
@export var overlap_offset: float = 0.0 

func generate_fences(ground_gen: Node, extents: Vector2i):
	for child in get_children():
		child.queue_free()
		
	if not fence_scene or not ground_gen: return
	
	var spacing = ground_gen.renderer.spacing
	
	var g_min_x = -float(padding_expansion)
	var g_max_x = float(extents.x + padding_expansion)
	var g_min_z = -float(padding_expansion)
	var g_max_z = float(extents.y + padding_expansion)
	
	var side_center_x = (g_min_x + g_max_x) / 2.0
	var side_center_z = (g_min_z + g_max_z) / 2.0

	var fill_gap = func(from_t: float, to_t: float, fixed_t: float, is_horz: bool):
		var total_len_tiles = to_t - from_t
		if total_len_tiles <= 0.05: return 
		
		var count = max(1, round(total_len_tiles / tiles_per_fence))
		var segment_len_tiles = total_len_tiles / count
		
		for i in range(count):
			var t_center = from_t + (i * segment_len_tiles) + (segment_len_tiles / 2.0)
			var f = fence_scene.instantiate()
			add_child(f)
			
			var offset_x = (float(extents.x) * spacing) / 2.0 - (spacing / 2.0)
			var offset_z = (float(extents.y) * spacing) / 2.0 - (spacing / 2.0)
			
			var wx = (t_center * spacing) - offset_x if is_horz else (fixed_t * spacing) - offset_x
			var wz = (fixed_t * spacing) - offset_z if is_horz else (t_center * spacing) - offset_z
			
			if is_horz:
				f.rotation_degrees.y = 90 if fixed_t < (g_min_z + g_max_z)/2.0 else -90
			else:
				f.rotation_degrees.y = 0 if fixed_t < (g_min_x + g_max_x)/2.0 else 180
				
			f.global_position = Vector3(wx, 0, wz) + fence_offset
			
			var final_w = (segment_len_tiles * spacing) + overlap_offset
			f.scale = Vector3(final_w / fence_mesh_native_width, fence_scale_y, 1.0)

	var process_side = func(start_t: float, end_t: float, fixed_t: float, is_horz: bool, side_enum: Side):
		if gate_side == side_enum and gate_scene:
			var center_t = side_center_x if is_horz else side_center_z
			var half_gate = gate_size_in_tiles / 2.0
			
			var gate_start = center_t - half_gate
			var gate_end = center_t + half_gate
			
			fill_gap.call(start_t, gate_start, fixed_t, is_horz)
			
			var g = gate_scene.instantiate()
			add_child(g)
			var offset_x = (float(extents.x) * spacing) / 2.0 - (spacing / 2.0)
			var offset_z = (float(extents.y) * spacing) / 2.0 - (spacing / 2.0)
			
			var gx = (center_t * spacing) - offset_x if is_horz else (fixed_t * spacing) - offset_x
			var gz = (fixed_t * spacing) - offset_z if is_horz else (center_t * spacing) - offset_z
			
			if is_horz:
				g.rotation_degrees.y = 90 if fixed_t < (g_min_z + g_max_z)/2.0 else -90
			else:
				g.rotation_degrees.y = 0 if fixed_t < (g_min_x + g_max_x)/2.0 else 180
				
			g.global_position = Vector3(gx, 0, gz) + fence_offset
			
			var g_w = (gate_size_in_tiles * spacing) + overlap_offset
			#g.scale = Vector3(g_w / gate_mesh_native_width, 1.0, 1.0)
			if g.has_method("setup_size"):
				g.setup_size(g_w, gate_mesh_native_width)
			else:
				g.scale = Vector3(g_w / gate_mesh_native_width, 1.0, 1.0)
			
			
			fill_gap.call(gate_end, end_t, fixed_t, is_horz)
		else:
			fill_gap.call(start_t, end_t, fixed_t, is_horz)

	process_side.call(g_min_x, g_max_x, g_min_z, true, Side.TOP)
	process_side.call(g_min_x, g_max_x, g_max_z, true, Side.BOTTOM)
	process_side.call(g_min_z, g_max_z, g_min_x, false, Side.LEFT)
	process_side.call(g_min_z, g_max_z, g_max_x, false, Side.RIGHT)
