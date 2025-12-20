extends Control

@onready var item_texture: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ItemTexture
@onready var item_name: Label = $MarginContainer/VBoxContainer/HBoxContainer/ItemName
@onready var item_description: RichTextLabel = $MarginContainer/VBoxContainer/ItemDescription

@onready var prev_btn: TextureButton = $MarginContainer/VBoxContainer/NavButton/BackButton
@onready var next_btn: TextureButton = $MarginContainer/VBoxContainer/NavButton/NextButton

@onready var interactive_book_2d: InteractiveBook2D = $BookControl/InteractiveBook2D

@export var recipes: Array[Recipe]
@export var unknown_texture: Texture2D 

# Không cần biến craft_bar nữa vì sách không check nồi nữa
# @export var craft_bar: Control 

var current_page: int = 0:
	set(val):
		current_page = clampi(val, 0, page_count-1)
var page_count: int = 1
var cur_recipe: Recipe
var can_view: bool = false

func _ready() -> void:
	visible = false
	page_count = recipes.size()
	if !recipes.is_empty(): cur_recipe = recipes[0]
	
	GameData.game_state_changed.connect(func(old, new):
		if new == GState.state_enum.COOK || new == GState.state_enum.RECIPE:
			open_book()
		elif old == GState.state_enum.COOK || old == GState.state_enum.RECIPE:
			# FIX: Kiểm tra nếu chuyển sang UI (Inventory) thì đóng ngay (true)
			var instant_close = (new == GState.state_enum.UI)
			close_book(instant_close)
	)
	
	next_btn.pressed.connect(page_turn.bind(true))
	prev_btn.pressed.connect(page_turn.bind(false))

func _process(delta: float) -> void:
	if visible:
		if Input.is_action_just_pressed("use_item"):
			page_turn(true)
		elif Input.is_action_just_pressed("quick_use_item"): # Đã sửa thành quick_use_item
			page_turn(false)
		
		# Chỉ hiển thị thông tin, không check điều kiện nấu nữa
		if cur_recipe:
			if cur_recipe.cook_result and cur_recipe.cook_result.item_data:
				var item: ItemData = cur_recipe.cook_result.item_data 
				item_texture.texture = item.texture
				item_name.text = item.name
				item_description.text = item.description
			else:
				item_name.text = "..."
				item_description.text = "..."
				item_texture.texture = null

func open_book():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	current_page = 0
	update_cur_recipe()
	toggle_page_ui(false)
	
	var conns = interactive_book_2d.animation_finished.get_connections()
	for c in conns: interactive_book_2d.animation_finished.disconnect(c.callable)

	interactive_book_2d.play("open_to_first")
	interactive_book_2d.animation_finished.connect(func():
		interactive_book_2d.play("next_from_first")
		interactive_book_2d.animation_finished.connect(func(): toggle_page_ui(true), CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

func close_book(instant: bool = false):
	toggle_page_ui(false)
	clear_animation_signals()

	if instant:
		visible = false
		interactive_book_2d.play("close_from_last") 
		interactive_book_2d.stop()
		return

	interactive_book_2d.play("next_to_last")
	interactive_book_2d.animation_finished.connect(func():
		interactive_book_2d.play("close_from_last")
		interactive_book_2d.animation_finished.connect(func(): 
			visible = false
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

func page_turn(_next: bool = true):
	if _next && current_page >= page_count-1: return
	if !_next && current_page <= 0: return
	current_page += 1 if _next else -1
	interactive_book_2d.play("next_page" if _next else "previous_page")
	update_cur_recipe()
	toggle_page_ui(false)
	add_child(TimerKit.generate_timer(0.5, func(): toggle_page_ui(true)))

func clear_animation_signals():
	var conns = interactive_book_2d.animation_finished.get_connections()
	for c in conns: 
		interactive_book_2d.animation_finished.disconnect(c.callable)


func toggle_page_ui(_bool: bool = false):
	item_texture.visible = _bool
	item_name.visible = _bool
	item_description.visible = _bool
	prev_btn.visible = _bool
	next_btn.visible = _bool
	can_view = _bool
	if _bool: GameData.current_recipe_changed.emit(cur_recipe)

func update_cur_recipe():
	if recipes.size() > 0:
		cur_recipe = recipes[current_page]
