extends LimboHSM
class_name LimboPrimeHSM

@export var character : Character
@export var state_set : Dictionary[StringName, StateSet]
@export var idle_aniset:AnimationSet
@export var walk_aniset:AnimationSet
@onready var ground_gen = get_tree().get_first_node_in_group("ground_generator")

var ani_set : AnimationSet
var states : Dictionary[StringName, CharacterState]
var prev:CharacterState
var use_item:bool = false
var long_tool:bool = false
var cook = false
enum COOK_MODE { STOVE = 0, BOARD = 1 }
var cook_mode: int = COOK_MODE.STOVE

func _ready() -> void:
	initialize(character)
	if PlayerData.player_inventory_data:
		PlayerData.player_inventory_data.item_used_up.connect(_on_item_used_up)


func _update(delta: float) -> void:
	if blackboard:
		use_item = blackboard.get_var(BBNames.use_item_var, false)
		
		if blackboard.get_var(BBNames.toggle_vehicle_var, false):
			var active = get_active_state()
			if active:
				if active.name == "BikingState":
					dispatch("idle")
				elif active.name == "IdleState" or active.name == "WalkState":
					dispatch("bike")
	
	if HotBar.active_slot && HotBar.active_item is ItemDataTool:
		long_tool = (HotBar.active_item as ItemDataTool).is_long_tool
	else: 
		long_tool = false
		
	if cook:
		dispatch("cook")

func _binding_setup():
	for i : StateSet in state_set.values():
		var key : StringName = state_set.find_key(i)
		var state : CharacterState = get_node(i.state_path) as CharacterState
		if not state:
			push_error("LimboPrimeHSM: state_path wrong in StateSet '%s'" % key)
			continue
		
		if state.play_default_ani: 
			state.ani_set = i.ani_set
		state.limbo_hsm = self 
		states.get_or_add(key, state)

func _on_item_used_up():
	if HotBar.active_item and HotBar.active_item.name.to_lower().ends_with("seed"):
		HotBar.active_item = null
		HotBar.active_slot = null

func can_plant() -> bool:
	var is_using = blackboard.get_var(BBNames.use_item_var, false)
	
	if not HotBar.active_slot or not HotBar.active_item:
		return false
	if HotBar.active_slot.quantity <= 0:
		return false
	return HotBar.active_item && HotBar.active_item.name.to_lower().ends_with("seed") && use_item \
	&& get_block().mode == BlockGround.Mode.TILLED 

func can_till() -> bool:
	var is_using = blackboard.get_var(BBNames.use_item_var, false)
	
	var basic_check = HotBar.active_item \
		&& HotBar.active_item.name.to_lower() == "hoe" \
		&& use_item

	if not basic_check:
		return false
		
	var block = get_block()
	if block == null:
		return false
		
	if block.mode == BlockGroundData.Mode.CUT or block.mode == BlockGroundData.Mode.GRASS:
		return true
		
	return false


func can_harvest() -> bool:
	if not use_item: return false

	# 1. Check tương tác vật lý (Cây tre, măng...)
	if character.current_interactable != null:
		var target = character.current_interactable
		if target.get("is_harvestable") == true:
			return true
			
	# 2. Check Block đất
	var block = get_block()
	if not block: return false
	
	if block.crop_ready:
		if HotBar.active_item == null or HotBar.active_item.name.to_lower() == "sickle":
			return true

	if HotBar.active_item and HotBar.active_item.name.to_lower() == "sickle":
		if block.mode == BlockGroundData.Mode.GRASS:
			return true
			
	return false


func can_care() -> bool:
	var is_using = blackboard.get_var(BBNames.use_item_var, false)
	
	if not HotBar.active_slot or not HotBar.active_item:
		return false
	
	var item_name = HotBar.active_item.name.to_lower()
	
	var is_care_tool = item_name.contains("watering") or \
					   item_name.contains("fertilizer") or \
					   item_name.contains("debugging")
					
	if is_care_tool and use_item and !Watcher.indoor:
		var block = get_block()
		if block:
			return block.mode == BlockGroundData.Mode.TILLED or \
				   block.mode == BlockGroundData.Mode.PLANTED
	
	return false


func get_block():
	var block = null
	if !ground_gen: return block
	if character.seed_cast.is_colliding():
		var hit_pos = character.seed_cast.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
		block = ground_gen.block_data[grid_pos.x][grid_pos.y]
	return block
