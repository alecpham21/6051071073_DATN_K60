extends ItemData
class_name Tool

func _init(_item_name:StringName, _node_path:NodePath) -> void:
	name = _item_name
	stackable = false
