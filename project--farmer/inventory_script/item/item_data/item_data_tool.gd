extends ItemData
class_name ItemDataTool

@export var equip_scene: PackedScene
@export var harvest_speed: int
@export var is_long_tool:bool = false

func use(cargo:Array = []) -> void:
	pass

func _init() -> void:
	stackable = false
