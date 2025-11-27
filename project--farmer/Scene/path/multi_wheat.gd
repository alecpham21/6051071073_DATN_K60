@tool
extends MultiMeshInstance3D

# --- RESOURCES ---
@export var mesh_mau: Mesh = preload("res://model/otherGrass/grass.res") 

# --- GROUP 1: CHIA ĐẤT LỚN ---
@export_group("1. Main Fields Configuration")

@export_subgroup("Main Grid Layout")
@export var rows: int = 2 
@export var columns: int = 4

@export_subgroup("Field Spacing")
@export var gap_x: float = 2.0 
@export var gap_z: float = 5.0 

# --- GROUP 2: CHIA HÀNG LÚA BÊN TRONG ---
@export_group("2. Rice Plant Configuration")

@export_subgroup("Inner Grid Layout")
@export var lines_per_field: int = 20  # Số hàng dọc
@export var plants_per_line: int = 30  # Số cây trên 1 hàng

@export_subgroup("Randomness & Transform")
@export var position_jitter: float = 0.1 # Độ lệch hàng lối
@export var scale_min: float = 0.8
@export var scale_max: float = 1.2
@export var random_rotation: bool = true

# --- ACTIONS ---
@export_group("Actions")
@export var update: bool = false:
	set(value):
		if value:
			_spawn_fields()
			update = false

func _ready():
	if not Engine.is_editor_hint():
		_spawn_fields()

func _spawn_fields():
	# Default values if null
	if gap_x == null: gap_x = 2.0
	if gap_z == null: gap_z = 5.0
	if rows == null: rows = 2
	if columns == null: columns = 4
	if lines_per_field <= 0: lines_per_field = 10
	if plants_per_line <= 0: plants_per_line = 10

	# 1. CHECK PARENT MESH
	var parent = get_parent()
	if not parent is MeshInstance3D:
		print("⚠️ Error: Parent must be a MeshInstance3D!")
		return
	var parent_mesh = parent.mesh
	if not parent_mesh: return
		
	var aabb = parent_mesh.get_aabb()
	var total_w = aabb.size.x
	var total_d = aabb.size.z 
	
	if rows <= 0: rows = 1
	if columns <= 0: columns = 1
	
	# 2. SETUP MULTIMESH
	if not multimesh: multimesh = MultiMesh.new()
	multimesh.instance_count = 0 
	
	if mesh_mau:
		multimesh.mesh = mesh_mau
	else:
		return

	if multimesh.transform_format != MultiMesh.TRANSFORM_3D:
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = false
	multimesh.use_custom_data = false
	
	# Calculate total instances
	var total_instances = (rows * columns) * (lines_per_field * plants_per_line)
	multimesh.instance_count = total_instances
	
	# 3. CALCULATE DIMENSIONS
	var field_width_x = (total_w - (gap_x * (columns - 1))) / columns
	var field_depth_z = (total_d - (gap_z * (rows - 1))) / rows
	
	var start_main_x = -total_w / 2.0 + field_width_x / 2.0
	var start_main_z = -total_d / 2.0 + field_depth_z / 2.0
	
	# Inner grid steps
	var step_x = field_width_x / max(1, plants_per_line - 1)
	var step_z = field_depth_z / max(1, lines_per_field - 1)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var instance_idx = 0
	
	print("Spawning aligned rice fields...")

	# 4. MAIN FIELDS LOOP
	for r in range(rows):
		for c in range(columns):
			var center_field_x = start_main_x + c * (field_width_x + gap_x)
			var center_field_z = start_main_z + r * (field_depth_z + gap_z)
			
			var start_rice_x = center_field_x - field_width_x / 2.0
			var start_rice_z = center_field_z - field_depth_z / 2.0
			
			# 5. INNER RICE LOOP
			for line in range(lines_per_field): 
				for plant in range(plants_per_line): 
					
					# Calculate aligned position
					var pos_x = start_rice_x + (plant * step_x)
					var pos_z = start_rice_z + (line * step_z)
					
					# Apply Jitter
					pos_x += rng.randf_range(-position_jitter, position_jitter)
					pos_z += rng.randf_range(-position_jitter, position_jitter)
					
					# Transform
					var t = Transform3D()
					
					if random_rotation:
						t = t.rotated(Vector3.UP, rng.randf_range(-PI, PI))
					
					var s = rng.randf_range(scale_min, scale_max)
					t = t.scaled(Vector3(s, s, s))
					
					t.origin = Vector3(pos_x, 0, pos_z)
					
					if instance_idx < total_instances:
						multimesh.set_instance_transform(instance_idx, t)
						instance_idx += 1
				
	print("✅ Done! Aligned Grid Spawning.")
