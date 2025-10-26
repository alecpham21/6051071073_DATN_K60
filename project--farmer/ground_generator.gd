extends Node3D
class_name GroundGenerator

@onready var renderer: GroundRenderer = $GroundRenderer


@export var ground_extents : Vector2i
@export var tree_spawn_chance : float = 0.1
@export var tree_max_count : int = 20
@export var grass_max_count : int = 4
@export var grass_spawn_chance : float = 0.1
@export var border_tree_count : int = 40
@export var border_offset : float = 2.0
@export var outer_tree_count : int = 60
@export var outer_offset : float = 5.0  # vòng trong hơn border

#var _block = preload("res://modelTscn/block/block_ground.tscn")
var _tree = preload("res://model/tree/TreeVer1.tscn")
var _bordertree = preload("res://model/tree/BackGroundTree.tscn")
var block_data: Array = []
var _tree_count := 0



func _ready() -> void:
	setup_data()
	renderer.setup(ground_extents.x, ground_extents.y)
	
	for x in range(ground_extents.x):
		for z in range(ground_extents.y):
			renderer.set_mode(x, z, 0)
	#gen_ground(ground_extents)
	_spawn_border_trees()
	_spawn_outer_trees()
	_create_ground_collision()

func setup_data():
	block_data.resize(ground_extents.x)
	for x in range(ground_extents.x):
		block_data[x] = []
		for z in range(ground_extents.y):
			block_data[x].append(BlockGroundData.new())


func gen_ground(extents:Vector2i):
	var start_pos = Vector3(-extents.x / 2, 0, -extents.y / 2)
	for x in extents.x:
		for z in extents.y:
			renderer.set_mode(x, z, BlockGroundData.Mode.GRASS)


func _create_ground_collision() -> void:
	var static_body = StaticBody3D.new()
	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	
	shape.size = Vector3(ground_extents.x, 0.2, ground_extents.y)
	
	collider.shape = shape
	static_body.add_child(collider)
	
	static_body.position = Vector3(0, 0, 0)
	
	add_child(static_body)


# cây
func _try_spawn_tree(pos: Vector3):
	if _tree_count >= tree_max_count:
		return
	var center = Vector3(0, 0, 0)
	var max_dist = ground_extents.length() / 2.0
	var dist = pos.distance_to(center)
	var weight = pow(1.0 - clamp(dist / max_dist, 0.0, 1.0), 3.0)
	var adjust_chance = tree_spawn_chance * weight
	if randf() < adjust_chance:
		var tree = _tree.instantiate()
		add_child(tree)
		tree.position = pos
		
		# scale
		var random_scale = randf_range(0.8, 1.5)
		tree.scale = Vector3.ONE * random_scale
		tree.rotate_y(randf_range(0.0, TAU))
		
		_tree_count += 1


# cây background
func _spawn_border_trees():
	var half_x = ground_extents.x / 2.0
	var half_y = ground_extents.y / 2.0
	
	for i in range(border_tree_count):
		var side = randi() % 4
		var pos = Vector3.ZERO
		match side:
			0: pos = Vector3(randf_range(-half_x, half_x), 0, -half_y - border_offset)
			1: pos = Vector3(randf_range(-half_x, half_x), 0, half_y + border_offset)
			2: pos = Vector3(-half_x - border_offset, 0, randf_range(-half_y, half_y))
			3: pos = Vector3(half_x + border_offset, 0, randf_range(-half_y, half_y))
		
		var border_tree = _bordertree.instantiate()
		add_child(border_tree)
		border_tree.position = pos
		
		var random_scale = randf_range(3.0, 4.0)
		border_tree.scale = Vector3.ONE * random_scale
		border_tree.rotate_y(randf_range(0.0, TAU))


# cây TreeVer1
func _spawn_outer_trees():
	var half_x = ground_extents.x / 2.0
	var half_y = ground_extents.y / 2.0
	
	for i in range(outer_tree_count):
		var side = randi() % 4
		var pos = Vector3.ZERO
		var inner_offset = outer_offset + randf_range(-1.0, 1.0)  # lệch nhẹ
		
		match side:
			0: pos = Vector3(randf_range(-half_x, half_x), 0, -half_y + inner_offset)
			1: pos = Vector3(randf_range(-half_x, half_x), 0, half_y - inner_offset)
			2: pos = Vector3(-half_x + inner_offset, 0, randf_range(-half_y, half_y))
			3: pos = Vector3(half_x - inner_offset, 0, randf_range(-half_y, half_y))
		
		var tree = _tree.instantiate()
		add_child(tree)
		tree.position = pos
		
		# scale nhỏ hơn border tree
		var random_scale = randf_range(1.2, 2.5)
		tree.scale = Vector3.ONE * random_scale
		tree.rotate_y(randf_range(0.0, TAU))

## Grid dựa trên world position
func get_grid_pos_from_world(world_pos: Vector3) -> Vector2i:
	var spacing := renderer.spacing
	var half_x := ground_extents.x * spacing / 2.0
	var half_z := ground_extents.y * spacing / 2.0

	var gx = int(floor((world_pos.x + half_x) / spacing))
	var gz = int(floor((world_pos.z + half_z) / spacing))

	# Giữ trong giới hạn map
	gx = clamp(gx, 0, ground_extents.x - 1)
	gz = clamp(gz, 0, ground_extents.y - 1)

	return Vector2i(gx, gz)
