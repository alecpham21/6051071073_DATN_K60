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
	cast.force_raycast_update()
	if not cast.is_colliding(): return

	var collider = cast.get_collider() # Cái này sẽ là Hitbox (Area3D) hoặc Đất (StaticBody)
	
	# --- 1. NẾU TRÚNG CÂY (HITBOX) ---
	# Vì collider là Area3D (con), nên ta phải lấy cha nó (Cây lúa) để gọi harvest
	var object_hit = collider.get_parent() 
	
	if object_hit.has_method("harvest"):
		# Kiểm tra xem cây đã chín chưa (nếu cần)
		# Giả sử biến is_harvestable nằm ở script cây
		if object_hit.get("is_harvestable") == true: 
			object_hit.harvest()
			print("✅ Gặt lúa (Trúng Hitbox)")
			return
		else:
			print("🚫 Cây chưa chín, không làm gì cả")
			return # Return luôn để không đào đất dưới chân

	# --- 2. NẾU TRÚNG ĐẤT (Logic cũ) ---
	# Nếu collider không phải cây, thì check xem có phải đất không
	var hit_pos = cast.get_collision_point()
	if not ground_gen: return
	
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	if not ground_gen.is_valid_grid_pos(grid_pos): return

	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]

	# Chỉ cho phép cắt cỏ/đào đất nếu ô đó KHÔNG CÓ CÂY (dựa trên data)
	if block.plant_type == PlantDatabase.PLANT_VARIANT.NONE:
		if block.mode == BlockGroundData.Mode.GRASS:
			block.mode = BlockGroundData.Mode.CUT
			ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, block.mode)
			print("✂️ Cắt cỏ")
