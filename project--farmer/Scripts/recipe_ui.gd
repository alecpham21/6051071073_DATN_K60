extends Control

@onready var item_texture: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ItemTexture
@onready var item_name: Label = $MarginContainer/VBoxContainer/HBoxContainer/ItemName
@onready var item_description: RichTextLabel = $MarginContainer/VBoxContainer/ItemDescription

@onready var cook_btn: Button = $CookBtn
@onready var prev_btn: Button = $MarginContainer/VBoxContainer/NavButton/PrevBtn
@onready var next_btn: Button = $MarginContainer/VBoxContainer/NavButton/NextBtn

@onready var blood_label: Label = $Label
@onready var interactive_book_2d: InteractiveBook2D = $BookControl/InteractiveBook2D

#signal page_turned

@export var recipes:Array[Recipe]
var current_page:int = 0:
	set(val):
		current_page = clampi(val, 0, page_count-1)
		#page_turned.emit()
var page_count:int = 1
var cur_recipe:Recipe
var can_view:bool =false
var book_offset:int = 2

var active_kitchen_inventory: InventoryData

func _ready() -> void:
	visible = false
	blood_label.visible = false
	page_count = recipes.size()
	if !recipes.is_empty(): cur_recipe = recipes[0]
	
	# --- ĐOẠN 1: KẾT NỐI VỚI BẾP ĐỂ LẤY DỮ LIỆU ---
	GameData.open_kitchen_interface.connect(func(kitchen_node):
		set_kitchen_inventory(kitchen_node.inventory_data)
	)
	# ----------------------------------------------

	GameData.game_state_changed.connect(func(old, new):
		if new == GState.state_enum.COOK || new == GState.state_enum.RECIPE:
			# --- ĐOẠN 2: HIỆN CHUỘT (KHÔNG XOAY CAMERA) ---
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
			open_book()
		elif old == GState.state_enum.COOK || old == GState.state_enum.RECIPE:
			# --- ĐOẠN 3: KHÓA CHUỘT (ĐỂ XOAY CAMERA) ---
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
			close_book()
		)
	next_btn.pressed.connect(page_turn.bind(true))
	prev_btn.pressed.connect(page_turn.bind(false))
	cook_btn.pressed.connect(cook)



func _process(delta: float) -> void:
	if visible && cur_recipe:
		var item:ItemData = cur_recipe.goal_item.item_data.duplicate()
		item_texture.texture = item.texture
		item_name.text = item.name
		item_description.text = item.description
		
		# Kiểm tra active_kitchen_inventory trước khi gọi can_cook để tránh lỗi null
		if active_kitchen_inventory:
			cook_btn.visible = cur_recipe.can_cook(active_kitchen_inventory) && can_view
		else:
			cook_btn.visible = false

# --- HÀM NÀY BỊ MẤT DO UNDO, CẦN THÊM LẠI ---
func set_kitchen_inventory(inv: InventoryData) -> void:
	active_kitchen_inventory = inv
# --------------------------------------------

func open_book():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	current_page = 0
	update_cur_recipe()
	toggle_page_ui(false)
	interactive_book_2d.play("open_to_first")
	interactive_book_2d.animation_finished.connect(func():
		interactive_book_2d.play("next_from_first")
		interactive_book_2d.animation_finished.connect(func(): toggle_page_ui(true), CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)

func close_book():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	toggle_page_ui(false)
	interactive_book_2d.play("next_to_last")
	interactive_book_2d.animation_finished.connect(func():
		interactive_book_2d.play("close_from_last")
		interactive_book_2d.animation_finished.connect(func():
			visible = false
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)

func page_turn(_next:bool = true):
	if _next && current_page >= page_count-1: return
	if !_next && current_page <= 0: return
	current_page += 1 if _next else -1
	interactive_book_2d.play("next_page" if _next else "previous_page")
	update_cur_recipe()
	toggle_page_ui(false)
	add_child(TimerKit.generate_timer(0.5, func(): toggle_page_ui(true)))

func cook():
	print("--- BẮT ĐẦU NẤU ---")
	
	# 1. Kiểm tra điều kiện (Túi đầy hoặc thiếu đồ)
	if PlayerData.player_inventory_data.slot_datas.filter(func(x): return x == null).is_empty()\
	&& !PlayerData.player_inventory_data.has_item(cur_recipe.goal_item.item_data):
		print("LỖI: Túi đầy hoặc thiếu item!")
		blood_flash()
		return
	
	print("Điều kiện OK. Chuẩn bị vào state Cook...")
	can_view = false
	
	var _temp_func: Callable 
	_temp_func = func(cur, prev):
		# In ra tên state để debug
		var prev_name = ""
		if prev is CharacterState: prev_name = prev.state_name
		print("State thay đổi! Từ: ", prev_name)
		
		# SỬA LẠI: So sánh không phân biệt hoa thường cho chắc
		if prev_name.to_lower() == "cook":
			print("Đã nấu xong! Đang trừ đồ...")
			queue_cook(cur_recipe)
			can_view = true
			
			if PlayerData.player.limbo_hsm.active_state_changed.is_connected(_temp_func):
				PlayerData.player.limbo_hsm.active_state_changed.disconnect(_temp_func)

	PlayerData.player.limbo_hsm.active_state_changed.connect(_temp_func)
	
	# --- ĐÂY LÀ CHỖ NGHI NGỜ BỊ LỖI ---
	# Dòng này set biến cook = true, nhưng State Machine có nhận không?
	(PlayerData.player.limbo_hsm as LimboPrimeHSM).cook = true
	print("Đã set cook = true. Chờ nhân vật múa...")

func queue_cook(_recipe:Recipe):
	for i:SlotData in _recipe.slot_datas:
		var quantity_needed = i.quantity
		var item = i.item_data
		
		# 1. Trừ trong túi người chơi trước
		if PlayerData.player_inventory_data.has_item(item):
			var slot_in_player = PlayerData.player_inventory_data.get_slot_from_item(item)
			var take_amount = mini(quantity_needed, slot_in_player.quantity)
			
			PlayerData.player_inventory_data.reduce_quantity(item, take_amount)
			quantity_needed -= take_amount 
			
		# 2. Nếu vẫn thiếu thì trừ tiếp trong bếp
		if quantity_needed > 0 and active_kitchen_inventory and active_kitchen_inventory.has_item(item):
			active_kitchen_inventory.reduce_quantity(item, quantity_needed)
			
	PlayerData.player_inventory_data.pick_up_slot_data(_recipe.goal_item.duplicate())
	
	if PlayerData.get("matterial_data"):
		PlayerData.matterial_data.refresh()
	elif PlayerData.get("material_data"):
		PlayerData.material_data.refresh()

func blood_flash():
	var _tween:Tween = create_tween()
	_tween.tween_property(blood_label, "visible", true, 0.3)
	_tween.tween_property(blood_label, "visible", false, 0.3)
	_tween.tween_property(blood_label, "visible", true, 0.3)
	_tween.tween_property(blood_label, "visible", false, 0.3)
	_tween.tween_property(blood_label, "visible", true, 0.3)
	_tween.finished.connect(func():
		add_child(TimerKit.generate_timer(1, func(): _tween.kill(); blood_label.visible = false))
		, CONNECT_ONE_SHOT)

func toggle_page_ui(_bool:bool = false):
	item_texture.visible = _bool
	item_name.visible = _bool
	item_description.visible = _bool
	prev_btn.visible = _bool
	next_btn.visible = _bool
	can_view = _bool
	if _bool: GameData.current_recipe_changed.emit(cur_recipe)

func update_cur_recipe():
	cur_recipe = recipes[current_page]
