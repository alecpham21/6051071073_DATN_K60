@tool
extends MultiMeshInstance3D
class_name GrassSpawner

@export var count: int = 20 : set = _set_count
@export var area_size: float = 1.0
@export var height_offset: float = 0.0

func _set_count(v):
	count = max(v, 0)
	if Engine.is_editor_hint():
		_spawn_grass()
	else:
		call_deferred("_spawn_grass")

func _ready():
	if not Engine.is_editor_hint():
		_spawn_grass()

func _spawn_grass():
	if multimesh == null:
		return
	multimesh.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(count):
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		var rotation = rng.randf_range(0, TAU)
		var transform := Transform3D().rotated(Vector3.UP, rotation)
		transform.origin = Vector3(x, height_offset, z)
		multimesh.set_instance_transform(i, transform)
