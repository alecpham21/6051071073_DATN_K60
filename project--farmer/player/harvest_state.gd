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

func harvest(cast: RayCast3D, ground_gen) -> void:
	# 1. Hái từ Area3D (Măng/Cây Tre)
	var target = character.current_interactable
	if target != null and target.has_method("harvest"):
		if target.get("is_harvestable"):
			target.harvest()
			print("✅ Đã hái từ Area3D")
			
			# Dirty Point for harvestin around
			PlayerData.add_dirt_to_outfit(2.0)
			return
	
	cast.force_raycast_update()
	if not cast.is_colliding(): return

	var collider = cast.get_collider()
	var object_hit = collider.get_parent() 
	
	if object_hit.has_method("harvest"):
		if object_hit.get("is_harvestable") == true: 
			object_hit.harvest()
			print("✅ Trúng Hitbox")
			
			# Dirty Point for harvesting plant
			PlayerData.add_dirt_to_outfit(3.0)
			return
		else:
			print("🚫 Cây chưa chín, không làm gì cả")
			return 

	var hit_pos = cast.get_collision_point()
	if not ground_gen: return
	
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	if not ground_gen.is_valid_grid_pos(grid_pos): return

	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]

	if block.plant_type == PlantDatabase.PLANT_VARIANT.NONE:
		if block.mode == BlockGroundData.Mode.GRASS:
			block.mode = BlockGroundData.Mode.CUT
			ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, block.mode)
			print("✂️ Cắt cỏ")
			
			# Dirty Point for cutting grass
			PlayerData.add_dirt_to_outfit(2.0)
