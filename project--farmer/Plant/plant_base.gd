extends Node3D

@export var growth_chance: float = 0.1
@export var crop_item_scene: PackedScene

# Texture cho từng giai đoạn
@export var texture_default: StandardMaterial3D
@export var texture_seeding: Texture2D

var growth: int = 0
var harvestable: bool = false

@export var harvest_yield: int = 2
@onready var graphic_seeding = $ModelCorn/Seeding/Tilled_Ground
@onready var graphic_sapling = $ModelCorn/Sapling
@onready var graphic_middle = $ModelCorn/Middle
@onready var graphic_ready = $ModelCorn/Ready
@onready var ground_mesh: MeshInstance3D = $ModelCorn/Seeding/Tilled_Ground/Plane


func _enter_tree():
	# ✅ chạy cực sớm để có texture xanh ngay khi spawn
	_apply_green_soil_initial()


func _ready():
	# Chờ 1 frame để đảm bảo mesh đã sẵn sàng rồi apply texture xanh
	call_deferred("_apply_green_soil_initial")
	
	GameData.get_current_stage().get_node("TimeManager").tick.connect(on_tick)
	update_plant_graphic()



func _apply_green_soil_initial():
	if ground_mesh and texture_seeding:
		var mat := ground_mesh.get_active_material(0)
		if mat:
			mat = mat.duplicate()
			mat.albedo_texture = texture_seeding
			ground_mesh.set_surface_override_material(0, mat)
			print("✅ Immediate green soil on spawn")


func grow_plant():
	growth += 1
	if growth >= 15:
		harvestable = true
		if get_parent().has_method("on_crop_ready"):
			get_parent().on_crop_ready(self)
	update_plant_graphic()


func update_plant_graphic():
	if growth <= 4:
		graphic_seeding.visible = true
		graphic_sapling.visible = false
		graphic_middle.visible = false
		graphic_ready.visible = false
		_apply_green_soil_initial()

	elif growth <= 8:
		graphic_seeding.visible = false
		graphic_sapling.visible = true
		graphic_middle.visible = false
		graphic_ready.visible = false
		_reset_soil_to_default()

	elif growth <= 14:
		graphic_seeding.visible = false
		graphic_sapling.visible = false
		graphic_middle.visible = true
		graphic_ready.visible = false
		_reset_soil_to_default()

	else:
		graphic_seeding.visible = false
		graphic_sapling.visible = false
		graphic_middle.visible = false
		graphic_ready.visible = true
		_reset_soil_to_default()


func _reset_soil_to_default():
	if ground_mesh and texture_default:
		var mat := ground_mesh.get_active_material(0)
		if mat:
			mat = mat.duplicate()
			mat.albedo_texture = texture_default
			ground_mesh.set_surface_override_material(0, mat)
			print("🌾 Soil reset to default")


func on_tick():
	if not harvestable and randf() < growth_chance:
		grow_plant()


func harvest():
	if not harvestable:
		return
	harvestable = false
	graphic_ready.visible = false

	if crop_item_scene:
		for i in range(harvest_yield):
			var item = crop_item_scene.instantiate()
			get_tree().get_root().ad
