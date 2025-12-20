class_name Player
extends Character


# BODY
@onready var body_base: MeshInstance3D = $Farmer/rig/Skeleton3D/Base
@onready var body_feets: MeshInstance3D = $Farmer/rig/Skeleton3D/Feets
@onready var body_legs: MeshInstance3D = $Farmer/rig/Skeleton3D/Legs
@onready var body_lower: MeshInstance3D = $Farmer/rig/Skeleton3D/LowerBody
@onready var body_upper: MeshInstance3D = $Farmer/rig/Skeleton3D/UpperBody
@onready var body_shoulder: MeshInstance3D = $Farmer/rig/Skeleton3D/Shoulder

@onready var ao_mesh_node: MeshInstance3D = $Farmer/rig/Skeleton3D/Base_002
@onready var quan_mesh_node: MeshInstance3D = $Farmer/rig/Skeleton3D/LongPants


@onready var seed_cast: RayCast3D = $SeedCast3D
@onready var anim: AnimationPlayer = $Farmer/AnimationPlayer
@onready var hoe: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Hoe
@onready var sickle: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Sickle
@onready var grid_check_ray: RayCast3D = $GridCheckRay
@onready var ground_gen = get_node_or_null("../GroundGenerator")
@onready var hl_select: MeshInstance3D = $HighlightSelector
@onready var interact_area: Area3D = $Interact_Area
@onready var tool_cast: RayCast3D = $HoeCast3D
@onready var watering: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Watering


@export var accel: float = 20.0
@export var use_gravity: bool = false
@export_node_path("Node3D") var camera_ref_path: NodePath
@export var player_actions : PlayerActions
@export var input: PlayerInput
@export var character : Character
@export var inventory_data: InventoryData


var blackboard : Blackboard
var last_block_pos: Vector2i = Vector2i(-1, -1)
var cam_ref: Node3D
var mouse_captured := true
var current_tool_name: String = "none"
var near_door: HouseDoor = null
var can_interact:bool = false
var equip_inventory_data: QuickInventoryData
var outfit_inventory_data: InventoryDataOutfit
var is_busy: bool = false:
	set(val):
		if !val && is_busy: action_finished.emit()
		is_busy = val
var body_parts_map = {}
var current_interactable: Node3D = null
var last_safe_position: Vector3
var safe_time_counter: float = 0.0


signal toggle_inventory()
signal action_finished


func _ready() -> void:
	super()
	GState.reset()
	
	Dialogic.timeline_started.connect(func(): 
		GState.dialog()
		_set_mouse_captured(false)
	)
	
	Dialogic.signal_event.connect(func(arg):
		if arg == "end_talk":
			if GState.is_dialog():
				GState.play()
				_set_mouse_captured(true)
	)
	
	Dialogic.timeline_ended.connect(func(): 
		if GState.is_dialog():
			GState.play()
			_set_mouse_captured(true)
	)
	
	GameData.game_state_changed.connect(func(old, new):
		_set_mouse_captured(true)
		
		if new == GState.state_enum.RECIPE \
		or new == GState.state_enum.COOK \
		or new == GState.state_enum.DIALOG \
		or new == GState.state_enum.UI \
		or new == GState.state_enum.SHOP:
			_set_mouse_captured(false)
	)
	
	PlayerData.player = self
	Watcher.player = self
	
	body_parts_map = {
		ItemDataOutfit.BodyPart.BASE:       body_base,
		ItemDataOutfit.BodyPart.FEETS:      body_feets,
		ItemDataOutfit.BodyPart.LEGS:       body_legs,
		ItemDataOutfit.BodyPart.LOWER_BODY: body_lower,
		ItemDataOutfit.BodyPart.UPPER_BODY: body_upper,
		ItemDataOutfit.BodyPart.SHOULDER: body_shoulder
	}
	interact_area.area_entered.connect(func(a): can_interact = true)
	interact_area.area_exited.connect(func(a): can_interact = false)
	
	if PlayerData.used_spawn_position == false:
		self.global_position = PlayerData.next_spawn_position
		PlayerData.used_spawn_position = true
	
	if self.inventory_data == null:
		self.inventory_data = PlayerData.player_inventory_data
	else:
		PlayerData.player_inventory_data = inventory_data
	self.equip_inventory_data = PlayerData.player_equip_data
	self.outfit_inventory_data = PlayerData.player_outfit_data
	interact_area.area_entered.connect(func(a): can_interact = true)
	interact_area.area_exited.connect(func(a): can_interact = false)
	
	# Bind camera
	if camera_ref_path != NodePath():
		cam_ref = get_node(camera_ref_path) as Node3D
	else:
		push_error("Player.gd: Chưa gán camera_ref_path (kéo SpringArm3D/Yaw vào).")
		set_physics_process(false)
	_set_mouse_captured(true)


	## Highlight Box
	hl_select.visible = false
	
	## Limbo Hierarchy Machine
	var hsm := get_node_or_null("LimboHSM")
	if hsm:
		blackboard = hsm.blackboard
	else:
		push_warning("Không tìm thấy LimboHSM => blackboard sẽ là null!")

## Outfit
	if outfit_inventory_data:
			outfit_inventory_data.inventory_updated.connect(update_all_outfits)
			update_all_outfits()

## Biking

	if PlayerData.is_transitioning_with_bike:
			await get_tree().process_frame 
			if limbo_hsm:
				(limbo_hsm as LimboPrimeHSM).dispatch("bike")
			# Fix the "biking virus while switching scene"
			PlayerData.is_transitioning_with_bike = false

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
	if not is_inside_tree(): 
		return
	if event.is_action_pressed("interact_mode"):
		_set_mouse_captured(false)
	elif event.is_action_released("interact_mode"):
		_set_mouse_captured(true)
		
	if event.is_action_pressed("recipe"):
		if !GState.is_cook() && !GState.is_recipe():
			GState.recipe()
		else: GState.play()
	
	if Input.is_action_just_pressed("inventory"):
		if GState.is_shop() or GState.is_dialog() or GState.is_cook() or GState.is_recipe():
			return 
		
		toggle_inventory.emit()
	
	if Input.is_action_just_pressed("interact"):
		if GState.is_shop():
			var ui = get_tree().get_first_node_in_group("inventory_interface")
			if ui:
				ui.close_shop_interface() 
			return

		if GState.is_cook() or GState.is_recipe() or GState.is_ui():
			GState.play()
		elif can_interact:
			interact()

	if event.is_action_pressed("use_item") and not is_busy:
		if Watcher.indoor:
			var current_slot = HotBar.active_slot
			if current_slot and current_slot.item_data is ItemDataTool:
				print("🚫 Không thể dùng công cụ trong nhà!")
				return
		(limbo_hsm as LimboPrimeHSM).use_item = true
		print("DEBUG: Use item pressed, current_tool_name =", current_tool_name)
	if event.is_action_released("use_item"):
		(limbo_hsm as LimboPrimeHSM).use_item = false

func interact():
	(interact_area.get_overlapping_areas()[0] as InteractArea).interacted.emit()

func get_drop_position() -> Vector3:
	var direction = grid_check_ray.global_position
	return direction

func _physics_process(delta: float) -> void:
	super(delta)
	
	RenderingServer.global_shader_parameter_set("player_position", global_position)

	
	if bt_player:
		bt_player.update(delta)

	if is_on_floor():
			safe_time_counter += delta
			if safe_time_counter > 2:
				last_safe_position = global_position
	else:
		safe_time_counter = 0.0

func register_interactable(object):
	current_interactable = object
	print("Đã vào vùng - Hiện UI Interact")
	

func unregister_interactable(object):
	if current_interactable == object:
		current_interactable = null
		print("Đã ra khỏi vùng - Ẩn UI")


func update_all_outfits(_inventory_data = null):
	if not outfit_inventory_data: return
	
	for part_node in body_parts_map.values():
		if part_node: 
			part_node.visible = true

	var slot_count = outfit_inventory_data.slot_datas.size()

	# Slot 1:
	if slot_count > 1: 
		apply_outfit_visual(1, ao_mesh_node) 
	
	# Slot 2:
	if slot_count > 2: 
		apply_outfit_visual(2, quan_mesh_node)


func apply_outfit_visual(slot_index: int, target_mesh_node: MeshInstance3D):
	if not target_mesh_node: return
	
	var slot_data = outfit_inventory_data.slot_datas[slot_index]
	
	
	if slot_data and slot_data.item_data and slot_data.item_data is ItemDataOutfit:
		var item_outfit = slot_data.item_data as ItemDataOutfit
		
		
		target_mesh_node.mesh = item_outfit.equip_mesh
		target_mesh_node.visible = true
		if target_mesh_node.mesh:
			target_mesh_node.set_surface_override_material(0, null)
		
		# 2.Hide Body Part
		#print("--- Outfit equipped slot: ", slot_index, " ---")
		for part_enum in item_outfit.hidden_body_parts:
			if body_parts_map.has(part_enum):
				var body_part_node = body_parts_map[part_enum]
				if body_part_node:
					body_part_node.visible = false
					#print("Hide body part: ", body_part_node.name)
	else:
		target_mesh_node.mesh = null
		target_mesh_node.visible = false



func _set_mouse_captured(enable: bool) -> void:
	mouse_captured = enable
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)


func is_interact_mode() -> bool:
	return not mouse_captured

func try_harvest_crop(crop):
		crop.harvest()
