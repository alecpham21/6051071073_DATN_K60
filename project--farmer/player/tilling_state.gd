extends GardeningState

#@export var hoe:Hoe

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

func till(cast:RayCast3D, ground_gen) -> void:
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
