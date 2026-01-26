extends Level
class_name Town


const PickUp = preload("res://inventory_script/item/pick_up_item/pick_up.tscn")
const TOWN_THEME = preload("res://audio/theme/TownTheme.mp3")

@onready var player: CharacterBody3D = %MainFarmer
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory

func _ready():
	var bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = TOWN_THEME
	bgm_player.autoplay = true
	bgm_player.bus = "Music"
	add_child(bgm_player)
	
	Watcher.indoor = false
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.set_outfit_inventory_data(player.outfit_inventory_data)
	inventory_interface.force_close.connect(toggle_inventory_interface)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	GameData.set_current_stage(self)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
	SceneTransition.reveal_scene()

func _process(_delta: float) -> void:
	if TimeManager.current_hour >= 20:
		var farm_return_pos = Vector3(0, 1, 0) 
		
		set_process(false) 
		
		print("🌙 Late night: Returning to farm...")
		SceneTransition.change_scene("res://world.tscn", farm_return_pos)

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
