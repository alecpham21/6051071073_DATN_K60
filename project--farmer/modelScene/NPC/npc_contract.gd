extends Node3D

@export var initial_timeline: String = "npc_trade_contract"
@export var busy_timeline: String = "npc_busy"
@onready var interact_area = $InteractArea

func _ready():
	if interact_area:
		interact_area.interacted.connect(_on_interacted)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_interacted():
	if QuestManager.active_contract_item != null:
		print("NPC Debug: Player is busy with contract: ", QuestManager.active_contract_item.name)
		Dialogic.start(busy_timeline)
	else:
		print("NPC Debug: Starting new contract dialogue.")
		Dialogic.start(initial_timeline)
	
	GState.ui()

func _on_dialogic_signal(argument: String):
	if argument.begins_with("start_contract"):
		var parts = argument.split(":")
		if parts.size() >= 2:
			var days = int(parts[1])
			var item_id = Dialogic.VAR.Contract.selected_item
			var crates = int(Dialogic.VAR.Contract.selected_crates)
			var total_qty = crates * 20
			
			if total_qty > 0 and item_id != "":
				QuestManager.start_trade_contract(item_id, total_qty, days)
				print("NPC English Debug: Contract accepted for ", item_id)
			else:
				printerr("NPC English Debug: Failed to start contract due to invalid data.")

func _on_timeline_ended():
	if GState.is_ui():
		GState.play()
