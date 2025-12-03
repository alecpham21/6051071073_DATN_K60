extends Node3D

@export var forage_scene: PackedScene
@export_range(0.0, 1.0) var spawn_chance: float = 0.3
@export var spawn_points: Array[Node3D]

var current_forage_object: Node = null

func _ready() -> void:
	TimeManager.tick.connect(_on_time_tick)
	check_spawn()

func _on_time_tick():
	if TimeManager.current_time == 0:
		check_spawn()

func check_spawn():

	if current_forage_object != null:
		return

	if randf() < spawn_chance:
		spawn_object()

func spawn_object():
	if spawn_points.is_empty(): return
	
	var point = spawn_points.pick_random()
	
	var obj = forage_scene.instantiate()
	add_child(obj)
	obj.global_position = point.global_position
	obj.rotation.y = randf() * TAU 
	
	current_forage_object = obj
