extends Control

signal drop_slot_data(slot_data: SlotData)
signal click_slot_data(slot_data: SlotData, inventory: InventoryData, btn:int)
signal force_close

var grabbed_slot_data: SlotData
var external_inventory_owner
var washing_machine_ui: Control

# Biến mới để quản lý Bếp/Thớt
var active_kitchen: Kitchen
var active_mode: String = ""

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $ExternalInventory
@onready var equip_inventory: PanelContainer = $EquipInventory
@onready var outfit_inventory: PanelContainer = $OutfitInventory
@export var craft_bar: PanelContainer
@export var material_inventory: PanelContainer # Giữ nguyên 2 chữ 't' theo code cũ
@export var cutting_ui : PanelContainer # Thêm cái này cho Thớt
@onready var recipe_book_ui = $"../RecipeUI" # Thêm cái này cho Sách

func _ready():
	washing_machine_ui = get_node_or_null("WashingMachineUI")
	
	# 1. Kết nối sự kiện mở bếp (Logic Mới)
	GameData.open_kitchen_interface.connect(set_kitchen_inventory)

	# 2. Xử lý logic Click (Phục hồi logic cũ + Thêm logic bếp mới)
	click_slot_data.connect(on_slot_clicked_handler)
	
	# 3. Kết nối nút cắt của thớt
	if cutting_ui:
		cutting_ui.cut_requested.connect(_on_cut_action)
	
	GameData.game_state_changed.connect(func(old, new):
		match new:
			GState.state_enum.PLAYING:
				close_kitchen() # Đã có hàm này (để đóng)
			GState.state_enum.RECIPE:
				open_standalone_book() # <--- Cần thêm hàm này để mở
	)



func on_slot_clicked_handler(sd:SlotData, inv:InventoryData, btn:int):
	# Nếu không đang mở bếp thì thôi
	if active_kitchen == null: return
	
	# Xác định inventory đích (Bếp lò hay Thớt)
	var target_inv: InventoryData = null
	if active_mode == "stove":
		target_inv = active_kitchen.inventory_data
	elif active_mode == "board":
		target_inv = active_kitchen.board_input_inv
	
	if target_inv == null: return

	# LOGIC CLICK CHUỘT TRÁI (Bỏ đồ vào) - PHỤC HỒI TỪ CODE CŨ
	if inv == PlayerData.material_data && btn == MOUSE_BUTTON_LEFT:
		if sd == null: return
		
		# [LOGIC CŨ CỦA BẠN] Kiểm tra nếu Bếp đã đầy slot (trừ khi item đó đã có sẵn)
		if target_inv.is_full() && !target_inv.has_item(sd.item_data): return
		
		# [QUAN TRỌNG - CHỐNG SPAM]
		# Logic này lấy từ code cũ: So sánh số lượng trong Bếp với số lượng Người chơi có.
		# Nếu trong bếp đã có >= số lượng người chơi đang có -> KHÔNG CHO THÊM NỮA.
		if target_inv.has_item(sd.item_data):
			var slot_in_kitchen = target_inv.get_slot_from_item(sd.item_data)
			var slot_in_player = PlayerData.material_data.get_slot_from_item(sd.item_data)
			
			# Nếu slot người chơi bị null hoặc số trong bếp đã bằng hoặc hơn số người chơi có
			if slot_in_player == null or slot_in_kitchen.quantity >= slot_in_player.quantity:
				return 

		# Riêng cho Thớt: Chỉ nhận 1 món, nếu có rồi thì thôi
		if active_mode == "board" and target_inv.slot_datas[0] != null:
			return

		# Thực hiện thêm item (Copy 1 cái bỏ vào)
		var new_slot = sd.duplicate()
		new_slot.quantity = 1
		target_inv.pick_up_slot_data(new_slot)
		
		# Lưu ý: Code cũ của bạn KHÔNG trừ item trong túi ngay tại đây (chỉ copy vào bếp).
		# Nếu bạn muốn trừ ngay thì uncomment dòng dưới:
		# PlayerData.matterial_data.reduce_quantity(sd.item_data, 1)

	# LOGIC CLICK CHUỘT PHẢI (Lấy đồ ra)
	if inv == target_inv && btn == MOUSE_BUTTON_RIGHT:
		if sd: target_inv.remove_slot(sd)


# --- CÁC HÀM HỖ TRỢ BẾP (LOGIC MỚI) ---
func set_kitchen_inventory(kitchen_node: Kitchen, type: String = "stove") -> void:
	active_kitchen = kitchen_node
	active_mode = type
	
	# Ẩn các túi khác
	player_inventory.visible = false
	outfit_inventory.visible = false
	equip_inventory.visible = false
	
	# Hiện túi nguyên liệu
	material_inventory.set_inventory_data(PlayerData.material_data)
	material_inventory.show()
	
	self.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Reset UI
	craft_bar.hide()
	cutting_ui.hide()
	
	if type == "stove":
		# Mở Bếp Lò
		var inventory_data = kitchen_node.inventory_data
		# Kết nối click nếu chưa có
		if not inventory_data.inventory_interact.is_connected(on_inventory_click):
			inventory_data.inventory_interact.connect(on_inventory_click)
			
		craft_bar.set_inventory_data(inventory_data)
		craft_bar.show()
		recipe_book_ui.open_book()
		
	elif type == "board":
		# Mở Thớt
		recipe_book_ui.close_book()
		cutting_ui.setup_board(kitchen_node)
		cutting_ui.show()

func close_kitchen() -> void:
	if active_kitchen:
		if active_mode == "stove" and active_kitchen.inventory_data.inventory_interact.is_connected(on_inventory_click):
			active_kitchen.inventory_data.inventory_interact.disconnect(on_inventory_click)
	
	# 1. Ẩn hết các giao diện
	craft_bar.hide()
	cutting_ui.hide()
	material_inventory.hide()
	
	# Đóng sách và ẩn node sách
	if recipe_book_ui:
		if recipe_book_ui.has_method("close_book"):
			recipe_book_ui.close_book()
		recipe_book_ui.hide()

	# Hiện lại túi đồ chính (nếu cần thiết kế game của bạn muốn vậy, còn không thì hide luôn)
	player_inventory.show()
	
	# Reset biến
	active_kitchen = null
	active_mode = ""
	self.visible = false
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 3. [FIX LỖI] Ép Player cập nhật trạng thái chuột (đề phòng Player chưa nhận được tin)
	if PlayerData.player and PlayerData.player.has_method("_set_mouse_captured"):
		PlayerData.player._set_mouse_captured(true)



func open_standalone_book():
	outfit_inventory.visible = false
	player_inventory.visible = false
	equip_inventory.visible = false
	craft_bar.hide()
	cutting_ui.hide()
	material_inventory.hide()
	if external_inventory: external_inventory.hide()
	
	self.visible = true
	#  Mở sách
	if recipe_book_ui:
		recipe_book_ui.show()
		if recipe_book_ui.has_method("open_book"):
			recipe_book_ui.open_book() 
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_cut_action(recipe: Recipe):
	start_cooking_process(LimboPrimeHSM.COOK_MODE.BOARD, func(): finalize_cut(recipe))

func start_cooking_process(mode: int, on_complete_callback: Callable):
	var hsm = PlayerData.player.limbo_hsm as LimboPrimeHSM
	hsm.cook_mode = mode
	
	var _temp_func: Callable 
	_temp_func = func(cur, prev):
		var prev_name = ""
		if prev is CharacterState: prev_name = prev.state_name
		
		if prev_name.to_lower() == "cook": 
			on_complete_callback.call()
			if hsm.active_state_changed.is_connected(_temp_func):
				hsm.active_state_changed.disconnect(_temp_func)

	if not hsm.active_state_changed.is_connected(_temp_func):
		hsm.active_state_changed.connect(_temp_func)
	
	hsm.cook = true

func finalize_cut(recipe: Recipe):
	active_kitchen.board_input_inv.slot_datas[0] = null
	active_kitchen.board_input_inv.inventory_updated.emit(active_kitchen.board_input_inv)
	PlayerData.player_inventory_data.pick_up_slot_data(recipe.goal_item.duplicate())


# --- PHẦN CODE CŨ GIỮ NGUYÊN ---
func _physics_process(delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)
	if external_inventory_owner \
			and external_inventory_owner.global_position.distance_to(PlayerData.get_global_posotion()) > 2:
		force_close.emit()
	
func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func set_equip_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory.set_inventory_data(inventory_data)

func set_outfit_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	outfit_inventory.set_inventory_data(inventory_data)

func set_material_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_click)
	material_inventory.set_inventory_data(inventory_data)

func set_craft_bar_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_click)
	craft_bar.set_inventory_data(inventory_data)

func set_external_inventory(_external_inventory_owner) -> void:
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	
	if not force_close.is_connected(external_inventory_owner.close_chest):
		force_close.connect(external_inventory_owner.close_chest)
	
	if external_inventory_owner is WashingMachine:
		external_inventory.hide()
		if washing_machine_ui: 
			washing_machine_ui.show()
			if washing_machine_ui.has_method("setup_machine_ui"):
				washing_machine_ui.setup_machine_ui(external_inventory_owner)
	else:
		if washing_machine_ui:
			washing_machine_ui.hide()
		external_inventory.show()
		external_inventory.set_inventory_data(inventory_data)

func clear_external_inventory() -> void:
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
		if inventory_data.inventory_interact.is_connected(on_inventory_interact):
			inventory_data.inventory_interact.disconnect(on_inventory_interact)
		
		if force_close.is_connected(external_inventory_owner.close_chest):
			force_close.disconnect(external_inventory_owner.close_chest)
		
		external_inventory.clear_inventory_data(inventory_data)
		external_inventory.hide()
		if washing_machine_ui:
			washing_machine_ui.hide()
		external_inventory_owner = null
	
func on_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	update_grabbed_slot()

func on_inventory_click(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			click_slot_data.emit(inventory_data.slot_datas[index], inventory_data, MOUSE_BUTTON_LEFT)
		[null, MOUSE_BUTTON_RIGHT]:
			click_slot_data.emit(inventory_data.slot_datas[index], inventory_data, MOUSE_BUTTON_RIGHT)

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

func _on_gui_input(event: InputEvent) -> void:
	if not is_inside_tree(): 
		return
	if event is InputEventMouseButton and event.is_pressed() and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
		update_grabbed_slot()

func _on_visibility_changed() -> void:
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
