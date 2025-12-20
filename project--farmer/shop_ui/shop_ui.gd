extends PanelContainer

const SHOP_SLOT_SCENE = preload("res://shop_script/shop_slot.tscn")

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var close_btn: Button = $MarginContainer/VBoxContainer/Button

func _ready():
	if close_btn:
		close_btn.pressed.connect(close_shop)

func setup_shop_data(incoming_items: Array[ItemData]):
	for child in grid_container.get_children():
		child.queue_free()
	
	for item in incoming_items:
		if item == null: continue
		
		var slot = SHOP_SLOT_SCENE.instantiate()
		grid_container.add_child(slot)
		
		var price = 100
		if "price" in item:
			price = item.price
			
		if slot.has_method("set_shop_item"):
			slot.set_shop_item(item, price)
		
		if not slot.buy_clicked.is_connected(on_buy_item):
			slot.buy_clicked.connect(on_buy_item)

func on_buy_item(item: ItemData, price: int):
	if PlayerData.money >= price:
		if PlayerData.player_inventory_data.add_item(item, 1):
			PlayerData.money -= price
			print("✅ Đã mua: " + item.name)
		else:
			print("⚠️ Túi đồ đầy!")
	else:
		print("❌ Không đủ tiền!")

func close_shop():
	var parent_interface = get_parent()
	if parent_interface and parent_interface.has_method("close_shop_interface"):
		parent_interface.close_shop_interface()
	else:
		self.hide()
