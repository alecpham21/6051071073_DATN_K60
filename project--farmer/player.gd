extends CharacterBody3D

@export var move_speed: float = 5.0
@export var accel: float = 20.0
@export var use_gravity: bool = false
@export_node_path("Node3D") var camera_ref_path: NodePath

@onready var anim: AnimationPlayer = $Jordax/AnimationPlayer
@onready var hoe: Node3D = $Jordax/rig/Skeleton3D/BoneAttachment3D/Hoe
@onready var sickle: Node3D = $Jordax/rig/Skeleton3D/BoneAttachment3D/Sickle
@onready var seeding: Node3D = $Seeding
@onready var player_inventory = get_node("/root/World/PlayerInventory")
@onready var interact_ray: RayCast3D = $InteractRay
@onready var ground_gen = get_node("../GroundGenerator")




var tool_map: Dictionary
var cam_ref: Node3D
var mouse_captured := true
var is_busy: bool = false
var current_tool_name: String = "none"
var near_door: HouseDoor = null




func _ready() -> void:
	tool_map = {
		"hoe": hoe,
		"sickle": sickle
	}

	# Tự động map mọi item kết thúc bằng "_seed" đến node seeding
	for item_name in player_inventory.get_all_item_names():
		if item_name.ends_with("_seed"):
			tool_map[item_name] = seeding

	if hoe:
		print("=== HOE DEBUG ===")
		print("hoe node:", hoe, "class:", hoe.get_class())
		for c in hoe.get_children():
			print("  child:", c, "class:", c.get_class(), "script:", c.get_script())
	else:
		print("❌ hoe not found!")

	if sickle:
		print("=== SICKLE DEBUG ===")
		print("sickle node:", sickle, "class:", sickle.get_class())
		for c in sickle.get_children():
			print("  child:", c, "class:", c.get_class(), "script:", c.get_script())
	else:
		print("❌ sickle not found!")
	if hoe:
		hoe.player_inventory = player_inventory
	if sickle:
		sickle.player_inventory = player_inventory
	if seeding:
		seeding.player_inventory = player_inventory
	# Sau đó để nguyên các dòng cũ bên dưới
	update_tool_visibility("none")

	# Bind camera
	if camera_ref_path != NodePath():
		cam_ref = get_node(camera_ref_path) as Node3D
	else:
		push_error("Player.gd: Chưa gán camera_ref_path (kéo SpringArm3D/Yaw vào).")
		set_physics_process(false)

	# Kết nối signal khi inventory đổi item
	player_inventory.active_item_changed.connect(_on_active_item_changed)

	_set_mouse_captured(true)
	anim.animation_finished.connect(_on_anim_finished)


func _on_active_item_changed(item_name: String) -> void:
	current_tool_name = item_name
	print("=== ACTIVE ITEM CHANGED ===")
	print("Inventory active item:", player_inventory.get_active_item())
	print("Current tool name:", current_tool_name)
	update_tool_visibility(item_name)

func _process(_delta):
	if not ground_gen:
		return

	var data = ground_gen.block_data
	if data.is_empty():
		print("⚠ block_data chưa được khởi tạo!")
		return
	var hit_pos = interact_ray.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)

	#var grid_pos: Vector2i = ground_gen.get_grid_pos_from_world(global_position)

	if grid_pos.x < 0 or grid_pos.y < 0 or grid_pos.x >= data.size() or grid_pos.y >= data[0].size():
		print("⚠ Ngoài giới hạn:", grid_pos, "| Map size:", Vector2i(data.size(), data[0].size()))
		return

	var block = data[grid_pos.x][grid_pos.y]
	print("Block hiện tại:", grid_pos, "| Mode:", block.mode)




func update_tool_visibility(current_item: String) -> void:
	# Ẩn tất cả tool
	for tool in tool_map.values():
		tool.visible = false

	# Hiện tool đang cầm (nếu có)
	if current_item in tool_map:
		tool_map[current_item].visible = true
	else:
		# Không có tool (slot rỗng)
		current_tool_name = "none"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_mode"):
		_set_mouse_captured(false)
	elif event.is_action_released("interact_mode"):
		_set_mouse_captured(true)
		
	if event.is_action_pressed("use_item") and not is_busy:
		if interact_ray.is_colliding():
			var hit = interact_ray.get_collider()
			print("Ray hit:", hit)
			
			if hit.has_method("on_player_interact"):
				hit.on_player_interact(self)



	if event.is_action_pressed("use_item") and not is_busy:
		print("DEBUG: Use item pressed, current_tool_name =", current_tool_name)
		match current_tool_name:
			"hoe":
				if hoe.has_method("is_holding_hoe"):
					print("DEBUG: hoe.has_method ok, result =", hoe.is_holding_hoe())
				if hoe.has_method("is_holding_hoe") and hoe.is_holding_hoe():
					start_swing()
			"sickle":
				if sickle.has_method("is_holding_sickle"):
					print("DEBUG: sickle.has_method ok, result =", sickle.is_holding_sickle())
				if sickle.has_method("is_holding_sickle") and sickle.is_holding_sickle():
					start_cut()
			"corn_seed", "wheat_seed":
				start_seeding()



func start_swing() -> void:
	is_busy = true
	anim.play("Till_Dirt")

func start_cut() -> void:
	is_busy = true
	anim.play("CutGrass_Sickle")

func start_seeding() -> void:
	is_busy = true
	anim.play("Seeding")


func _on_anim_finished(name: String) -> void:
	match name:
		"Till_Dirt":
			if hoe and hoe.has_method("swing_hoe"):
				hoe.swing_hoe()
			is_busy = false

		"Seeding":
			is_busy = false

		"CutGrass_Sickle":
			if sickle and sickle.has_method("swing_sickle"):
				sickle.swing_sickle()
			is_busy = false



func _physics_process(delta: float) -> void:
	# Gravity
	if use_gravity and not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	# Đang bận thì đứng yên
	if is_busy:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Interact mode thì đứng yên
	if not mouse_captured:
		velocity.x = lerpf(velocity.x, 0.0, clampf(accel * delta, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, 0.0, clampf(accel * delta, 0.0, 1.0))
		move_and_slide()
		return

	# Input movement
	var iv: Vector2 = Input.get_vector("left", "right", "back", "forward")
	if iv.length() > 1.0:
		iv = iv.normalized()

	# Hướng theo yaw camera
	var eul: Vector3 = cam_ref.global_transform.basis.get_euler()
	var cam_yaw: float = eul.y
	var forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw))
	var right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))
	var move_dir: Vector3 = right * iv.x + forward * iv.y

	# Animation
	if move_dir.length() > 0.0:
		anim.play("Walking")
	else:
		anim.play("Idle1")

	# Vận tốc mục tiêu
	var target_vel: Vector3 = move_dir * move_speed
	var k: float = clampf(accel * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target_vel.x, k)
	velocity.z = lerpf(velocity.z, target_vel.z, k)

	move_and_slide()

	# Xoay nhân vật theo hướng di chuyển
	if move_dir.length() > 0.0:
		var target_yaw: float = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 10.0 * delta)


func _set_mouse_captured(enable: bool) -> void:
	mouse_captured = enable
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)


func is_interact_mode() -> bool:
	return not mouse_captured

func try_harvest_crop(crop):
	if player_inventory.get_active_item() == "sickle":
		crop.harvest()
