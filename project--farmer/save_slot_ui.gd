extends Panel

@onready var v_box: VBoxContainer = $CenterContainer/VBoxContainer
@onready var back_btn: Button = $CenterContainer/VBoxContainer/BackBtn

var is_loading_mode: bool = false

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.pressed.connect(hide)
	
	for i in range(1, 4):
		var slot_node = v_box.get_node("Slot" + str(i))
		if slot_node:
			slot_node.pressed.connect(_on_slot_selected.bind("slot_" + str(i)))
	
	visibility_changed.connect(_refresh_slots_info)

func _refresh_slots_info() -> void:
	if not visible: return
	
	for i in range(1, 4):
		var slot_node = v_box.get_node("Slot" + str(i))
		var slot_name = "slot_" + str(i)
		var path = SaveManager.get_save_path(slot_name)
		
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			var data = file.get_var()
			file.close()
			slot_node.text = "Slot %d: Day %d - %d Gold" % [i, data.time.day, data.player.money]
		else:
			slot_node.text = "Slot %d: (Empty)" % i

func _on_slot_selected(slot_name: String) -> void:
	if is_loading_mode:
		SaveManager.load_game(slot_name)
		hide()
		get_tree().paused = false
	else:
		SaveManager.save_game(slot_name)
		_refresh_slots_info()
