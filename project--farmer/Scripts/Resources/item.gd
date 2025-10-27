extends Resource
class_name Item

var item_name:StringName
var max_stack:int = 1:
	set(val):
		if !stackable: max_stack = 1
		max_stack = val
var stackable:bool = false
var quantity:int = 1:
	set(val):
		quantity = clampi(val, 0, max_stack)
var node_path:NodePath

func _init(_item_name:StringName, _stackable:bool = false, _node_path:NodePath = "", _max_stack:int = 1, _quantity:int = 1) -> void:
	item_name = _item_name
	stackable = _stackable
	if stackable:
		max_stack = _max_stack
		quantity = _quantity
	node_path = _node_path
