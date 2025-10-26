extends Node3D

@export var grid_w := 5
@export var grid_h := 5
@export var cell_size := 2.0
@export var grid_origin := Vector3.ZERO

@onready var hover := $MultiHover as MultiMeshInstance3D
@onready var cells := $MultiCells as MultiMeshInstance3D
@onready var player := get_tree().get_first_node_in_group("player") # Player group

func _ready():
	grid_origin.x = floor(global_transform.origin.x / cell_size) * cell_size
	grid_origin.y = 0
	grid_origin.z = floor(global_transform.origin.z / cell_size) * cell_size
	
	# Spawn Cells
	var quad := PlaneMesh.new()
	quad.size = Vector2(cell_size, cell_size)
	var mm := MultiMesh.new()
	mm.mesh = quad
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = grid_w * grid_h
	cells.multimesh = mm
	var idx := 0
	for y in grid_h:
		for x in grid_w:
			var pos := grid_origin + Vector3(x * cell_size, 0.01, y * cell_size)
			var t := Transform3D(Basis.IDENTITY, pos)
			mm.set_instance_transform(idx, t)
			idx += 1
	_init_hover()

func _init_hover():
	var quad := PlaneMesh.new()
	quad.size = Vector2(cell_size, cell_size)
	var mm := MultiMesh.new()
	mm.mesh = quad
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 1
	hover.multimesh = mm
	hover.visible = false

func set_hover_cell(c: Vector2i):
	if not in_bounds(c):
		hover.visible = false
		return
	var pos := grid_origin + Vector3(c.x * cell_size, 0.012, c.y * cell_size)
	hover.multimesh.set_instance_transform(0, Transform3D(Basis.IDENTITY, pos))
	hover.visible = true

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < grid_w and c.y < grid_h

func world_to_cell(pos: Vector3) -> Vector2i:
	var local := pos - grid_origin
	return Vector2i(int(floor(local.x / cell_size)), int(floor(local.z / cell_size)))

func _ray_to_ground(cam: Camera3D) -> Dictionary:
	var sp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(sp)
	var to := from + cam.project_ray_normal(sp) * 2000.0
	var p := PhysicsRayQueryParameters3D.create(from, to)
	p.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_ray(p)

func _unhandled_input(e: InputEvent):
	if player == null or not player.is_interact_mode():
		hover.visible = false
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	if e is InputEventMouseMotion:
		var hit := _ray_to_ground(cam)
		if hit:
			var c := world_to_cell(hit.position)
			set_hover_cell(c)
	if e is InputEventMouseMotion:
		var hit := _ray_to_ground(cam)
		if hit:
			print("Hit at: ", hit.position)
			var c := world_to_cell(hit.position)
			print("Cell: ", c)
			set_hover_cell(c)
	else:
		print("No hit")
