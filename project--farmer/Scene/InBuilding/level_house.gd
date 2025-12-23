extends Level


const PickUp = preload("res://inventory_script/item/pick_up_item/pick_up.tscn")

@onready var player: CharacterBody3D = %MainFarmer
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory

func _ready():
	Watcher.indoor = true
	
	if player.cam_ref and "lock_movement" in player.cam_ref:
		player.cam_ref.lock_movement = true

	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.set_outfit_inventory_data(player.outfit_inventory_data)
	inventory_interface.force_close.connect(toggle_inventory_interface)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	inventory_interface.set_material_inventory_data(PlayerData.material_data)
	GameData.set_current_stage(self)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
	SceneTransition.reveal_scene()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
