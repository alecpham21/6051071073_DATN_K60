extends Node

signal object_harvested(obj_name: String, amount: int)
signal item_added_to_inventory(item_name, quantity)

signal item_dropped(item_data: ItemData, amount: int, position: Vector3)
