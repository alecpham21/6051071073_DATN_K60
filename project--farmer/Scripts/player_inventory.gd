extends Node
#
#signal active_item_changed(item_name: String)
#
#var inventory = [
	#{"item_name": "hoe"},
	#{"item_name": "corn_seed"},
	#{"item_name": "wheat_seed"},
	#{"item_name": "sickle"},
	#{"item_name": "null"},
	#{"item_name": "null"},
	#{"item_name": "null"},
	#
#]
#
#var active_item_slot :int = 0
#
#
#func _input(event):
	#if event.is_action_pressed("item_slot_0"):
		#set_active_slot(0)
	#if event.is_action_pressed("item_slot_1"):
		#set_active_slot(1)
	#if event.is_action_pressed("item_slot_2"):
		#set_active_slot(2)
	#if event.is_action_pressed("item_slot_3"):
		#set_active_slot(3)
	#if event.is_action_pressed("item_slot_4"):
		#set_active_slot(4)
	#if event.is_action_pressed("item_slot_5"):
		#set_active_slot(5)
	#if event.is_action_pressed("item_slot_6"):
		#set_active_slot(6)
#
#func set_active_slot(slot: int) -> void:
	#if slot >= 0 and slot < inventory.size():
		#active_item_slot = slot
		#var item_name = inventory[slot].item_name
		#emit_signal("active_item_changed", item_name)
#
#func get_active_item() -> String:
	#return inventory[active_item_slot]["item_name"]
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
#
#
#
#func is_holding(item_name: String) -> bool:
	#return get_active_item() == item_name
	#
#
#func get_all_item_names() -> Array:
	#var names: Array = []
	#for slot in inventory:
		#names.append(slot["item_name"])
	#return names
