extends Node3D

var current_grid_pos: Vector2i 

func harvest():
	if SignalBus.has_signal("object_harvested"):
		SignalBus.object_harvested.emit("wind_grass", 1)

	print("🌿 Cây cỏ tại ", current_grid_pos, " đã bị cắt!")
	queue_free()
