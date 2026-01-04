extends MainState
class_name HarvestingState

@export_group("Animations")
@export var hand_ani: AnimationSet
@export var hand_crouch_ani: AnimationSet
@export var knife_ani: AnimationSet
@export var sickle_ani: AnimationSet
@export var sickle_stand_ani: AnimationSet

enum HarvestStance { STANDING = 0, CROUCHING = 1 }

func _setup() -> void:
	super()
	if safe_guard: overtimed.connect(func(): dispatch("idle"); print("overtimed"))

func _enter() -> void:
	super()
	
	if not character.stats.has_stamina(character.stats.action_cost):
		print("⚡ Not enought stamina mina ey")
		dispatch("idle")
		return
	
	character.is_busy = true
	
	var target_info = _get_target_info((character as Player).tool_cast, limbo_hsm.ground_gen)
	var req_stance = target_info.stance
	var allow_tool = target_info.can_tool
	
	var anim_to_play: AnimationSet
	
	var is_hand = HotBar.hand()
	var is_sickle = HotBar.active_item and HotBar.active_item.name.to_lower() == "sickle"
	var has_tool = HotBar.active_item != null
	
	if has_tool and not allow_tool:
		print("🚫 Only Hand")
		character.is_busy = false
		dispatch("idle")
		return
	
	if req_stance == HarvestStance.CROUCHING:
		if is_hand:
			anim_to_play = hand_crouch_ani
		else:
			anim_to_play = sickle_ani
			
	else: # STANDING
		if is_hand:
			anim_to_play = hand_ani
		elif is_sickle:
			anim_to_play = sickle_stand_ani if sickle_stand_ani else knife_ani
		else:
			anim_to_play = knife_ani 

	if not anim_to_play: anim_to_play = hand_ani
	
	anim_to_play.play(character.ani)
		
	character.ani.animation_finished.connect(func(a):
		harvest((character as Player).tool_cast, limbo_hsm.ground_gen)
		
		if has_tool:
			character.stats.consume(character.stats.action_cost)
		else:
			character.stats.consume(character.stats.action_cost * 0.5)
		
		dispatch("idle")
		, CONNECT_ONE_SHOT)

func _exit() -> void:
	super()
	character.is_busy = false

func _get_target_info(cast: RayCast3D, ground_gen) -> Dictionary:
	var result = { "stance": HarvestStance.STANDING, "can_tool": true }
	
	cast.force_raycast_update()
	
	if cast.is_colliding():
		var collider = cast.get_collider()
		var object_hit = collider.get_parent()
		
		if "harvest_stance" in object_hit: 
			result.stance = object_hit.harvest_stance
			if "can_use_tool" in object_hit: 
				result.can_tool = object_hit.can_use_tool
			return result
			
	if ground_gen and cast.is_colliding():
		var hit_pos = cast.get_collision_point()
		var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
		
		if ground_gen.is_valid_grid_pos(grid_pos):
			var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
			
			if block.mode == BlockGroundData.Mode.GRASS:
				result.stance = HarvestStance.CROUCHING
				result.can_tool = true
	
	return result

func harvest(cast: RayCast3D, ground_gen) -> void:
	var target = character.current_interactable
	if target != null and target.has_method("harvest"):
		if target.get("is_harvestable"):
			target.harvest()
			print("✅ Harvest from area")
			PlayerData.add_dirt_to_outfit(2.0)
			return
	
	cast.force_raycast_update()
	if not cast.is_colliding(): return

	var collider = cast.get_collider()
	var object_hit = collider.get_parent() 
	
	if object_hit.has_method("harvest"):
		if object_hit.get("is_harvestable") == true: 
			object_hit.harvest()
			print("✅ Trúng Hitbox Cây Trồng")
			PlayerData.add_dirt_to_outfit(3.0)
			return
		else:
			print("🚫 Cây chưa chín")
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
			
			var found_grass = false
			for child in ground_gen.get_children():
				if child.get("current_grid_pos") == grid_pos:
					child.queue_free()
					found_grass = true
					break 
			
			if found_grass:
				SignalBus.object_harvested.emit("wind_grass", 1)

			PlayerData.add_dirt_to_outfit(2.0)
