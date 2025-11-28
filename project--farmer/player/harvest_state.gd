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
	# 1. BẮT BUỘC PHẢI CHECK RAYCAST TRÚNG ĐẤT
	cast.force_raycast_update()
	if not cast.is_colliding(): return

	var hit_pos = cast.get_collision_point()
	if not ground_gen: return
		
	# 2. LẤY TỌA ĐỘ GRID TỪ ĐIỂM CLICK
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	if not ground_gen.is_valid_grid_pos(grid_pos): return

	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]

	# 3. [FIX] ƯU TIÊN KIỂM TRA CÂY TRỒNG TRƯỚC
	# Nếu ô đất này (theo dữ liệu) đang có cây
	if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
		
		# Nếu cây đã chín -> Tìm và Gặt
		if block.crop_ready:
			# Duyệt qua các node con để tìm thằng nào có địa chỉ trùng khớp
			for child in ground_gen.get_children():
				# Kiểm tra biến current_grid_pos mà mình đã gán lúc trồng/load
				if "current_grid_pos" in child and child.current_grid_pos == grid_pos:
					if child.has_method("harvest"):
						child.harvest()
						print("✅ Gặt thành công cây tại:", grid_pos)
						return # Gặt xong thì nghỉ, không làm gì nữa
		
		# [QUAN TRỌNG]
		# Nếu ô này CÓ CÂY (dù chưa chín) -> THÌ CẤM ĐÀO ĐẤT
		# Return luôn để tránh việc click trúng cây chưa chín mà lại thành đào lỗ
		print("🚫 Có cây (chưa chín hoặc đang đợi), không đào đất!")
		return 

	# 4. CHỈ KHI KHÔNG CÓ CÂY GÌ MỚI ĐƯỢC CẮT CỎ/ĐÀO ĐẤT
	if block.mode == BlockGroundData.Mode.GRASS:
		block.mode = BlockGroundData.Mode.CUT
		ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, block.mode)
		print("✂️ Cắt cỏ tại:", grid_pos)
		return
