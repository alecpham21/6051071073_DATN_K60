extends GardeningState

#@export var sickle:Sickle
@export var hand_ani:AnimationSet
@export var knife_ani:AnimationSet

func _setup() -> void:
	super()
	if safe_guard: overtimed.connect(func():
		dispatch("idle")
		print("overtimed")
		)

func _enter() -> void:
	super()
	character.is_busy = true
	if HotBar.hand(): hand_ani.play(character.ani)
	else: knife_ani.play(character.ani)
	character.ani.animation_finished.connect(func(a):
		harvest((character as Player).tool_cast, limbo_hsm.ground_gen)
		dispatch("idle")
		, CONNECT_ONE_SHOT)
	

#func check_dispatch():
	#if !character.is_busy: dispatch("idle")

func _exit() -> void:
	super()
	character.is_busy = false

func harvest(cast:RayCast3D, ground_gen) -> void:
	#if not cast or not visible: return
	
	cast.force_raycast_update()
	if not cast.is_colliding(): return

	var hit_pos = cast.get_collision_point()
	if not ground_gen: return
		
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	if not ground_gen.is_valid_grid_pos(grid_pos): return

	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]

	# 1. Harvest Crop
	if block.crop_ready:
		for child in ground_gen.get_children():
			if child.has_method("harvest") and \
				child.global_position.distance_to(ground_gen.get_world_pos_from_grid(grid_pos)) < 0.5:
				child.harvest()
				ground_gen.reset_block_after_harvest(grid_pos, true)
				print("✅ Harvested crop at:", grid_pos)
				return 

	# 2. Cut Grass
	if block.mode == BlockGroundData.Mode.GRASS:
		block.mode = BlockGroundData.Mode.CUT
		ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, block.mode)
		print("✂️ Cut grass at:", grid_pos)
		return
