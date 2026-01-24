extends PanelContainer

@onready var chicken_slot = $HBoxContainer/ChickenSlot
@onready var progress_bar = $HBoxContainer/VBoxContainer/ProgressBar
@onready var feed_label = $HBoxContainer/VBoxContainer/Label
@onready var egg_output_slot = $HBoxContainer/EggOutputSlot

var machine_ref: CoopMachine
var row_index: int

func update_row(index: int, machine: CoopMachine):
	if not is_node_ready():
		await ready
		
	machine_ref = machine
	row_index = index
	
	var data = machine.chickens[index]
	var in_slot = machine.input_inv.slot_datas[index]
	var out_slot = machine.output_inv.slot_datas[index]
	
	if chicken_slot:
		chicken_slot.set_slot_data(in_slot)
	if egg_output_slot:
		egg_output_slot.set_slot_data(out_slot)
		egg_output_slot.is_output_only = true

	if data:
		if data.gender == LivestockEnums.Gender.MALE or data.stage == LivestockEnums.Stage.BABY:
			progress_bar.visible = false
		else:
			progress_bar.visible = true
			progress_bar.value = data.egg_progress
			
		feed_label.text = "Feed: %d/%d" % [data.feed_count, data.get_max_feed()]
	else:
		progress_bar.visible = false
		feed_label.text = "Empty"

	if not chicken_slot.slot_clicked.is_connected(_on_slot_clicked):
		chicken_slot.slot_clicked.connect(_on_slot_clicked.bind(machine.input_inv))
	
	if not egg_output_slot.slot_clicked.is_connected(_on_slot_clicked):
		egg_output_slot.slot_clicked.connect(_on_slot_clicked.bind(machine.output_inv))

func _on_slot_clicked(_idx: int, btn: int, target_inv: InventoryData):
	var interface = get_tree().get_first_node_in_group("inventory_interface")
	if not interface: return

	if target_inv == machine_ref.input_inv and interface.grabbed_slot_data:
		var new_item = interface.grabbed_slot_data.item_data
		if new_item is ItemDataLivestock:
			var current_stage = machine_ref.get_coop_stage(row_index)
			
			if current_stage != -1 and current_stage != new_item.stage:
				print("❌ Không được nuôi xen kẽ các lứa tuổi khác nhau!")
				return

	interface.on_inventory_interact(target_inv, row_index, btn)
