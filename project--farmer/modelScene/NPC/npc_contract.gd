extends Node3D

@export var initial_timeline: String = "npc_trade_contract"
@export var busy_timeline: String = "npc_busy"
@export var no_money_timeline: String = "npc_no_money"
@export var fee_per_crate: int = 2000
@export var reward_per_crate: int = 3000

@onready var interact_area = $InteractArea


func _ready():
	if interact_area:
		interact_area.interacted.connect(_on_interacted)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_interacted():
	Dialogic.VAR.Contract.fee_per_crate = fee_per_crate
	Dialogic.VAR.Contract.reward_per_crate = reward_per_crate
	if QuestManager.active_contract_item != null:
		print("NPC Debug: Player is busy.")
		Dialogic.start(busy_timeline)
	else:
		print("NPC Debug: Starting contract timeline.")
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
			
			var total_fee = crates * fee_per_crate
			
			if total_qty > 0 and item_id != "":
				if PlayerData.money >= total_fee:
					PlayerData.money -= total_fee
					PlayerData.money_changed.emit(PlayerData.money)
					
					QuestManager.start_trade_contract(item_id, total_qty, days)
					print("NPC English Debug: Contract started. Item: ", item_id, " | Fee: ", total_fee)
				else:
					print("NPC English Debug: Insufficient funds. Required: ", total_fee)
					Dialogic.start(no_money_timeline)
			else:
				printerr("NPC English Debug: Invalid data received from Dialogic.")

func _on_timeline_ended():
	if GState.is_ui():
		GState.play()
