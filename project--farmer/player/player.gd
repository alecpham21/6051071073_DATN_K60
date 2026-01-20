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
@onready var hold_position: Marker3D = $Farmer/HoldPosition
#Side
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
var carried_node: Node3D = null
var body_parts_map = {}
var is_busy: bool = false:
	set(val):
		if !val && is_busy: action_finished.emit()
		is_busy = val
var is_regenerating: bool = true
const PICKUP_SCENE = preload("res://inventory_script/item/pick_up_item/pick_up.tscn")

signal toggle_inventory()
signal action_finished

func _ready() -> void:
	super()
	GState.reset()
	PlayerData.player = self
	Watcher.player = self
	
	if self.stats == null:
		self.stats = PlayerData.stats
	else:
		PlayerData.stats = self.stats
	
	print("🔍 [Player] Stats ID: ", self.stats.get_instance_id())
	print("📊 Current Modifiers: ", self.stats.max_stamina_modifiers)
	
	if stats:
		await get_tree().process_frame
		stats.stamina_changed.emit(stats.stamina, stats.get_max_stamina())
	
	if self.inventory_data == null:
		self.inventory_data = PlayerData.player_inventory_data
	else:
		PlayerData.player_inventory_data = self.inventory_data
		
	self.equip_inventory_data = PlayerData.player_equip_data
	self.outfit_inventory_data = PlayerData.player_outfit_data
	
	
	if PlayerData.used_spawn_position == false:
		self.global_position = PlayerData.next_spawn_position
		PlayerData.used_spawn_position = true
	
	
	_setup_dialog_connections()
	_setup_game_state_connections()
	
	await get_tree().process_frame 
	var inv_interface = get_tree().get_first_node_in_group("inventory_interface")
	if inv_interface:
		if not inv_interface.drop_slot_data.is_connected(_on_drop_item_from_ui):
			inv_interface.drop_slot_data.connect(_on_drop_item_from_ui)
	
	body_parts_map = {
		ItemDataOutfit.BodyPart.BASE: body_base,
		ItemDataOutfit.BodyPart.FEETS: body_feets,
		ItemDataOutfit.BodyPart.LEGS: body_legs,
		ItemDataOutfit.BodyPart.LOWER_BODY: body_lower,
		ItemDataOutfit.BodyPart.UPPER_BODY: body_upper,
		ItemDataOutfit.BodyPart.SHOULDER: body_shoulder
	}
	
	
	interact_area.area_entered.connect(func(area):
		can_interact = true
		current_interactable = area
	)
	
	interact_area.area_exited.connect(func(area):
		can_interact = false
		current_interactable = null
	)
	
	
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
	
	if SignalBus.has_signal("item_dropped"):
		SignalBus.item_dropped.connect(_on_external_item_dropped)

func _process(_delta):
	_update_highlight_selector()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_mode"): _set_mouse_captured(false)
	elif event.is_action_released("interact_mode"): _set_mouse_captured(true)
	
	
	if event.is_action_pressed("ui_cancel"):
		if GState.is_build():
			GState.play()
			if building_manager: building_manager.cancel_build()
			return
		if !GState.is_playing(): GState.play()
	
	if event.is_action_pressed("build"):
		if GState.is_playing():
			GState.build()
			print("Building In")
		elif GState.is_build():
			GState.play()
			if building_manager: building_manager.cancel_build()
			print("Building Out")
	
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

	if event.is_action_pressed("interact"):
		if GState.is_shop() or GState.is_ui() or GState.is_cook() or GState.is_recipe() or GState.is_coop():
			var inv_interface = get_tree().get_first_node_in_group("inventory_interface")
			if GState.is_shop() and inv_interface:
				inv_interface.close_shop_interface()
			else:
				GState.play()
				if inv_interface:
					inv_interface.visible = false
					inv_interface.clear_external_inventory()
			get_viewport().set_input_as_handled()
			return

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
	if bt_player: bt_player.update(delta)

	if is_on_floor() and not is_busy and blackboard:
		var is_running = blackboard.get_var(BBNames.run_var, false)
		if not is_running and stats: 
			stats.regenerate(stats.get_restore_speed() * delta)

	if is_on_floor():
		safe_time_counter += delta
		if safe_time_counter > 2.0: last_safe_position = global_position
	else:
		safe_time_counter = 0.0

var stink_dialogues = [
	"I am so dirty ",
	"Did someone just throw a garbage",
	"I should clean my outfit",
	"My nose gonna deaf...",
	"I smell something "
]

func interact():
	if not current_interactable: return
	
	var target_node = current_interactable.get_parent()
	if PlayerData.is_player_stinky() and target_node and target_node.is_in_group("npc"):
		Dialogic.VAR.stink_line_eng = stink_dialogues.pick_random()
		Dialogic.start("timeline_stinky")
		return

	if current_interactable is InteractArea:
		current_interactable.interacted.emit()

func register_interactable(object):
	current_interactable = object

func unregister_interactable(object):
	if current_interactable == object: current_interactable = null

func get_drop_position() -> Vector3:
	return grid_check_ray.global_position

func try_harvest_crop(crop):
	crop.harvest()
	print("Ray Colliding: ", grid_check_ray.is_colliding())

func _update_highlight_selector():
	if not HotBar.active_item or not (HotBar.active_item is ItemDataTool):
		hl_select.visible = false
		return
	
	if not ground_gen:
		hl_select.visible = false
		return

	tool_cast.force_raycast_update()

	if not tool_cast.is_colliding():
		hl_select.visible = false
		return
		
	var hit_pos = tool_cast.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	var data = ground_gen.block_data
	
	if grid_pos.x >= 0 and grid_pos.x < data.size() and grid_pos.y >= 0 and grid_pos.y < data[0].size():
		hl_select.global_position = ground_gen.get_world_pos_from_grid(grid_pos) + Vector3(0, 0.05, 0)
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
			GState.state_enum.BUILD,
			GState.state_enum.COOP
		]
		_set_mouse_captured(new not in ui_states)
	)

func _on_drop_item_from_ui(slot_data: SlotData) -> void:
	if not is_inside_tree() or slot_data == null:
		return
		
	var throw_dir = -global_transform.basis.z 
	
	var pickup = PICKUP_SCENE.instantiate()
	pickup.slot_data = slot_data
	
	var drop_pos = global_position + Vector3(0, 1.2, 0)
	pickup.global_position = drop_pos
	
	var p = get_parent()
	if p:
		p.call_deferred("add_child", pickup)
		
		pickup.ready.connect(func():
			var throw_force = (throw_dir * 3.0) + Vector3(0, 2.0, 0)
			pickup.apply_impulse(throw_force)
		, CONNECT_ONE_SHOT)

func _on_external_item_dropped(item_data: ItemData, amount: int, target_pos: Vector3) -> void:
	if not item_data: return
	
	var new_slot = SlotData.new()
	new_slot.item_data = item_data
	new_slot.quantity = amount
	
	var pickup = PICKUP_SCENE.instantiate()
	pickup.slot_data = new_slot
	
	if target_pos == Vector3.ZERO:
		pickup.global_position = global_position + Vector3(0, 1.5, 0)
	else:
		pickup.global_position = target_pos
	
	get_parent().add_child(pickup)
	
	var throw_force = Vector3(randf_range(-1, 1), 2.0, randf_range(-1, 1)).normalized() * 2.0
	if pickup.has_method("apply_impulse"):
		pickup.apply_impulse(throw_force)
		
	print("Spawned dropped item: ", item_data.name)

func pick_up_object(obj: Node3D) -> void:
	if carried_node != null or obj == null: return
	
	var target = obj
	if target is Area3D:
		target = target.get_parent()
	
	carried_node = target
	print("Pick up: ", carried_node.name)
	
	var old_parent = carried_node.get_parent()
	if old_parent:
		old_parent.remove_child(carried_node)
	
	hold_position.add_child(carried_node)
	carried_node.position = Vector3.ZERO
	carried_node.rotation = Vector3.ZERO
	
	if carried_node.has_method("set_carried"):
		carried_node.set_carried(true)

func place_down_object() -> void:
	if carried_node == null: return
	
	var drop_pos = global_position + (-global_transform.basis.z * 1.5)
	
	if seed_cast.is_colliding():
		var hit_pos = seed_cast.get_collision_point()
		drop_pos = Vector3(round(hit_pos.x), hit_pos.y, round(hit_pos.z))
	
	print("Place down at: ", drop_pos)
	
	hold_position.remove_child(carried_node)
	
	if ground_gen:
		ground_gen.add_child(carried_node)
	else:
		get_parent().add_child(carried_node)
	
	carried_node.global_position = drop_pos
	carried_node.rotation = Vector3.ZERO
	
	if carried_node.has_method("set_carried"):
		carried_node.set_carried(false)
		
	carried_node = null
