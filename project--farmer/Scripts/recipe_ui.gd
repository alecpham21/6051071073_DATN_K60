extends Control

@onready var item_texture: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ItemTexture
@onready var item_name: Label = $MarginContainer/VBoxContainer/HBoxContainer/ItemName
@onready var item_description: RichTextLabel = $MarginContainer/VBoxContainer/ItemDescription

@onready var cook_btn: Button = $MarginContainer/VBoxContainer/NavButton/CookBtn
@onready var prev_btn: TextureButton = $MarginContainer/VBoxContainer/NavButton/BackButton
@onready var next_btn: TextureButton = $MarginContainer/VBoxContainer/NavButton/NextButton

@onready var blood_label: Label = $Label
@onready var interactive_book_2d: InteractiveBook2D = $BookControl/InteractiveBook2D

@export var recipes: Array[Recipe]

var current_page: int = 0:
	set(val):
		current_page = clampi(val, 0, page_count-1)
var page_count: int = 1
var cur_recipe: Recipe
var can_view: bool = false

var active_kitchen_inventory: InventoryData

func _ready() -> void:
	visible = false
	if blood_label: blood_label.visible = false
	page_count = recipes.size()
	if !recipes.is_empty(): cur_recipe = recipes[0]
	
	# [FIX 1] Nhận đúng 2 tham số từ Signal (để không bị lỗi kết nối)
	if not GameData.open_kitchen_interface.is_connected(on_open_kitchen):
		GameData.open_kitchen_interface.connect(on_open_kitchen)

	GameData.game_state_changed.connect(func(old, new):
		if new == GState.state_enum.COOK || new == GState.state_enum.RECIPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif old == GState.state_enum.COOK || old == GState.state_enum.RECIPE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			close_book()
	)
	
	next_btn.pressed.connect(page_turn.bind(true))
	prev_btn.pressed.connect(page_turn.bind(false))
	cook_btn.pressed.connect(cook)


func on_open_kitchen(kitchen_node, type = "stove"):
	# Chỉ quan tâm nếu là Bếp lò, Thớt thì không cần nhận data ở đây
	if type == "stove":
		set_kitchen_inventory(kitchen_node.inventory_data)
	else:
		active_kitchen_inventory = null # Reset nếu không phải bếp

func _process(delta: float) -> void:
	if visible && cur_recipe:
		# Update thông tin hiển thị (Nên tối ưu không chạy mỗi frame, nhưng tạm thời để đây)
		if cur_recipe.goal_item and cur_recipe.goal_item.item_data:
			var item: ItemData = cur_recipe.goal_item.item_data
			item_texture.texture = item.texture
			item_name.text = item.name
			item_description.text = item.description
		
		# [LOGIC HIỆN NÚT COOK]
		if active_kitchen_inventory:
			var enough_items = cur_recipe.can_cook(active_kitchen_inventory)
			cook_btn.visible = enough_items && can_view
			
			# Debug nếu bạn không thấy nút (Mở Output xem nó in gì)
			# print("Cook Check: Ingredients=", enough_items, " | View=", can_view)
		else:
			cook_btn.visible = false

func _input(event: InputEvent) -> void:
	if not visible or not can_view: return
	if event.is_action_pressed("use_item"):
		page_turn(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_use_item"):
		page_turn(false)
		get_viewport().set_input_as_handled()

func set_kitchen_inventory(inv: InventoryData) -> void:
	active_kitchen_inventory = inv

func open_book():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	
	# Ngắt kết nối cũ an toàn
	var old_connections = interactive_book_2d.animation_finished.get_connections()
	for conn in old_connections:
		interactive_book_2d.animation_finished.disconnect(conn.callable)
	
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
	
	var old_connections = interactive_book_2d.animation_finished.get_connections()
	for conn in old_connections:
		interactive_book_2d.animation_finished.disconnect(conn.callable)
	
	interactive_book_2d.play("next_to_last")
	interactive_book_2d.animation_finished.connect(func():
		interactive_book_2d.play("close_from_last")
		interactive_book_2d.animation_finished.connect(func(): visible = false, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

func page_turn(_next: bool = true):
	if _next && current_page >= page_count-1: return
	if !_next && current_page <= 0: return
	current_page += 1 if _next else -1
	interactive_book_2d.play("next_page" if _next else "previous_page")
	update_cur_recipe()
	toggle_page_ui(false)
	add_child(TimerKit.generate_timer(0.5, func(): toggle_page_ui(true)))

func cook():
	print("--- BẮT ĐẦU NẤU ---")
	
	# Check túi đầy
	var has_space = PlayerData.player_inventory_data.slot_datas.any(func(x): return x == null)
	var is_stackable_exist = PlayerData.player_inventory_data.has_item(cur_recipe.goal_item.item_data)
	
	if !has_space && !is_stackable_exist:
		print("LỖI: Túi đầy!")
		blood_flash()
		return
	
	# Check lại nguyên liệu lần cuối cho chắc
	if not cur_recipe.can_cook(active_kitchen_inventory):
		print("LỖI: Thiếu nguyên liệu hoặc ai đó vừa lấy mất!")
		return

	can_view = false
	
	# Logic chạy animation nấu
	var hsm = PlayerData.player.limbo_hsm as LimboPrimeHSM
	hsm.cook_mode = LimboPrimeHSM.COOK_MODE.STOVE # Set mode Bếp lò
	
	var _temp_func: Callable 
	_temp_func = func(cur, prev):
		var prev_name = ""
		if prev is CharacterState: prev_name = prev.state_name
		
		if prev_name.to_lower() == "cook":
			queue_cook(cur_recipe)
			can_view = true
			if hsm.active_state_changed.is_connected(_temp_func):
				hsm.active_state_changed.disconnect(_temp_func)

	if not hsm.active_state_changed.is_connected(_temp_func):
		hsm.active_state_changed.connect(_temp_func)
	
	hsm.cook = true

func queue_cook(_recipe: Recipe):
	for i: SlotData in _recipe.slot_datas:
		if active_kitchen_inventory and active_kitchen_inventory.has_item(i.item_data):
			active_kitchen_inventory.reduce_quantity(i.item_data, i.quantity)
			
	# Thêm thành phẩm vào túi người chơi
	PlayerData.player_inventory_data.pick_up_slot_data(_recipe.goal_item.duplicate())
	
	# Refresh UI
	if active_kitchen_inventory:
		active_kitchen_inventory.inventory_updated.emit(active_kitchen_inventory)

func blood_flash():
	if not blood_label: return
	var _tween: Tween = create_tween()

	_tween.tween_property(blood_label, "visible", true, 0.3)
	_tween.tween_property(blood_label, "visible", false, 0.3)
	_tween.finished.connect(func(): blood_label.visible = false)

func toggle_page_ui(_bool: bool = false):
	item_texture.visible = _bool
	item_name.visible = _bool
	item_description.visible = _bool
	prev_btn.visible = _bool
	next_btn.visible = _bool
	cook_btn.visible = _bool and cur_recipe.can_cook(active_kitchen_inventory) # Update lại ngay
	can_view = _bool
	if _bool: GameData.current_recipe_changed.emit(cur_recipe)

func update_cur_recipe():
	if recipes.size() > 0:
		cur_recipe = recipes[current_page]
