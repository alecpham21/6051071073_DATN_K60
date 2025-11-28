extends Plant
class_name Wheat

func update_visuals():
	# Reset ẩn hết trước
	if mesh_seeding: mesh_seeding.visible = false
	if mesh_sapling: mesh_sapling.visible = false
	if mesh_middle: mesh_middle.visible = false
	if mesh_ready: mesh_ready.visible = false
	
	# Tính phần trăm độ lớn (từ 0.0 đến 1.0)
	# Ép kiểu float để chia có số thập phân
	var progress = float(current_growth) / float(max_growth)
	
	if progress <= 0.2:
		if mesh_seeding: mesh_seeding.visible = true
		_set_soil_wet(true)
		
	elif progress <= 0.5:
		if mesh_seeding: mesh_seeding.visible = true 
		if mesh_sapling: mesh_sapling.visible = true
		_set_soil_wet(false)
		
	elif progress < 1.0:
		if mesh_seeding: mesh_seeding.visible = true
		if mesh_middle: mesh_middle.visible = true
		_set_soil_wet(false)
		
	else:
		if mesh_seeding: mesh_seeding.visible = true
		if mesh_ready: mesh_ready.visible = true
		_set_soil_wet(false)
