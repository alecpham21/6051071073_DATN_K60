extends PanelContainer

@export var input_slot_node: PanelContainer 
@export var output_preview_node: TextureRect 
@export var cut_btn: Button 

@export var recipes: Array[Recipe] 
@export var progress_bar: ProgressBar

var current_kitchen: Board
var active_recipe: Recipe = null
var is_cutting: bool = false

func _ready():
	visible = false
	cut_btn.pressed.connect(_on_cut_btn_pressed)
	cut_btn.disabled = true
	output_preview_node.visible = false
	
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0
	
	GameData.game_state_changed.connect(func(old, new):
		if old == GState.state_enum.COOK and new != GState.state_enum.COOK:
			close_ui()
			is_cutting = false
			if progress_bar: progress_bar.visible = false
	)

func setup_board(kitchen: Board):
	current_kitchen = kitchen
	visible = true
	
	if not current_kitchen.inventory_data.inventory_updated.is_connected(check_recipe):
		current_kitchen.inventory_data.inventory_updated.connect(check_recipe)
	
	if input_slot_node.has_signal("slot_clicked"):
		if input_slot_node.slot_clicked.is_connected(on_input_slot_clicked):
			input_slot_node.slot_clicked.disconnect(on_input_slot_clicked)
		
		input_slot_node.slot_clicked.connect(on_input_slot_clicked)
	
	check_recipe(current_kitchen.inventory_data)

func on_input_slot_clicked(_index: int, _btn: int):
	if is_cutting: return
	
	var inv = current_kitchen.inventory_data
	var slot = inv.slot_datas[0]
	
	if slot and slot.item_data:
		PlayerData.player_inventory_data.add_item(slot.item_data, slot.quantity)
		
		inv.slot_datas[0] = null
		inv.inventory_updated.emit(inv)
		
		if PlayerData.material_data:
			PlayerData.material_data.refresh(PlayerData.player_inventory_data)

func check_recipe(inv_data: InventoryData):
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
					
					if not is_cutting:
						cut_btn.disabled = false
				break


func _on_cut_btn_pressed():
	if active_recipe == null or current_kitchen == null or is_cutting: return
	
	is_cutting = true
	cut_btn.disabled = true
	
	var hsm = PlayerData.player.limbo_hsm as LimboPrimeHSM
	hsm.cook_mode = LimboPrimeHSM.COOK_MODE.BOARD
	hsm.cook = true 
	
	var time_to_cut = 2.0
	if "craft_time" in active_recipe:
		time_to_cut = active_recipe.craft_time
		
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
		progress_bar.max_value = 100
		
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", 100, time_to_cut)
		
		await tween.finished
		
		progress_bar.visible = false
	else:
		await get_tree().create_timer(time_to_cut).timeout
	
	finish_cutting()

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

	is_cutting = false
	check_recipe(current_kitchen.inventory_data)

func close_ui():
	visible = false
	if current_kitchen and current_kitchen.inventory_data.inventory_updated.is_connected(check_recipe):
		current_kitchen.inventory_data.inventory_updated.disconnect(check_recipe)
