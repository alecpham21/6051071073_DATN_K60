extends MainState
class_name CareState

@export_group("Animations")
@export var water_ani: AnimationSet
@export var fertilize_ani: AnimationSet
@export var debug_ani: AnimationSet # Destroy the bug

@onready var ground_gen = get_tree().get_first_node_in_group("ground_generator")

var has_water: bool = true
const WATER_SPLASH_VFX = preload("res://Scene/vfx/water_splash.tscn")
const WATERING_SOUND = preload("res://audio/watering cutted.wav")
const WATERING_SOUND_2 = preload("res://audio/watering_cutted_2.wav")


func _enter() -> void:
	super()
	character.is_busy = true
	character.velocity = Vector3.ZERO
	var slot_data = HotBar.active_slot
	var item_name = HotBar.active_item.name.to_lower()
	
	if "watering" in item_name:
		var current_water = slot_data.get_stat("water_current")
		if current_water > 0:
			has_water = true
			if water_ani: water_ani.play(character.ani)
			
			get_tree().create_timer(0.4).timeout.connect(func(): 
				if character.is_busy: 
					apply_care_effect(item_name)
			)
			
		else:
			has_water = false
			print("🕳️ No water in can")
			dispatch("idle")
			return
			
	elif "fertilizer" in item_name:
		if fertilize_ani: fertilize_ani.play(character.ani)
		get_tree().create_timer(0.4).timeout.connect(func():
			if character.is_busy:
				apply_care_effect(item_name)
		)
		
	if character.ani.is_playing():
		character.ani.animation_finished.connect(func(a):
			dispatch("idle")
			, CONNECT_ONE_SHOT)
	else:
		dispatch("idle")

func _exit() -> void:
	super()
	character.is_busy = false

func apply_care_effect(tool_name: String) -> void:
	var cast = (character as Player).tool_cast
	cast.force_raycast_update()
	
	if not cast.is_colliding():
		return
	
	var hit_pos = cast.get_collision_point()
	var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	
	if not ground_gen.is_valid_grid_pos(grid_pos):
		return
	
	var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
	var slot_data = HotBar.active_slot
	
	
	if "watering" in tool_name:
		var current_water = slot_data.get_stat("water_current")
		
		if current_water > 0:
			block.is_watered = true
			
			if ground_gen.has_method("get_plant_node"):
				var plant_node = ground_gen.get_plant_node(grid_pos)
				
				if plant_node:
					plant_node.update_visuals()
			
			print("💧 Đã tưới. Nước còn: %s" % (current_water - 1))
			
			var vfx = WATER_SPLASH_VFX.instantiate()
			get_tree().root.add_child(vfx)
			vfx.global_position = hit_pos
			vfx.global_position.y += 0.4
			
			var sfx = AudioStreamPlayer3D.new()
			
			var watering_sounds = [WATERING_SOUND, WATERING_SOUND_2]
			sfx.stream = watering_sounds.pick_random()
			
			sfx.unit_size = 5.0
			sfx.max_db = 2.0
			sfx.bus = "SFX"
			sfx.pitch_scale = randf_range(0.9, 1.1) 
			
			get_tree().root.add_child(sfx)
			sfx.global_position = hit_pos
			sfx.finished.connect(sfx.queue_free)
			sfx.play()

			slot_data.set_stat("water_current", current_water - 1)
			
			PlayerData.player_inventory_data.inventory_updated.emit(PlayerData.player_inventory_data)
	
	elif "fertilizer" in tool_name:
		if block.plant_type != PlantDatabase.PLANT_VARIANT.NONE:
			var plant_node = ground_gen.get_plant_node(grid_pos)
			if plant_node and plant_node.has_method("apply_fertilizer"):
				if not plant_node.is_fertilized:
					plant_node.apply_fertilizer()
					print("✨ Fertilizer applied to: ", grid_pos)
				
					var index = PlayerData.player_inventory_data.slot_datas.find(HotBar.active_slot)
					if index != -1:
						PlayerData.player_inventory_data.actual_use_slot_data(index)
			else:
				print("Already fertilized.")
