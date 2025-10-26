extends Node3D
class_name BlockGround

enum Mode { GRASS, CUT, TILLED }

@export var mode: Mode = Mode.GRASS : set = set_mode
@export var dug_offset := -0.03
@export var smooth_transition := true
@export var transition_speed := 5.0
@export var falloff_strength := 3.0 # càng cao => càng ít spawn ở rìa
# tỉ lệ xuất hiện và tối đa số lượng windgrass toàn map
@export var windgrass_chance := 0.1
@export var max_windgrass := 50

@onready var cube: MeshInstance3D = $Cube
@onready var dark_grass = $darkLeaf
@onready var light_grass = $lightLeaf
@onready var wind_grass_node: Node3D = $WindGrass
@onready var highlight_box: MeshInstance3D = $HighlightBox


@export_file("*.tres") var grass_mat_path: String = "res://materials/block_grass.tres"
@export_file("*.tres") var tilled_mat_path: String = "res://materials/block_tilled.tres"

@onready var player_inventory = get_tree().get_first_node_in_group("player_inventory")

var base_pos_y: float
var target_pos_y: float
var plant_type = PlantDatabase.PLANT_VARIANT.NONE
var _mat_grass: Material
var _mat_tilled: Material
var is_block := true
var has_dark_grass := false
var has_light_grass := false
var crop_ready := false
var crop_node: Node = null



static var current_windgrass := 0

func _ready() -> void:
	base_pos_y = position.y
	target_pos_y = base_pos_y
	
	has_dark_grass = randf() < 0.05
	has_light_grass = randf() < 0.05
	_mat_grass = load(grass_mat_path)
	_mat_tilled = load(tilled_mat_path)

	_apply_mode()
	_spawn_wind_grass_if_needed()


func _spawn_wind_grass_if_needed():
	if not wind_grass_node:
		return

	wind_grass_node.visible = false

	var center = Vector3(0, 0, 0)
	var max_dist = get_parent().ground_extents.length() / 2.0
	var dist = position.distance_to(center)

	# Càng gần giữa map thì weight càng cao
	var weight = pow(1.0 - clamp(dist / max_dist, 0.0, 1.0), falloff_strength)

	if mode == Mode.GRASS and randf() < windgrass_chance * weight and current_windgrass < max_windgrass:
		wind_grass_node.visible = true
		current_windgrass += 1

func set_highlighted(state: bool) -> void:
	highlight_box.visible = state

func set_mode(v: Mode) -> void:
	mode = v
	_apply_mode()



func on_crop_ready(plant):
	crop_ready = true
	crop_node = plant


func _apply_mode() -> void:
	if cube and cube.mesh:
		var mat = _mat_tilled if mode == Mode.TILLED else _mat_grass
		for i in range(cube.mesh.get_surface_count()):
			cube.set_surface_override_material(i, mat)

	if dark_grass:
		dark_grass.visible = (mode == Mode.GRASS and has_dark_grass)
	if light_grass:
		light_grass.visible = (mode == Mode.GRASS and has_light_grass)

	var new_y = base_pos_y + (dug_offset if mode == Mode.TILLED else 0.0)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "position:y", new_y, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func cut_grass() -> void:
	if mode == Mode.GRASS:
		mode = Mode.CUT
		_apply_mode()

func till_block() -> void:
	if mode != Mode.CUT:
		mode = Mode.TILLED
		_apply_mode()

func add_plant(type):
	plant_type = type
	var plant = PlantDatabase.get_plant_node(type)
	if plant == null:
		push_error("❌ Could not get plant for variant: %s" % [type])
		return
	add_child(plant)
	plant.position = Vector3(0, 0.5, 0)

	var time_manager = get_tree().get_first_node_in_group("time_manager")
	if time_manager:
		time_manager.tick.connect(plant.on_tick)

func harvest_plant():
	if crop_ready and crop_node:
		crop_node.harvest()
		crop_ready = false
		crop_node = null
	else:
		print("No harvestable crop here.")
	


func interact() -> void:
	if mode == Mode.GRASS:
		mode = Mode.CUT
		_apply_mode()
		print("Grass cut -> CUT")
	elif mode == Mode.CUT:
		mode = Mode.TILLED
		_apply_mode()
		print("CUT -> TILLED")
	elif mode == Mode.TILLED:
		var active_item = player_inventory.get_active_item()
		print("Active item: ", active_item)
		if active_item.ends_with("_seed"):
			var variant = PlantDatabase.get_variant_from_seed(active_item)
			if variant != PlantDatabase.PLANT_VARIANT.NONE:
				add_plant(variant)
				print("Planted seed: ", active_item)
		else:
			print("No seed selected")




static func get_block_from_hit(hit: Object) -> BlockGround:
	if hit is BlockGround:
		return hit
	if hit is Node:
		var n := hit as Node
		while n:
			if n is BlockGround:
				return n
			n = n.get_parent()
	return null
