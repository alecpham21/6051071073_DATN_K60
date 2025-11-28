extends Plant
class_name Cabbage

func update_visuals():
	if mesh_seeding: mesh_seeding.visible = false
	if mesh_sapling: mesh_sapling.visible = false
	if mesh_middle: mesh_middle.visible = false
	if mesh_ready: mesh_ready.visible = false

	if current_growth <= 3:
		if mesh_seeding: mesh_seeding.visible = true
		_set_soil_wet(true)
		
	elif current_growth <= 7:
		if mesh_seeding: mesh_seeding.visible = true 
		if mesh_sapling: mesh_sapling.visible = true
		_set_soil_wet(false)
		
	elif current_growth <= 14:
		if mesh_seeding: mesh_seeding.visible = true
		if mesh_middle: mesh_middle.visible = true
		_set_soil_wet(false)
		
	else: #Ready
		if mesh_seeding: mesh_seeding.visible = true
		if mesh_ready: mesh_ready.visible = true
		_set_soil_wet(false)
