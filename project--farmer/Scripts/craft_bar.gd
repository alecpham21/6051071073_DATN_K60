extends PanelContainer

const Slot = preload("res://Inventory_ui/slot.tscn")

@onready var item_grid: GridContainer = $VBoxContainer/MarginContainer/ItemGrid
@onready var recipe_texture: TextureRect = $VBoxContainer/Slot/RecipeTexture
@onready var cook_button: Button = $VBoxContainer/Slot/RecipeTexture/CookButton
@export var progress_bar: ProgressBar
@export var all_recipes: Array[Recipe]


var craft_slots_data: Array[SlotData]
var valid_recipe_to_cook: Recipe = null
var is_crafting: bool = false

func _ready() -> void:
	craft_slots_data = PlayerData.craft_bin_data
	visible = false 
	
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0
	
	if cook_button:
		cook_button.pressed.connect(_on_cook_button_pressed)
		cook_button.visible = false
	
	if not GameData.open_kitchen_interface.is_connected(on_open_kitchen):
		GameData.open_kitchen_interface.connect(on_open_kitchen)
	
	GameData.game_state_changed.connect(func(old, new):
		if old == GState.state_enum.COOK and new != GState.state_enum.COOK:
			visible = false
			is_crafting = false
			if progress_bar: progress_bar.visible = false
	)

func on_open_kitchen(kitchen_node, type = "stove"):
	if type == "stove": 
		visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		update_craft_bar_ui()
		check_recipe()
	else:
		visible = false


func add_ingredient(item_data: ItemData) -> bool:
	for slot in craft_slots_data:
		if slot and slot.item_data == item_data and slot.quantity < 99:
			slot.quantity += 1
			
			update_craft_bar_ui()
			check_recipe()
			return true

	for i in range(craft_slots_data.size()):
		if craft_slots_data[i] == null:
			# Tạo slot mới
			var new_slot = SlotData.new()
			new_slot.item_data = item_data
			new_slot.quantity = 1
			
			craft_slots_data[i] = new_slot
			
			update_craft_bar_ui()
			check_recipe()
			return true # Báo thành công
			
	return false

func remove_ingredient(index: int, btn: int):
	if btn != MOUSE_BUTTON_RIGHT: 
		return

	var slot = craft_slots_data[index]
	if slot != null and slot.item_data != null:
		PlayerData.player_inventory_data.add_item(slot.item_data, slot.quantity)
		PlayerData.material_data.refresh(PlayerData.player_inventory_data)
		
		# 3. XÓA KHỎI CRAFT BAR
		craft_slots_data[index] = null
		update_craft_bar_ui()
		check_recipe()

# Hàm vẽ lại các ô trong Craft Bar
func update_craft_bar_ui():
	# Xóa hết con cũ
	for child in item_grid.get_children():
		child.queue_free()
	
	# Vẽ lại dựa trên mảng craft_slots_data
	for i in range(craft_slots_data.size()):
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		var data = craft_slots_data[i]
		if data:
			slot.set_slot_data(data)
			# Gắn sự kiện click để gỡ đồ ra (nếu cần)
			slot.slot_clicked.connect(func(_idx, btn): remove_ingredient(i, btn))
		else:
			slot.set_slot_data(null) # Vẽ slot rỗng

func check_recipe():
	# Reset
	recipe_texture.texture = null
	recipe_texture.modulate = Color(1, 1, 1, 1)
	valid_recipe_to_cook = null
	if cook_button: cook_button.visible = false
	
	var is_empty = true
	for s in craft_slots_data:
		if s != null: 
			is_empty = false
			break
	if is_empty: return


	if all_recipes:
		for recipe in all_recipes:
			if check_if_matches_recipe(recipe):
				if recipe.cook_result and recipe.cook_result.item_data:
					recipe_texture.texture = recipe.cook_result.item_data.texture
					recipe_texture.modulate = Color(0.8, 0.8, 0.8, 1)
					valid_recipe_to_cook = recipe
					
					if cook_button: 
						cook_button.visible = true
						
						if PlayerData.player_inventory_data.is_full():
							cook_button.disabled = true
							cook_button.modulate = Color(1, 0.5, 0.5)
						else:
							cook_button.disabled = false
							cook_button.modulate = Color(1, 1, 1)
				return
	valid_recipe_to_cook = null
	if cook_button: cook_button.visible = false

func check_if_matches_recipe(recipe: Recipe) -> bool:
	if recipe == null: return false
	
	var pot_totals = {} 
	for slot in craft_slots_data:
		if slot and slot.item_data:
			var item_name = slot.item_data.name
			if not pot_totals.has(item_name):
				pot_totals[item_name] = 0
			pot_totals[item_name] += slot.quantity
			
	for req_slot in recipe.slot_datas:
		var req_item_name = req_slot.item_data.name
		var req_amount = req_slot.quantity
		
		if not pot_totals.has(req_item_name) or pot_totals[req_item_name] < req_amount:
			return false


	for item_name_in_pot in pot_totals.keys():
		var is_valid_ingredient = false
		
		for req_slot in recipe.slot_datas:
			if req_slot.item_data.name == item_name_in_pot:
				is_valid_ingredient = true
				break
		
		if not is_valid_ingredient:
			return false

	return true

func consume_ingredients_in_pot():
	if valid_recipe_to_cook:
		var final_dish = valid_recipe_to_cook.cook_result.duplicate()
		
		# Xóa đồ
		for i in range(craft_slots_data.size()):
			craft_slots_data[i] = null
		update_craft_bar_ui()
		check_recipe()
		
		_pending_dish = final_dish

func _on_cook_button_pressed():
	if valid_recipe_to_cook == null or is_crafting: return
	
	is_crafting = true 
	if cook_button: cook_button.disabled = true 
	
	
	var time_to_cook = 2.0
	if "craft_time" in valid_recipe_to_cook:
		time_to_cook = valid_recipe_to_cook.craft_time
	
	consume_ingredients_in_pot()
	
	var hsm = PlayerData.player.limbo_hsm as LimboPrimeHSM
	hsm.cook_mode = LimboPrimeHSM.COOK_MODE.STOVE 
	hsm.cook = true
	
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
		progress_bar.max_value = 100
		
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", 100, time_to_cook)
		
		await tween.finished
		
		progress_bar.visible = false
	else:
		await get_tree().create_timer(time_to_cook).timeout

	finish_cooking()

var _pending_dish: SlotData

func finish_cooking():
	if _pending_dish:
		PlayerData.player_inventory_data.pick_up_slot_data(_pending_dish.duplicate())
		_pending_dish = null
		
		if PlayerData.material_data:
			PlayerData.material_data.refresh(PlayerData.player_inventory_data)
	
	is_crafting = false
	if cook_button: cook_button.disabled = false
	
	check_recipe()
