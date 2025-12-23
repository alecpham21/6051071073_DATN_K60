extends MainState
class_name TillingState


func _setup() -> void:
	super()
	if safe_guard: overtimed.connect(func():
		dispatch("idle")
		print("overtimed")
		)

func _enter() -> void:
	super()
	character.is_busy = true
	character.ani.animation_finished.connect(func(a):
		till((character as Player).tool_cast, limbo_hsm.ground_gen)
		dispatch("idle")
		, CONNECT_ONE_SHOT)

#func check_dispatch():
	#if !character.is_busy: dispatch("idle")

func _exit() -> void:
	super()
	character.is_busy = false

func till(cast: RayCast3D, ground_gen) -> void:
	cast.force_raycast_update()
	if not cast.is_colliding():
		print("Raycast miss")
		return

	var hit_pos = cast.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	
	if not ground_gen.is_valid_grid_pos(grid_pos): return

	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
	
	if block.mode == BlockGroundData.Mode.GRASS:
		for child in ground_gen.get_children():
			if child.get("current_grid_pos") == grid_pos:
				print("❌ Vướng cỏ dai (WindGrass)! Hãy dùng liềm cắt trước.")
				return
	
	if block.mode == BlockGroundData.Mode.CUT or block.mode == BlockGroundData.Mode.GRASS:
		block.mode = BlockGroundData.Mode.TILLED
		ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, BlockGroundData.Mode.TILLED)
		
		print("✅ Cuốc đất thành công (Decorative grass tự mất)")
		PlayerData.add_dirt_to_outfit(5.0)
		
	else:
		print("🚫 Ô này không thể cuốc:", grid_pos)
