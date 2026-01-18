extends Node

signal object_harvested(obj_name: String, amount: int)
signal item_added_to_inventory(item_name, quantity)
signal inventory_opened(external_inventory_owner)
signal item_dropped(item_data: ItemData, amount: int, position: Vector3)
