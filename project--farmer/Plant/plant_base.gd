extends Node3D

@export var growth_chance: float = 0.1
@export var crop_item_scene: PackedScene

var growth: int
var harvestable: bool = false

@export var harvest_yield: int = 2
@onready var graphic_sapling = $ModelCorn/Sapling
@onready var graphic_middle = $ModelCorn/Middle
@onready var graphic_ready = $ModelCorn/Ready


func _ready():
	GameData.get_current_stage().get_node("TimeManager").tick.connect(on_tick)


func grow_plant():
	growth += 1
	if growth >= 10:
		harvestable = true
		# báo cho block_ground biết cây này harvest được
		if get_parent().has_method("on_crop_ready"):
			get_parent().on_crop_ready(self)
	update_plant_graphic()
	
func update_plant_graphic():
	if growth <= 3:
		graphic_sapling.visible = true
		print("growth 1")
	elif growth <= 9:
		graphic_sapling.visible = false
		graphic_middle.visible = true
		print("growth 2")
	else:
		graphic_sapling.visible = false
		graphic_middle.visible = false
		graphic_ready.visible = true
		print("growth 3")


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
			print("spawn:", crop_item_scene, " -> ", item)
			get_tree().get_root().add_child(item)
			item.global_position = global_position

			var start_pos = item.global_position
			var peak_pos = start_pos + Vector3(randf() - 0.5, 2.0, randf() - 0.5)
			var end_pos = start_pos + Vector3(randf() - 0.5, 0.2, randf() - 0.5)

			var tween = get_tree().create_tween()
			tween.tween_property(item, "global_position", peak_pos, 0.3).set_ease(Tween.EASE_OUT)
			tween.tween_property(item, "global_position", end_pos, 0.6).set_ease(Tween.EASE_IN)
			print(">>> spawned:", item.name, "at", item.global_position)

	queue_free()
