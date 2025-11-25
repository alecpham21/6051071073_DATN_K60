@tool
extends MultiMeshInstance3D

@export var extents := Vector2.ONE

func _ready():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	

	multimesh.instance_count = 0 
	multimesh.instance_count = 10000

	for i in range(multimesh.instance_count):
		var x = rng.randf_range(-extents.x, extents.x)
		var z = rng.randf_range(-extents.y, extents.y)

		var trans := Transform3D()
		var random_angle = rng.randf_range(-PI, PI)
		trans = trans.rotated(Vector3.UP, random_angle)
		var random_scale = rng.randf_range(1, 1.6)
		trans = trans.scaled(Vector3(random_scale, random_scale, random_scale))


		trans.origin = Vector3(x, 0, z)

		multimesh.set_instance_transform(i, trans)
