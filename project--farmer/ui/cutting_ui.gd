extends PanelContainer

signal cut_requested(recipe: Recipe)

@export var input_slot_node: PanelContainer # Kéo node Slot vào đây
@export var output_preview_node: TextureRect # Kéo TextureRect để hiện kết quả
@export var cut_btn: Button
@export var recipes: Array[Recipe] # Gán danh sách Recipe vào đây

var current_kitchen: Kitchen
var active_recipe: Recipe = null

func _ready():
	cut_btn.pressed.connect(_on_cut_btn_pressed)
	cut_btn.disabled = true
	output_preview_node.texture = null

func setup_board(kitchen: Kitchen):
	current_kitchen = kitchen
	
	var inv_data = kitchen.board_input_inv
	input_slot_node.set_slot_data(inv_data.slot_datas[0])
	
	if not inv_data.inventory_updated.is_connected(_on_input_updated):
		inv_data.inventory_updated.connect(_on_input_updated)
	
	_on_input_updated(inv_data)

func _on_input_updated(inv_data: InventoryData):
	active_recipe = null
	output_preview_node.texture = null
	cut_btn.disabled = true
	
	var input_slot = inv_data.slot_datas[0]
	if input_slot == null or input_slot.item_data == null:
		return


	for r in recipes:
		if r.station == Recipe.STATION.BOARD:
			if r.slot_datas.size() > 0 and r.slot_datas[0].item_data == input_slot.item_data:
				active_recipe = r
				output_preview_node.texture = r.goal_item.item_data.texture
				cut_btn.disabled = false
				break

func _on_cut_btn_pressed():
	if active_recipe and current_kitchen:
		cut_requested.emit(active_recipe)
