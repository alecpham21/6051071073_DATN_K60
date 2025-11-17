class_name Player
extends Character

@export var player_actions : PlayerActions
@export var input: PlayerInput
@export var character : Character

@onready var anim: AnimationPlayer = $Farmer/AnimationPlayer
@onready var hoe: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Hoe
@onready var sickle: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Sickle
@onready var seeding: Node3D = $Seeding
@onready var grid_check_ray: RayCast3D = $GridCheckRay
@onready var ground_gen = get_node_or_null("../GroundGenerator")
@onready var hl_select: MeshInstance3D = $HighlightSelector
@onready var interact_area: Area3D = $Interact_Area
var equip_inventory_data: QuickInventoryData
var outfit_inventory_data: InventoryDataOutfit
var inventory_data: InventoryData
@export var move_speed: float = 5.0
@export var accel: float = 20.0
@export var use_gravity: bool = false
@onready var ao_mesh_node: MeshInstance3D = $Farmer/rig/Skeleton3D/FarmerTShirt
@export_node_path("Node3D") var camera_ref_path: NodePath


var blackboard : Blackboard
var last_block_pos: Vector2i = Vector2i(-1, -1)
var cam_ref: Node3D
var mouse_captured := true
var is_busy: bool = false
var current_tool_name: String = "none"
var near_door: HouseDoor = null
var can_interact:bool = false

signal toggle_inventory()


func _ready() -> void:
	super()
	if PlayerData.used_spawn_position == false:
		self.global_position = PlayerData.next_spawn_position
		PlayerData.used_spawn_position = true
	
	self.inventory_data = PlayerData.player_inventory_data
	self.equip_inventory_data = PlayerData.player_equip_data
	self.outfit_inventory_data = PlayerData.player_outfit_data
	interact_area.area_entered.connect(func(a): can_interact = true)
	interact_area.area_exited.connect(func(a): can_interact = false)
	
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

	# Bind camera
	if camera_ref_path != NodePath():
		cam_ref = get_node(camera_ref_path) as Node3D
	else:
		push_error("Player.gd: Chưa gán camera_ref_path (kéo SpringArm3D/Yaw vào).")
		set_physics_process(false)

	_set_mouse_captured(true)
	anim.animation_finished.connect(_on_anim_finished)
	## Highlight Box
	hl_select.visible = false
	var hsm := get_node_or_null("LimboHSM")
	if hsm:
		blackboard = hsm.blackboard
	else:
		push_warning("Không tìm thấy LimboHSM => blackboard sẽ là null!")

## Outfit
	if outfit_inventory_data:
			outfit_inventory_data.inventory_updated.connect(update_all_outfits)
			update_all_outfits()


func _process(_delta):
	if not ground_gen:
		return

	var data = ground_gen.block_data
	if data.is_empty():
		print("⚠ block_data chưa được khởi tạo!")
		return

	if grid_check_ray.is_colliding():
		var hit_pos = grid_check_ray.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)

		if grid_pos.x < 0 or grid_pos.y < 0 or grid_pos.x >= data.size() or grid_pos.y >= data[0].size():
			hl_select.visible = false
			return

		## Print Block Location and Mode
		if grid_pos != last_block_pos:
			var block = data[grid_pos.x][grid_pos.y]
			print("Block hiện tại:", grid_pos, "| Mode:", block.mode)
			last_block_pos = grid_pos
			print("Đang trỏ vào ô:", grid_pos)

		## Highlighting Block: Always active 
		var world_pos = ground_gen.get_world_pos_from_grid(grid_pos)
		hl_select.global_position = world_pos + Vector3(0, 0.02, 0)
		hl_select.scale = Vector3(ground_gen.renderer.spacing, 1, ground_gen.renderer.spacing)
		hl_select.global_rotation = Vector3.ZERO 
		hl_select.visible = true
	else:
		## Hide block when ray doenst hit
		hl_select.visible = false



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_mode"):
		_set_mouse_captured(false)
	elif event.is_action_released("interact_mode"):
		_set_mouse_captured(true)
	
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()
	
	if event.is_action_pressed("use_item") and not is_busy:
		if grid_check_ray.is_colliding():
			var hit = grid_check_ray.get_collider()
			print("Ray hit:", hit)
			
			if hit.has_method("on_player_interact"):
				hit.on_player_interact(self)

	if Input.is_action_just_pressed("interact") && can_interact:
		interact()

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
	anim.play("Cutting_Plant")

func start_seeding() -> void:
	is_busy = true
	anim.play("Seeding")

func interact():
	(interact_area.get_overlapping_areas()[0] as InteractArea).interacted.emit()

func get_drop_position() -> Vector3:
	var direction = grid_check_ray.global_position
	return direction


func _on_anim_finished(name: String) -> void:
	match name:
		"Till_Dirt":
			if hoe and hoe.has_method("swing_hoe"):
				hoe.swing_hoe()
			is_busy = false

		"Seeding":
			seeding.plant_seed()
			is_busy = false

		"Cutting_Plant":
			if sickle and sickle.has_method("swing_sickle"):
				sickle.swing_sickle()
			is_busy = false

func update_visuals(slot_index: int, target_node: MeshInstance3D):
	if slot_index >= outfit_inventory_data.slot_datas.size():
		return 
	
	if not target_node:
		push_error("Target node (ao_mesh_node) bị null!")
		return
		
	var slot_data = outfit_inventory_data.slot_datas[slot_index]
	
	if slot_data and slot_data.item_data and slot_data.item_data.equip_mesh:
		target_node.mesh = slot_data.item_data.equip_mesh
		target_node.visible = true
	else:
		target_node.mesh = null
		target_node.visible = false

func update_all_outfits(_inventory_data = null):
	if not outfit_inventory_data: return

		# (Nhớ thêm kiểm tra an toàn cho size mảng)
	if outfit_inventory_data.slot_datas.size() < 3: return 
	update_visuals(1, ao_mesh_node)    # Slot 1 = BODY


func _physics_process(delta: float) -> void:
	super(delta)
	if bt_player:
		bt_player.update(delta)


func _set_mouse_captured(enable: bool) -> void:
	mouse_captured = enable
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)


func is_interact_mode() -> bool:
	return not mouse_captured

func try_harvest_crop(crop):
		crop.harvest()
