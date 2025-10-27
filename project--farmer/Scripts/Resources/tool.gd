extends Item
class_name Tool

func _init(_item_name:StringName, _node_path:NodePath) -> void:
	item_name = _item_name
	stackable = false
	node_path = _node_path
