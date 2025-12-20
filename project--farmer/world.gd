extends Level

const PickUp = preload("res://inventory_script/item/pick_up_item/pick_up.tscn")

@export var level_id: String = "Home_Farm"

@onready var ground_generator = $SubViewportContainer/SubViewport/GroundGenerator

@onready var player: CharacterBody3D = %MainFarmer
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory

func _ready():
	Watcher.indoor = false
	
	if Watcher.has_data(level_id):
		print("📂 World: Load data...")
		var data = Watcher.get_level_data(level_id)
		await ground_generator.load_from_data(data) 
	else:
		print("✨ World: New map...")
		await ground_generator.generate_new_map()
		
	if Watcher.has_data(level_id):
		print("📂 World: Tìm thấy dữ liệu cũ của ", level_id, " -> Đang Load...")
		var data = Watcher.get_level_data(level_id)
		ground_generator.load_from_data(data)
	else:
		print("✨ World: Không có dữ liệu của ", level_id, " -> Tạo Mới...")
		ground_generator.generate_new_map()
		
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.set_outfit_inventory_data(player.outfit_inventory_data)
	inventory_interface.force_close.connect(toggle_inventory_interface)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	if GameData.has_method("set_current_stage"):
		GameData.set_current_stage(self)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)

	
	SceneTransition.reveal_scene()

func save_level_state():
	if ground_generator:
		var current_data = ground_generator.get_current_state()
		
		Watcher.save_level_data(level_id, current_data)
		print("✅ World: Đã lưu trạng thái map ", level_id)


func _process(_delta: float) -> void:
	pass

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	if inventory_interface.visible:
		inventory_interface.close_kitchen()
		
		inventory_interface.clear_external_inventory()
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	else:
		if external_inventory_owner:
			inventory_interface.set_external_inventory(external_inventory_owner)
			inventory_interface.open_player_inventory()
		else:
			inventory_interface.open_player_inventory()
			
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_inventory_interface_drop_slot_data(slot_data) -> void:
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = player.get_drop_position()
	add_child(pick_up)
