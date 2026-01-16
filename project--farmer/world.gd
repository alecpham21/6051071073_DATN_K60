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
		
		var minutes_away = 0.0
		if data.has("saved_at_total_min"):
			var saved_time = data["saved_at_total_min"]
			var current_time = TimeManager.get_total_minutes_played()
			minutes_away = current_time - saved_time
		
		await ground_generator.load_from_data(data, minutes_away)
	else:
		print("✨ World: New map...")
		await ground_generator.generate_new_map()
		
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
		current_data["saved_at_total_min"] = TimeManager.get_total_minutes_played()
		
		Watcher.save_level_data(level_id, current_data)
		print("✅ World: Saved Level State ", level_id)

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.visible = not inventory_interface.visible
	
	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()

func _on_inventory_interface_drop_slot_data(slot_data) -> void:
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = player.get_drop_position()
	add_child(pick_up)
