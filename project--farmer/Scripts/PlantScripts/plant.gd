extends Node3D
class_name Plant

@export_group("Growth Stats")
@export var max_growth: int = 15
@export var growth_chance: float = 0.1
@export var day_time_multiply: float = 1.5
@export var harvest_yield: int = 2

@export_group("Resources")
@export var crop_item_scene: PackedScene
@export var material_default: StandardMaterial3D 
@export var material_seeding: StandardMaterial3D 

@export_group("Visual Nodes")
@export var mesh_seeding: Node3D
@export var mesh_sapling: Node3D
@export var mesh_middle: Node3D
@export var mesh_ready: Node3D
@export var ground_mesh: MeshInstance3D

var block_data_reference = null
var current_growth: int = 0
var is_harvestable: bool = false
var current_grid_pos: Vector2i

func _ready():
	TimeManager.tick.connect(_on_tick_process)
	update_visuals()

func _on_tick_process():
	if is_harvestable: return
	
	# Kiểm tra nước trước, nếu không có nước thì nghỉ khỏe, khỏi tính toán
	var parent_generator = get_parent()
	if parent_generator and "block_data" in parent_generator:
		var block = parent_generator.block_data[current_grid_pos.x][current_grid_pos.y]
		if block.is_watered == false:
			return # Đất khô thì không lớn
	
	# Logic tính tỉ lệ lớn (giữ nguyên của bạn)
	var current_minutes = TimeManager.current_time
	var hour = int(current_minutes / 60)
	var is_daytime = hour >= 6 and hour < 18
	
	var final_chance = growth_chance
	if is_daytime:
		final_chance *= day_time_multiply
	
	if randf() < final_chance:
		grow()


func get_stage_id() -> int:
	var progress = float(current_growth) / float(max_growth)
	if progress >= 1.0: return 3
	if progress > 0.5: return 2
	if progress > 0.2: return 1
	return 0

func grow():
	var old_stage = get_stage_id()
	
	current_growth += 1
	
	var new_stage = get_stage_id()
	
	if new_stage > old_stage:
		var parent_generator = get_parent()
		if parent_generator and "block_data" in parent_generator:
			var block = parent_generator.block_data[current_grid_pos.x][current_grid_pos.y]
			block.is_watered = false
			_set_soil_wet(false) 

	if current_growth >= max_growth:
		current_growth = max_growth
		is_harvestable = true
		if get_parent().has_method("on_crop_ready"):
			get_parent().on_crop_ready(self)
			
	update_visuals()

func update_visuals():
	pass

func _set_soil_wet(is_wet: bool):
	if not ground_mesh: return
	
	if is_wet and material_seeding:
		ground_mesh.set_surface_override_material(0, material_seeding)
	elif material_default:
		ground_mesh.set_surface_override_material(0, material_default)

func harvest():
	if not is_harvestable: return
	spawn_items()
	var parent_generator = get_parent()
	if parent_generator.has_method("reset_block_after_harvest"):
		parent_generator.reset_block_after_harvest(current_grid_pos)
	queue_free()

func spawn_items():
	if not crop_item_scene: return
	for i in range(harvest_yield):
		var item = crop_item_scene.instantiate()
		get_tree().root.add_child(item)
		item.global_position = global_position
		var target_pos = item.global_position + Vector3(randf()-0.5, 0.0, randf()-0.5) * 1.5
		var tween = create_tween()
		tween.tween_property(item, "global_position", item.global_position + Vector3(0, 1.5, 0), 0.3).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "global_position", target_pos, 0.4).set_ease(Tween.EASE_IN)
