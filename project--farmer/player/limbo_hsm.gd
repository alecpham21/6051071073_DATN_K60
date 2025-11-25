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

func _ready() -> void:
	initialize(character)
	if PlayerData.player_inventory_data:
		PlayerData.player_inventory_data.item_used_up.connect(_on_item_used_up)
func _update(delta: float) -> void:
	if HotBar.active_slot && HotBar.active_item is ItemDataTool:
		long_tool = (HotBar.active_item as ItemDataTool).is_long_tool
	else: long_tool = false

func _binding_setup():
	for i : StateSet in state_set.values():
		var key : StringName = state_set.find_key(i)
		# Take node from path
		var state : CharacterState = get_node(i.state_path) as CharacterState
		# Error if not state
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
		print("AAAAAAAAAAAAAAAA")

func can_plant() -> bool:
	if not HotBar.active_slot or not HotBar.active_item:
		return false
	if HotBar.active_slot.quantity <= 0:
		return false
	return HotBar.active_item && HotBar.active_item.name.to_lower().ends_with("seed") && use_item \
	&& get_block().mode == BlockGround.Mode.TILLED && !Watcher.indoor 

func can_till() -> bool:
	return HotBar.active_item && HotBar.active_item.name.to_lower() == "hoe" && use_item && !Watcher.indoor

func can_harvest() -> bool:
	var block = get_block()
	return (block && block.crop_ready) && use_item \
	&& (HotBar.active_item == null || HotBar.active_item.name.to_lower() == "sickle") && !Watcher.indoor
	
func get_block():
	var block = null
	if !ground_gen: return block
	if character.seed_cast.is_colliding():
		var hit_pos = character.seed_cast.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
		block = ground_gen.block_data[grid_pos.x][grid_pos.y]
	return block
