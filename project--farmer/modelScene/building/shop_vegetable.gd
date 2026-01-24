extends Node3D

@export var items_to_sell: Array[ItemData] 
@export var dialog_timeline: String = "SellingVegetable"
@export var accepted_selling_type: ItemDataMaterial.SellingType = ItemDataMaterial.SellingType.VEGETABLE

@onready var interact_area = $InteractArea

var sell_box_inventory: ShopInventoryData
var inventory_data: InventoryData:
	get:
		return sell_box_inventory


func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	if interact_area:
		interact_area.interacted.connect(start_dialogue)
	
	sell_box_inventory = ShopInventoryData.new()
	sell_box_inventory.slot_datas.resize(5)
	sell_box_inventory.accepted_type = accepted_selling_type

func start_dialogue():
	Dialogic.start(dialog_timeline)

func _on_dialogic_signal(argument: String):
	match argument:
		"open_buy_shop_veg":
			handle_shop_opening("buy")
			
		"sell_wholesale_veg":
			handle_shop_opening("sell")


func handle_shop_opening(mode: String):
	Dialogic.end_timeline()
	await get_tree().process_frame
	
	GState.shop()
	var ui = get_tree().get_first_node_in_group("inventory_interface")
	
	if ui:
		if mode == "buy":
			if ui.has_method("open_shop_interface"):
				ui.open_shop_interface(items_to_sell)
		else:
			if ui.has_method("open_shop_sell_interface"):
				ui.open_shop_sell_interface(self, sell_box_inventory)
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_sell_button_pressed():
	var total_money = 0
	var datas = sell_box_inventory.slot_datas
	
	for i in range(datas.size()):
		var slot = datas[i]
		
		if slot and slot.item_data:
			var price = 0
			if slot.item_data is ItemDataMaterial:
				price = slot.item_data.sell_price
			else:
				price = int(slot.item_data.price * 0.5)
			
			total_money += price * slot.quantity
			
			sell_box_inventory.slot_datas[i] = null 
	
	if total_money > 0:
		finalize_transaction(total_money, sell_box_inventory)
		print("Success, income: ", total_money)
	else:
		print("Empty!")

func on_sell_wholesale_pressed():
	var player = get_tree().get_first_node_in_group("Player")
	if not player: 
		print("Bug: No Player")
		return
	
	var player_inv = player.inventory_data
	var total_earned = 0
	var items_sold_count = 0
	
	for i in range(player_inv.slot_datas.size()):
		var slot = player_inv.slot_datas[i]
		
		if slot and slot.item_data:
			
			if slot.item_data is ItemDataMaterial:
				
				print("Check Slot ", i, ": ", slot.item_data.name, " | SL: ", slot.quantity, " | Type: ", slot.item_data.selling_type)
				
				var is_right_type = (slot.item_data.selling_type == accepted_selling_type)
				var is_wholesale_qty = (slot.quantity >= 20) 
				
				if is_right_type and is_wholesale_qty:
					var profit = slot.item_data.sell_price * slot.quantity
					
					total_earned += profit
					items_sold_count += slot.quantity
					
					player_inv.slot_datas[i] = null 
					print(" -> Sold!")
				else:
					print(" -> Sell less than 20")
					
			else:
				print("Check Slot ", i, ": ", slot.item_data.name, " -> Ignore (Not Material)")
	
	if items_sold_count > 0:
		finalize_transaction(total_earned, player_inv)
		print(">>>  Sell Success: ", items_sold_count, " món. Tiền: ", total_earned)
	else:
		print(">>> Cant sell")

func finalize_transaction(amount: int, inventory_to_update: InventoryData):
	if PlayerData:
		PlayerData.money += amount
		if PlayerData.has_signal("money_changed"):
			PlayerData.money_changed.emit(PlayerData.money)
	
	inventory_to_update.inventory_updated.emit(inventory_to_update)

func close_chest():
	var ui = get_tree().get_first_node_in_group("inventory_interface")
	if ui:
		ui.close_shop_interface()
