extends Node3D

@onready var cast: RayCast3D = $"../../../../../HoeCast3D"
@onready var ground_gen = get_tree().get_first_node_in_group("ground_generator")

var item_active := true
var last_grid_pos: Vector2i = Vector2i(-1, -1)



func _process(delta: float) -> void:
	visible = HotBar.active_item.item_name == ItemNames.hoe
	#print(HotBar.active_idx())
	if ground_gen == null:
		print("❌ ground_gen null rồi, path sai hoặc scene chưa load GroundGenerator")
		return
	cast.force_raycast_update()

	if cast.is_colliding():
		var hit_pos = cast.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)

		# highlight block (nếu muốn hiển thị chọn ô)
		if last_grid_pos != grid_pos:
			last_grid_pos = grid_pos
			print("Đang trỏ vào ô:", grid_pos)
	else:
		last_grid_pos = Vector2i(-1, -1)


func is_holding_hoe() ->bool:
	return HotBar.active_item.item_name == ItemNames.hoe


func swing_hoe() -> void:
	cast.force_raycast_update()
	if cast.is_colliding():
		var hit_pos = cast.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)

		# Truy cập block data và đổi mode
		var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
		if block.mode != BlockGroundData.Mode.TILLED:
			block.mode = BlockGroundData.Mode.TILLED
			ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, BlockGroundData.Mode.TILLED)
			print("Cuốc thành công ô:", grid_pos, "| mode mới:", block.mode)
		else:
			print("Ô này đã được cuốc rồi:", grid_pos)
	else:
		print("Raycast miss")
