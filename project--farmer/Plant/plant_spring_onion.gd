extends Plant
class_name SpringOnion

func update_visuals():
	# Ẩn tất cả trước
	if mesh_seeding: mesh_seeding.visible = false
	if mesh_sapling: mesh_sapling.visible = false
	if mesh_middle: mesh_middle.visible = false
	if mesh_ready: mesh_ready.visible = false
	if mesh_over: mesh_over.visible = false
	
	var is_watered_real = false
	var parent_gen = get_parent()
	if parent_gen and "block_data" in parent_gen:
		var block = parent_gen.block_data[current_grid_pos.x][current_grid_pos.y]
		is_watered_real = block.is_watered

	var stage = get_stage_id()
	
	match stage:
		0:
			if mesh_seeding: mesh_seeding.visible = true
		1:
			if mesh_sapling: mesh_sapling.visible = true
		2:
			if mesh_middle: mesh_middle.visible = true
		3:
			if mesh_ready: mesh_ready.visible = true
		4:
			if mesh_over: mesh_over.visible = true
	
	_set_soil_wet(is_watered_real)
