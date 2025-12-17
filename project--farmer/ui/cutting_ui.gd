extends PanelContainer

# Kéo node từ cây UI vào đây:
@export var input_slot_node: PanelContainer 
@export var output_preview_node: TextureRect 
@export var cut_btn: Button 

@export var recipes: Array[Recipe] 

var current_kitchen: Board
var active_recipe: Recipe = null

func _ready():
	visible = false
	cut_btn.pressed.connect(_on_cut_btn_pressed)
	cut_btn.disabled = true
	output_preview_node.visible = false
	
	GameData.game_state_changed.connect(func(old, new):
		if old == GState.state_enum.COOK and new != GState.state_enum.COOK:
			close_ui() 
	)

# Setup khi người chơi tương tác vào thớt
func setup_board(kitchen: Board):
	current_kitchen = kitchen
	visible = true
	
	# 1. Kết nối cập nhật kho
	if not current_kitchen.inventory_data.inventory_updated.is_connected(check_recipe):
		current_kitchen.inventory_data.inventory_updated.connect(check_recipe)
	
	# --- [BỔ SUNG QUAN TRỌNG] KẾT NỐI SỰ KIỆN CLICK ĐỂ LẤY ĐỒ RA ---
	# Phải ngắt kết nối cũ trước để tránh bị double click nếu mở lại nhiều lần
	if input_slot_node.has_signal("slot_clicked"):
		if input_slot_node.slot_clicked.is_connected(on_input_slot_clicked):
			input_slot_node.slot_clicked.disconnect(on_input_slot_clicked)
		
		# Kết nối hàm lấy đồ ra
		input_slot_node.slot_clicked.connect(on_input_slot_clicked)
	# -------------------------------------------------------------
	
	check_recipe(current_kitchen.inventory_data)

# --- [HÀM MỚI] XỬ LÝ LẤY ĐỒ RA KHỎI THỚT ---
func on_input_slot_clicked(_index: int, _btn: int):
	# Chỉ cho lấy đồ khi đang không cắt (nếu đang chạy animation thì thôi)
	if cut_btn.disabled == false and active_recipe == null: return # Logic phụ, không quan trọng lắm
	
	var inv = current_kitchen.inventory_data
	var slot = inv.slot_datas[0]
	
	if slot and slot.item_data:
		# 1. Trả đồ về túi Player
		PlayerData.player_inventory_data.add_item(slot.item_data, slot.quantity)
		
		# 2. Xóa đồ trên thớt
		inv.slot_datas[0] = null
		inv.inventory_updated.emit(inv)
		
		# 3. Refresh lại bảng Material để hiện lại món vừa lấy
		if PlayerData.material_data:
			PlayerData.material_data.refresh(PlayerData.player_inventory_data)

# -----------------------------------------------------------

func check_recipe(inv_data: InventoryData):
	# 1. Reset UI
	cut_btn.disabled = true
	output_preview_node.visible = false
	active_recipe = null
	
	var input_slot = inv_data.slot_datas[0]
	
	if input_slot_node.has_method("set_slot_data"):
		input_slot_node.set_slot_data(input_slot)
	
	if input_slot == null or input_slot.item_data == null:
		return

	for r in recipes:
		if r.station == Recipe.STATION.BOARD: 
			if r.slot_datas.size() > 0 and r.slot_datas[0].item_data == input_slot.item_data:
				active_recipe = r
				
				if r.cook_result and r.cook_result.item_data:
					output_preview_node.texture = r.cook_result.item_data.texture
					output_preview_node.visible = true
					cut_btn.disabled = false
				break

func _on_cut_btn_pressed():
	if active_recipe == null or current_kitchen == null: return
	
	var hsm = PlayerData.player.limbo_hsm as LimboPrimeHSM
	hsm.cook_mode = LimboPrimeHSM.COOK_MODE.BOARD
	
	var _temp_func: Callable 
	_temp_func = func(cur, prev):
		var prev_name = ""
		if prev is CharacterState: 
			prev_name = prev.state_name
		elif prev.has_method("get_name"): 
			prev_name = prev.name
		
		if prev_name.to_lower() == "cook":
			finish_cutting()
			if hsm.active_state_changed.is_connected(_temp_func):
				hsm.active_state_changed.disconnect(_temp_func)

	if not hsm.active_state_changed.is_connected(_temp_func):
		hsm.active_state_changed.connect(_temp_func)
	
	hsm.cook = true 

func finish_cutting():
	var item_to_give: SlotData = null
	if active_recipe and active_recipe.cook_result:
		item_to_give = active_recipe.cook_result.duplicate()
	
	current_kitchen.inventory_data.slot_datas[0] = null
	current_kitchen.inventory_data.inventory_updated.emit(current_kitchen.inventory_data)
	
	if item_to_give:
		PlayerData.player_inventory_data.pick_up_slot_data(item_to_give)
		if PlayerData.material_data:
			PlayerData.material_data.refresh(PlayerData.player_inventory_data)

	check_recipe(current_kitchen.inventory_data)

func close_ui():
	visible = false
	if current_kitchen and current_kitchen.inventory_data.inventory_updated.is_connected(check_recipe):
		current_kitchen.inventory_data.inventory_updated.disconnect(check_recipe)
