extends Node3D

@onready var cast: RayCast3D = $"../../../../../HoeCast3D"
@onready var ground_gen = get_tree().get_first_node_in_group("ground_generator")

var item_active := true
var last_grid_pos: Vector2i = Vector2i(-1, -1)


func _process(delta: float) -> void:
	cast.force_raycast_update()
	

func is_holding_sickle():
	print("is holding sickle")
	
	
func swing_sickle() -> void:
	cast.force_raycast_update()
	if not cast.is_colliding():
		print("❌ Raycast miss")
		return

	var hit_pos = cast.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)

	if not ground_gen.is_valid_grid_pos(grid_pos):
		print("❌ Grid position out of range:", grid_pos)
		return

	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]

	# Nếu có cây sẵn sàng thu hoạch
	if block.crop_ready:
		block.crop_ready = false
		block.mode = BlockGroundData.Mode.TILLED
		ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, block.mode)

		# Tìm cây ở vị trí đó và gọi harvest
		for child in ground_gen.get_children():
			if child.has_method("harvest") and \
				child.global_position.distance_to(ground_gen.get_world_pos_from_grid(grid_pos)) < 0.3:
				child.harvest()
				break


		print("✅ Harvested crop at:", grid_pos)
		return



	# Nếu là cỏ thì cắt, chuyển sang CUT
	if block.mode == BlockGroundData.Mode.GRASS:
		block.mode = BlockGroundData.Mode.CUT
		ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, block.mode)
		print("✂️ Cut grass at:", grid_pos)
		return

	print("No valid target to swing at:", grid_pos)
