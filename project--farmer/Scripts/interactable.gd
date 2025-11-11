extends Area3D
class_name InteractArea

signal interacted
var par:Node
func _ready() -> void:
	par = get_parent()
