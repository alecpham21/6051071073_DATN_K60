extends Control

var current_machine: WashingMachine 

@onready var inventory_ui = $VBoxContainer/Inventory
@onready var start_button = $VBoxContainer/StartButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)

# Hàm này để bên ngoài (InventoryInterface) gọi khi mở UI lên
func setup_machine_ui(machine: WashingMachine):
	current_machine = machine
	
	if inventory_ui.has_method("set_inventory_data"):
		inventory_ui.set_inventory_data(machine.inventory_data)
	
	start_button.disabled = machine.is_washing
	
	if machine.is_washing:
		start_button.text = "Đang giặt..."
	else:
		start_button.text = "Bắt đầu giặt"


func _on_start_button_pressed():
	if current_machine:
		current_machine.request_start_washing()
