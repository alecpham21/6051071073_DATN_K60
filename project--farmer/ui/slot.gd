extends Control

@export var slot_int:int = 0

func _get_drag_data(at_position: Vector2) -> Variant:
	var preview:TextureRect = get_child(0).duplicate()
	set_drag_preview(preview)
	return slot_int

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is int

func _drop_data(at_position: Vector2, data: Variant) -> void:
	Inventory.slot_swap(slot_int, data)
