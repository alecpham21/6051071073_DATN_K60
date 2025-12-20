extends Node3D

@export var items_to_sell: Array[ItemData] 

@onready var interact_area = $InteractArea

func _ready():
	if interact_area:
		interact_area.interacted.connect(open_shop)

func open_shop():
	print("DEBUG: item list: ", items_to_sell.size())
	
	var ui = get_tree().get_first_node_in_group("inventory_interface")
	if ui and ui.has_method("open_shop_interface"):
		ui.open_shop_interface(items_to_sell)
	else:
		print("❌ UI!")
