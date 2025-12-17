extends Control

signal drop_slot_data(slot_data: SlotData)
signal click_slot_data(slot_data: SlotData, inventory: InventoryData, btn:int)
signal force_close

var grabbed_slot_data: SlotData
var external_inventory_owner
var washing_machine_ui: Control

# Node3D để nhận cả Stove và Board
var active_kitchen: Node3D 
var active_mode: String = ""

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $ExternalInventory
@onready var equip_inventory: PanelContainer = $EquipInventory
@onready var outfit_inventory: PanelContainer = $OutfitInventory

# Kéo node vào Inspector
@export var hotbar_inventory: PanelContainer 
@export var material_inventory: PanelContainer

@export var craft_bar: PanelContainer      # UI Stove
@export var cutting_ui : PanelContainer    # UI Board
@onready var recipe_book_ui = $"../RecipeUI"

func _ready():
	washing_machine_ui = get_node_or_null("WashingMachineUI")
	
	if not GameData.open_kitchen_interface.is_connected(set_kitchen_inventory):
		GameData.open_kitchen_interface.connect(set_kitchen_inventory)
	
	if not click_slot_data.is_connected(on_slot_clicked_handler):
		click_slot_data.connect(on_slot_clicked_handler)
	
	GameData.game_state_changed.connect(func(old, new):
		match new:
			GState.state_enum.PLAYING:
				close_kitchen()
			GState.state_enum.RECIPE:
				open_standalone_book()
	)

# ------------------------------------------------------------------
# LOGIC CLICK SLOT
# ------------------------------------------------------------------
func on_slot_clicked_handler(sd: SlotData, inv: InventoryData, btn: int):
	if btn == MOUSE_BUTTON_LEFT:
		if sd == null or sd.item_data == null or sd.quantity <= 0: return

		# --- LOGIC STOVE (BẾP) ---
		if active_mode == "stove":
			if craft_bar and craft_bar.has_method("add_ingredient"):
				if craft_bar.add_ingredient(sd.item_data):
					PlayerData.player_inventory_data.reduce_quantity(sd.item_data, 1)
					refresh_material_data()
			return

		# --- LOGIC BOARD (THỚT) ---
		elif active_mode == "board" and active_kitchen:
			var board_inv = active_kitchen.inventory_data
			
			# Nếu thớt trống
			if board_inv.slot_datas[0] == null:
				
				# [CÁCH MỚI - GIỐNG STOVE]
				# Tạo slot mới tinh, không copy thuộc tính để tránh crash
				var item_to_place = SlotData.new()
				item_to_place.item_data = sd.item_data
				item_to_place.quantity = 1
				
				board_inv.slot_datas[0] = item_to_place
				board_inv.inventory_updated.emit(board_inv)
				
				# Trừ đồ trong túi
				PlayerData.player_inventory_data.reduce_quantity(sd.item_data, 1)
				
				refresh_material_data()
					
			return

func set_kitchen_inventory(kitchen_node: Node3D, type: String = "stove") -> void:
	GState.ui()
	active_kitchen = kitchen_node
	active_mode = type
	
	self.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Ẩn UI mặc định và HOTBAR
	player_inventory.visible = false
	outfit_inventory.visible = false
	equip_inventory.visible = false
	if hotbar_inventory: hotbar_inventory.hide()
	
	if craft_bar: craft_bar.hide()
	if cutting_ui: cutting_ui.hide()
	
	refresh_material_data()

	match type:
		"stove":
			setup_stove_mode(kitchen_node)
		"board":
			setup_board_mode(kitchen_node)

func setup_stove_mode(node):
	if material_inventory:
		if material_inventory.has_method("reset_to_default_mode"):
			material_inventory.reset_to_default_mode()
		material_inventory.set_inventory_data(PlayerData.material_data)
		material_inventory.show()

	var inventory_data = node.inventory_data
	if not inventory_data.inventory_interact.is_connected(on_inventory_click):
		inventory_data.inventory_interact.connect(on_inventory_click)
	
	if craft_bar:
		if craft_bar.has_method("on_open_kitchen"):
			craft_bar.on_open_kitchen(node, "stove")
		craft_bar.show()
	if recipe_book_ui: recipe_book_ui.open_book()

func setup_board_mode(node):
	if recipe_book_ui: recipe_book_ui.close_book()
	
	# Lọc chỉ hiện Nguyên liệu cho Thớt
	if material_inventory:
		var filter_raw = func(item_data):
			if item_data is ItemDataMaterial:
				return item_data.material_type == ItemDataMaterial.MaterialType.RAW_MATERIAL
			return false
		
		if material_inventory.has_method("setup_custom_mode"):
			material_inventory.setup_custom_mode(filter_raw, Callable())
			
		material_inventory.set_inventory_data(PlayerData.material_data)
		material_inventory.show()
	
	if cutting_ui:
		cutting_ui.setup_board(node)
		cutting_ui.show()

func refresh_material_data():
	PlayerData.material_data.refresh(PlayerData.player_inventory_data)

# ------------------------------------------------------------------
# ĐÓNG UI
# ------------------------------------------------------------------
func close_kitchen() -> void:
	if active_kitchen and active_mode == "stove":
		if active_kitchen.get("inventory_data") and active_kitchen.inventory_data.inventory_interact.is_connected(on_inventory_click):
			active_kitchen.inventory_data.inventory_interact.disconnect(on_inventory_click)
	
	if craft_bar: craft_bar.hide()
	if cutting_ui: cutting_ui.close_ui()
	if material_inventory: material_inventory.hide()
	if recipe_book_ui: recipe_book_ui.hide()
	
	if player_inventory: player_inventory.show()
	if hotbar_inventory: hotbar_inventory.show()
	
	if PlayerData.player and PlayerData.player.cam_ref:
		if PlayerData.player.cam_ref.has_method("return_to_player"):
			PlayerData.player.cam_ref.return_to_player()
	
	active_kitchen = null
	active_mode = ""
	self.visible = false
	
	if not GState.is_dialog():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if PlayerData.player and PlayerData.player.has_method("_set_mouse_captured"):
			PlayerData.player._set_mouse_captured(true)

	if not GState.is_playing():
		GState.play()

func open_standalone_book():
	outfit_inventory.visible = false
	player_inventory.visible = false
	equip_inventory.visible = false
	if craft_bar: craft_bar.hide()
	if cutting_ui: cutting_ui.hide()
	if material_inventory: material_inventory.hide()
	if external_inventory: external_inventory.hide()
	self.visible = true
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

# [SỬA QUAN TRỌNG] Đổi tên biến board_input_inv -> inventory_data
func finalize_cut(recipe: Recipe):
	active_kitchen.inventory_data.slot_datas[0] = null
	active_kitchen.inventory_data.inventory_updated.emit(active_kitchen.inventory_data)
	PlayerData.player_inventory_data.pick_up_slot_data(recipe.goal_item.duplicate())

# ... (Phần code cũ bên dưới giữ nguyên) ...
func _physics_process(delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)
	if external_inventory_owner and external_inventory_owner.global_position.distance_to(PlayerData.get_global_posotion()) > 2:
		force_close.emit()
	
func set_player_inventory_data(inventory_data: InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func set_equip_inventory_data(inventory_data: InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory.set_inventory_data(inventory_data)

func set_outfit_inventory_data(inventory_data: InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_interact):
		inventory_data.inventory_interact.connect(on_inventory_interact)
	outfit_inventory.set_inventory_data(inventory_data)

func set_material_inventory_data(inventory_data: InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_click):
		inventory_data.inventory_interact.connect(on_inventory_click)
	material_inventory.set_inventory_data(inventory_data)

func set_craft_bar_data(inventory_data: InventoryData) -> void:
	if not inventory_data.inventory_interact.is_connected(on_inventory_click):
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
		if washing_machine_ui: washing_machine_ui.hide()
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
		if washing_machine_ui: washing_machine_ui.hide()
		external_inventory_owner = null
	
func on_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]: grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]: grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]: inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]: grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	update_grabbed_slot()

func on_inventory_click(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]: click_slot_data.emit(inventory_data.slot_datas[index], inventory_data, MOUSE_BUTTON_LEFT)
		[null, MOUSE_BUTTON_RIGHT]: click_slot_data.emit(inventory_data.slot_datas[index], inventory_data, MOUSE_BUTTON_RIGHT)

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

func _on_gui_input(event: InputEvent) -> void:
	if not is_inside_tree(): return
	if event is InputEventMouseButton and event.is_pressed() and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1: grabbed_slot_data = null
		update_grabbed_slot()

func _on_visibility_changed() -> void:
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
