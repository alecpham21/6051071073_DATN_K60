extends Area3D

func _ready():
	_check_active_day()
	if TimeManager.has_signal("tick"):
		TimeManager.tick.connect(_check_active_day)

func _check_active_day():
	if TimeManager.day < 2:
		visible = false
		monitoring = false
		monitorable = false
	else:
		visible = true
		monitoring = true
		monitorable = true
		
		if not area_entered.is_connected(_on_area_entered):
			area_entered.connect(_on_area_entered)
			area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D):
	var crate = area.get_parent()
	if crate is ContractCrate:
		if PlayerData.player:
			PlayerData.player.set_meta("is_in_delivery_zone", true)
		
		if not crate.dropped.is_connected(_check_delivery):
			crate.dropped.connect(_check_delivery.bind(crate))

func _on_area_exited(area: Area3D):
	var crate = area.get_parent()
	if crate is ContractCrate:
		if PlayerData.player:
			PlayerData.player.set_meta("is_in_delivery_zone", false)
			
		if crate.dropped.is_connected(_check_delivery):
			crate.dropped.disconnect(_check_delivery)

func _check_delivery(crate: ContractCrate):
	if not QuestManager.active_contract_item or not is_instance_valid(QuestManager.active_contract_item):
		return
	
	var inv = crate.inventory_data 
	var slot = inv.slot_datas[0] if inv.slot_datas.size() > 0 else null
	
	if slot and is_instance_valid(slot.item_data):
		if slot.item_data.name == QuestManager.active_contract_item.name:
			if slot.quantity >= QuestManager.contract_amount_needed:
				_complete_contract(crate)

func _complete_contract(crate: ContractCrate):
	if QuestManager.has_method("complete_quest"):
		QuestManager.complete_quest(QuestManager.current_contract_id)
	
	QuestManager.active_contract_item = null
	QuestManager.contract_amount_needed = 0
	
	if is_instance_valid(crate):
		crate.queue_free()
		print("✅ Delivery successful: Crate removed.")

	var truck = get_parent()
	if truck and truck.has_method("depart"):
		truck.depart()
