extends Level

const PickUp = preload("res://inventory_script/item/pick_up_item/pick_up.tscn")

# --- [MỚI] KHAI BÁO QUẢN LÝ ---
# 1. Đặt tên ID cho Level này (Trong Inspector nhớ đổi tên khác nhau cho mỗi Scene, vd: "Home", "Forest")
@export var level_id: String = "Home_Farm"

# 2. Tham chiếu đến GroundGenerator (Thợ vẽ)
# Lưu ý: Đường dẫn này dựa trên hình ông gửi. Nếu lỗi node not found thì chuột phải vào node GroundGenerator chọn "Access as Unique Name" rồi sửa thành %GroundGenerator
@onready var ground_generator = $SubViewportContainer/SubViewport/GroundGenerator
# ------------------------------

@onready var player: CharacterBody3D = %MainFarmer
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory

func _ready():
	Watcher.indoor = false
	
	# --- [SỬA] THÊM await VÀO ĐÂY ---
	if Watcher.has_data(level_id):
		print("📂 World: Load data...")
		var data = Watcher.get_level_data(level_id)
		# Chờ GroundGenerator setup xong rồi mới load
		await ground_generator.load_from_data(data) 
	else:
		print("✨ World: New map...")
		# Chờ GroundGenerator setup xong rồi mới gen
		await ground_generator.generate_new_map()
		
	# Hỏi thằng trùm Watcher xem có dữ liệu của map này chưa
	if Watcher.has_data(level_id):
		print("📂 World: Tìm thấy dữ liệu cũ của ", level_id, " -> Đang Load...")
		var data = Watcher.get_level_data(level_id)
		# Quăng data cho thợ vẽ làm việc
		ground_generator.load_from_data(data)
	else:
		print("✨ World: Không có dữ liệu của ", level_id, " -> Tạo Mới...")
		# Bảo thợ vẽ tạo map trắng
		ground_generator.generate_new_map()
		
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.set_outfit_inventory_data(player.outfit_inventory_data)
	inventory_interface.force_close.connect(toggle_inventory_interface)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	# Lưu ý: Nếu Watcher và GameData là 1 thì dùng Watcher, nếu khác nhau thì giữ nguyên
	if GameData.has_method("set_current_stage"):
		GameData.set_current_stage(self)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
	SceneTransition.reveal_scene()
# --- [MỚI] HÀM SAVE (Sẽ được gọi bởi Cổng dịch chuyển hoặc Menu Save) ---
func save_level_state():
	if ground_generator:
		# 1. Lấy dữ liệu hiện tại từ thợ vẽ
		var current_data = ground_generator.get_current_state()
		
		# 2. Gửi về kho tổng Watcher để cất
		Watcher.save_level_data(level_id, current_data)
		print("✅ World: Đã lưu trạng thái map ", level_id)

# --- (CÁC HÀM CŨ GIỮ NGUYÊN) ---
func _process(_delta: float) -> void:
	pass

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
