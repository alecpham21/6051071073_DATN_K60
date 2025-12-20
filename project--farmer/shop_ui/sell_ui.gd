extends Control

@onready var inventory_view = $VBoxContainer/Inventory
@onready var sell_button = $VBoxContainer/HBoxContainer/SellButton
@onready var sell_all_button = $VBoxContainer/HBoxContainer/SellAllButton

func setup(shop_node: Node, shop_inventory_data: InventoryData):
	self.show()
	
	if inventory_view:
		inventory_view.set_inventory_data(shop_inventory_data)
	
	if sell_button.pressed.is_connected(shop_node.on_sell_button_pressed):
		sell_button.pressed.disconnect(shop_node.on_sell_button_pressed)
	sell_button.pressed.connect(shop_node.on_sell_button_pressed)

	if sell_all_button.pressed.is_connected(shop_node.on_sell_wholesale_pressed):
		sell_all_button.pressed.disconnect(shop_node.on_sell_wholesale_pressed)
	sell_all_button.pressed.connect(shop_node.on_sell_wholesale_pressed)

func close_shop():
	var parent_interface = get_parent()
	if parent_interface and parent_interface.has_method("close_shop_interface"):
		parent_interface.close_shop_interface()
	else:
		self.hide()
