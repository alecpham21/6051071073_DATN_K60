extends Resource
class_name GridKit

static func get_at_pos(pos:Vector3, world:PhysicsDirectSpaceState3D) -> Array:
	var space_state: PhysicsDirectSpaceState3D = world
	var query = PhysicsPointQueryParameters3D.new()
	query.position = pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result:Array = []
	result = space_state.intersect_point(query)
	return result

static func has_object(pos:Vector3, world:PhysicsDirectSpaceState3D, col:int) -> bool:
	return get_at_pos(pos, world).map(func(x): return x.collider).any(func(x): return x.get_collision_layer_value(1))
