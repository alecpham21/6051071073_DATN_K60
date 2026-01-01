class_name Player
extends Character

# MESHES & NODES
@onready var body_base: MeshInstance3D = $Farmer/rig/Skeleton3D/Base
@onready var body_feets: MeshInstance3D = $Farmer/rig/Skeleton3D/Feets
@onready var body_legs: MeshInstance3D = $Farmer/rig/Skeleton3D/Legs
@onready var body_lower: MeshInstance3D = $Farmer/rig/Skeleton3D/LowerBody
@onready var body_upper: MeshInstance3D = $Farmer/rig/Skeleton3D/UpperBody
@onready var body_shoulder: MeshInstance3D = $Farmer/rig/Skeleton3D/Shoulder
@onready var ao_mesh_node: MeshInstance3D = $Farmer/rig/Skeleton3D/Base_002
@onready var quan_mesh_node: MeshInstance3D = $Farmer/rig/Skeleton3D/LongPants

# TOOLS & NODES
@onready var hoe: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Hoe
@onready var sickle: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Sickle
@onready var watering: Node3D = $Farmer/rig/Skeleton3D/BoneAttachment3D/Watering
@onready var seed_cast: RayCast3D = $SeedCast3D
@onready var tool_cast: RayCast3D = $HoeCast3D
@onready var grid_check_ray: RayCast3D = $GridCheckRay
@onready var interact_area: Area3D = $Interact_Area
@onready var anim: AnimationPlayer = $Farmer/AnimationPlayer
@onready var hl_select: MeshInstance3D = $HighlightSelector
@onready var ground_gen = get_node_or_null("../GroundGenerator")
@onready var building_manager: BuildingManager = get_node_or_null("../BuildingManager")

# EXPORTS
@export var accel: float = 20.0
@export var use_gravity: bool = false
@export_node_path("Node3D") var camera_ref_path: NodePath
@export var inventory_data: InventoryData

# VARIABLES
var blackboard : Blackboard
var cam_ref: Node3D
var last_block_pos: Vector2i = Vector2i(-1, -1)
var mouse_captured := true
var can_interact: bool = false
var current_tool_name: String = "none"
var near_door: HouseDoor = null
var current_interactable: Node3D = null
var equip_inventory_data: QuickInventoryData
var outfit_inventory_data: InventoryDataOutfit
var last_safe_position: Vector3
var safe_time_counter: float = 0.0
var body_parts_map = {}
var is_busy: bool = false:
	set(val):
		if !val && is_busy: action_finished.emit()
		is_busy = val

signal toggle_inventory()
signal action_finished

func _ready() -> void:
	super()
	GState.reset()
	PlayerData.player = self
	Watcher.player = self
	
	if self.inventory_data == null:
		self.inventory_data = PlayerData.player_inventory_data
	else:
		PlayerData.player_inventory_data = self.inventory_data
		
	self.equip_inventory_data = PlayerData.player_equip_data
	self.outfit_inventory_data = PlayerData.player_outfit_data
	
	# Spawn Position logic
	if PlayerData.used_spawn_position == false:
		self.global_position = PlayerData.next_spawn_position
		PlayerData.used_spawn_position = true

	_setup_dialog_connections()
	_setup_game_state_connections()
	
	body_parts_map = {
		ItemDataOutfit.BodyPart.BASE: body_base,
		ItemDataOutfit.BodyPart.FEETS: body_feets,
		ItemDataOutfit.BodyPart.LEGS: body_legs,
		ItemDataOutfit.BodyPart.LOWER_BODY: body_lower,
		ItemDataOutfit.BodyPart.UPPER_BODY: body_upper,
		ItemDataOutfit.BodyPart.SHOULDER: body_shoulder
	}
	
	interact_area.area_entered.connect(func(a): can_interact = true)
	interact_area.area_exited.connect(func(a): can_interact = false)
	
	if outfit_inventory_data:
		outfit_inventory_data.inventory_updated.connect(update_all_outfits)
		update_all_outfits()
	
	if camera_ref_path:
		cam_ref = get_node(camera_ref_path)
	_set_mouse_captured(true)
	
	if limbo_hsm: blackboard = limbo_hsm.blackboard
	if PlayerData.is_transitioning_with_bike:
		await get_tree().process_frame
		if limbo_hsm: (limbo_hsm as LimboPrimeHSM).dispatch("bike")
		PlayerData.is_transitioning_with_bike = false

func _process(_delta):
	_update_highlight_selector()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_mode"): _set_mouse_captured(false)
	elif event.is_action_released("interact_mode"): _set_mouse_captured(true)
	
	if event.is_action_pressed("click"):
		if GState.is_build():
			print("🖱️ Player: Bắt được action 'click'!")
			
			if building_manager:
				building_manager.place_building()
				get_viewport().set_input_as_handled()
			else:
				printerr("❌ Player: Không tìm thấy BuildingManager!")
			return
	

	
	if event.is_action_pressed("ui_cancel"):
		if GState.is_build():
			GState.play()
			if building_manager: building_manager.cancel_build()
			return
			
		if !GState.is_playing(): GState.play()
	
	if event.is_action_pressed("build"):
		if GState.is_playing():
			GState.build()
			print("🔨 Vào chế độ xây dựng")
		elif GState.is_build():
			GState.play()
			if building_manager: building_manager.cancel_build()
			print("❌ Thoát chế độ xây dựng")
	
	if GState.is_build():
		return
	
	if event.is_action_pressed("recipe"):
		if !GState.is_cook() && !GState.is_recipe(): GState.recipe()
		else: GState.play()
	
	if event.is_action_pressed("toggle_journal"):
		if GState.is_shop() or GState.is_dialog() or GState.is_cook() or GState.is_build():
			return
			
		var journal = get_tree().get_first_node_in_group("quest_journal")
		if journal: journal.toggle_ui()
	
	
	if Input.is_action_just_pressed("inventory"):
		if not (GState.is_shop() or GState.is_dialog() or GState.is_cook() or GState.is_build()):
			toggle_inventory.emit()

	if Input.is_action_just_pressed("interact"):
		if GState.is_shop():
			var ui = get_tree().get_first_node_in_group("inventory_interface")
			if ui: ui.close_shop_interface()
			return
			
		if GState.is_cook() or GState.is_recipe() or GState.is_ui():
			GState.play()
			return
			
		elif can_interact:
			interact()

	if event.is_action_pressed("use_item") and not is_busy:
		if Watcher.indoor:
			var current_slot = HotBar.active_slot
			if current_slot and current_slot.item_data is ItemDataTool: return
		if limbo_hsm: (limbo_hsm as LimboPrimeHSM).use_item = true
		
	if event.is_action_released("use_item"):
		if limbo_hsm: (limbo_hsm as LimboPrimeHSM).use_item = false

func _physics_process(delta: float) -> void:
	RenderingServer.global_shader_parameter_set("player_position", global_position)
	if limbo_hsm: limbo_hsm.update(delta)
	if bt_player: bt_player.update(delta) # Khôi phục

	if is_on_floor():
		safe_time_counter += delta
		if safe_time_counter > 2.0: last_safe_position = global_position
	else:
		safe_time_counter = 0.0

# --- CÁC HÀM TIỆN ÍCH KHÔI PHỤC ---
func interact():
	var areas = interact_area.get_overlapping_areas()
	if areas.size() > 0: (areas[0] as InteractArea).interacted.emit()

func register_interactable(object):
	current_interactable = object

func unregister_interactable(object):
	if current_interactable == object: current_interactable = null

func get_drop_position() -> Vector3:
	return grid_check_ray.global_position

func try_harvest_crop(crop):
	crop.harvest()

func _update_highlight_selector():
	if not HotBar.active_item or not (HotBar.active_item is ItemDataTool):
		hl_select.visible = false
		return
	
	if not ground_gen or not grid_check_ray.is_colliding():
		hl_select.visible = false
		return
	var hit_pos = grid_check_ray.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	var data = ground_gen.block_data
	if grid_pos.x >= 0 and grid_pos.x < data.size() and grid_pos.y >= 0 and grid_pos.y < data[0].size():
		hl_select.global_position = ground_gen.get_world_pos_from_grid(grid_pos) + Vector3(0, 0.02, 0)
		hl_select.scale = Vector3(ground_gen.renderer.spacing, 1, ground_gen.renderer.spacing)
		hl_select.global_rotation = Vector3.ZERO
		hl_select.visible = true
	else:
		hl_select.visible = false

func update_all_outfits(_data = null):
	for node in body_parts_map.values(): if node: node.visible = true
	if outfit_inventory_data.slot_datas.size() > 1: apply_outfit_visual(1, ao_mesh_node)
	if outfit_inventory_data.slot_datas.size() > 2: apply_outfit_visual(2, quan_mesh_node)

func apply_outfit_visual(slot_idx, target_node):
	if not target_node: return
	var slot = outfit_inventory_data.slot_datas[slot_idx]
	if slot and slot.item_data is ItemDataOutfit:
		target_node.mesh = slot.item_data.equip_mesh
		target_node.visible = true
		for part in slot.item_data.hidden_body_parts:
			if body_parts_map.has(part): body_parts_map[part].visible = false
	else:
		target_node.mesh = null
		target_node.visible = false

func _set_mouse_captured(enable: bool) -> void:
	mouse_captured = enable
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE)

func _setup_dialog_connections():
	Dialogic.timeline_started.connect(func(): GState.dialog(); _set_mouse_captured(false))
	Dialogic.timeline_ended.connect(func(): if GState.is_dialog(): GState.play(); _set_mouse_captured(true))

func _setup_game_state_connections():
	GameData.game_state_changed.connect(func(old, new):
		var ui_states = [
			GState.state_enum.RECIPE, 
			GState.state_enum.COOK, 
			GState.state_enum.DIALOG, 
			GState.state_enum.UI, 
			GState.state_enum.SHOP, 
			GState.state_enum.JOURNAL,
			GState.state_enum.BUILD
		]
		_set_mouse_captured(new not in ui_states)
	)
