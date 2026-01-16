extends MainState
class_name TillingState

const DIRT_VFX = preload("res://vfx/dirt_splash.tscn")

@export var hit_times: Array[float] = [1.0, 2.0]

func _setup() -> void:
	super()
	if safe_guard: overtimed.connect(func():
		dispatch("idle")
		print("Wrapper: State overtimed")
		)

func _enter() -> void:
	super()
	
	if character.stats.stamina > 0 and character.stats.stamina < character.stats.action_cost:
		character.stats.report_force_work()
	
	if character.stats.stamina <= 0:
		print("⚡ Exhausted! Cannot till.")
		if blackboard: blackboard.set_var("tired_cause", "farm")
		dispatch("tired")
		return

	character.is_busy = true
	
	for i in range(hit_times.size()):
		var time_point = hit_times[i]
		var is_last_hit = (i == hit_times.size() - 1)
		
		get_tree().create_timer(time_point).timeout.connect(func():
			if character.is_busy:
				spawn_vfx((character as Player).tool_cast, limbo_hsm.ground_gen)
				
				if is_last_hit:
					till((character as Player).tool_cast, limbo_hsm.ground_gen)
					character.stats.consume(character.stats.action_cost)
		)
	
	character.ani.animation_finished.connect(func(a):
		if character.stats.stamina <= 0:
			print("😫 Over-exerted! Tilling caused exhaustion.")
			if blackboard: blackboard.set_var("tired_cause", "farm")
			dispatch("tired")
		else:
			dispatch("idle")
			
		, CONNECT_ONE_SHOT)

func _exit() -> void:
	super()
	character.is_busy = false

func spawn_vfx(cast: RayCast3D, ground_gen) -> void:
	if not DIRT_VFX: return
	
	cast.force_raycast_update()
	if not cast.is_colliding(): return
	
	var hit_pos = cast.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	
	if not ground_gen.is_valid_grid_pos(grid_pos): return
	
	var vfx = DIRT_VFX.instantiate()
	get_tree().root.add_child(vfx)
	vfx.global_position = hit_pos
	vfx.global_position.y += 0.2

func till(cast: RayCast3D, ground_gen) -> void:
	cast.force_raycast_update()
	if not cast.is_colliding():
		print("❌ Raycast missed")
		return

	var hit_pos = cast.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	
	if not ground_gen.is_valid_grid_pos(grid_pos): 
		print("❌ Invalid grid position")
		return

	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
	
	if block.mode == BlockGroundData.Mode.GRASS:
		for child in ground_gen.get_children():
			if child.get("current_grid_pos") == grid_pos:
				print("❌ Cannot till: Wind grass present")
				return
	
	if block.mode == BlockGroundData.Mode.CUT or block.mode == BlockGroundData.Mode.GRASS:
		block.mode = BlockGroundData.Mode.TILLED
		ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, BlockGroundData.Mode.TILLED)
		
		print("✅ Tilling successful")
		PlayerData.add_dirt_to_outfit(5.0)
		
	else:
		print("🚫 Cannot till this grid: ", grid_pos)
