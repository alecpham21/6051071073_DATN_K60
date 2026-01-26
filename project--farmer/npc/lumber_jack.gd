extends Node3D

@export var items_in_stock: Array[ItemData]
@export var items_to_order: Array[ItemData]
@export var dialog_timeline: String = "Lumberjack_Shop"

@export_group("Buy Settings (Instant)")
@export var max_buy_limit: int = 30
var current_buy_count: int = 0

@export_group("Pre-order Settings")
@export var days_to_wait: int = 3
@export var max_order_limit: int = 50

@export_group("Animations")
@export var anim_idle: String = "Idle"
@export var anim_interacted: String = "Interacted"
@export var anim_interacted_idle: String = "Idle_Interacted"

@onready var interact_area = $InteractArea
@onready var anim_player = $AnimationPlayer

var temp_item: ItemData
var temp_price: int
var ordered_item: ItemData
var ordered_quantity: int = 0
var delivery_day: int = -1
var is_shopping_instant: bool = false
var is_in_shop: bool = false

func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_dialogic_ended)
	
	if interact_area:
		interact_area.interacted.connect(start_dialogue)
	
	if anim_player:
		anim_player.play(anim_idle)

func _process(_delta):
	if is_in_shop:
		var ui = get_tree().get_first_node_in_group("inventory_interface")
		if ui and not ui.visible:
			is_in_shop = false
			if anim_player: anim_player.play(anim_idle)

func start_dialogue():
	var current_day = TimeManager.day
	Dialogic.VAR.WoodShop.order_ready = (ordered_quantity > 0 and current_day >= delivery_day)
	Dialogic.VAR.WoodShop.is_waiting = (ordered_quantity > 0 and current_day < delivery_day)
	Dialogic.VAR.WoodShop.pending_count = ordered_quantity
	Dialogic.VAR.WoodShop.max_limit = max_order_limit - ordered_quantity
	
	if anim_player:
		anim_player.play(anim_interacted)
		anim_player.queue(anim_interacted_idle)
		
	Dialogic.start(dialog_timeline)

func _on_dialogic_signal(argument: String):
	match argument:
		"open_shop_instant": 
			is_shopping_instant = true
			handle_shop_opening("instant")
		
		"open_shop_order": 
			is_shopping_instant = false
			if items_to_order.size() > 0:
				temp_item = items_to_order[0]
				temp_price = temp_item.sell_price
				Dialogic.VAR.WoodShop.max_limit = max_order_limit - ordered_quantity
				Dialogic.start("AskOrderQty")
				
		"collect_wood": 
			give_ordered_wood()
			
		"confirm_order": 
			finalize_order_from_dialogic()

func _on_dialogic_ended():
	await get_tree().process_frame
	if not is_in_shop and anim_player:
		anim_player.play(anim_idle)

func handle_shop_opening(mode: String):
	is_in_shop = true
	Dialogic.end_timeline()
	await get_tree().process_frame
	
	GState.shop()
	var ui = get_tree().get_first_node_in_group("inventory_interface")
	if ui and ui.has_method("open_shop_interface"):
		ui.open_shop_interface(items_in_stock if mode == "instant" else items_to_order, self)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_item_ordered(item: ItemData, quantity: int, price_per_unit: int):
	if is_shopping_instant:
		if current_buy_count + quantity > max_buy_limit:
			print("NPC stock limit reached")
			return
			
		var total_cost = quantity * price_per_unit
		if PlayerData.money >= total_cost:
			if PlayerData.player_inventory_data.add_item(item, quantity):
				PlayerData.money -= total_cost
				PlayerData.money_changed.emit(PlayerData.money)
				current_buy_count += quantity
				print("Instant purchase success")

func finalize_order_from_dialogic():
	var input_str = str(Dialogic.VAR.WoodShop.input_text).strip_edges()
	
	if not input_str.is_valid_int() or input_str.to_int() <= 0:
		print("Invalid input string")
		Dialogic.start("AskOrderQty")
		return

	var raw_quantity = input_str.to_int()
	var remaining_space = max_order_limit - ordered_quantity
	
	if remaining_space <= 0:
		print("Max order limit reached")
		return
		
	var final_qty = min(raw_quantity, remaining_space)
	var total_cost = final_qty * temp_price

	if PlayerData.money >= total_cost:
		PlayerData.money -= total_cost
		PlayerData.money_changed.emit(PlayerData.money)
		
		ordered_item = temp_item
		ordered_quantity += final_qty
		delivery_day = TimeManager.day + days_to_wait
		
		print("Order Success")
		Dialogic.start("Lumberjack_ConfirmSuccess") 
	else:
		print("Not enough money")
		Dialogic.start("Lumberjack_NoMoney")

func give_ordered_wood():
	if ordered_quantity > 0 and TimeManager.day >= delivery_day:
		if PlayerData.player_inventory_data.add_item(ordered_item, ordered_quantity):
			ordered_quantity = 0
			ordered_item = null
			delivery_day = -1
			print("Collection Success")
		else:
			print("Inventory full")

func get_save_data() -> Dictionary:
	return {
		"ordered_item_path": ordered_item.resource_path if ordered_item else "",
		"ordered_quantity": ordered_quantity,
		"delivery_day": delivery_day,
		"current_buy_count": current_buy_count
	}

func load_save_data(data: Dictionary):
	if data.get("ordered_item_path", "") != "":
		ordered_item = load(data.ordered_item_path)
	
	ordered_quantity = data.get("ordered_quantity", 0)
	delivery_day = data.get("delivery_day", -1)
	current_buy_count = data.get("current_buy_count", 0)
	#print("[DEBUG] Lumberjack: Data restored. Orders: ", ordered_quantity)
