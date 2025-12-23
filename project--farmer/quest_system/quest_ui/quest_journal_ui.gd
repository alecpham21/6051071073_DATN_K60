extends CanvasLayer

# Kéo thả các node từ bên trái vào đây để lấy đường dẫn
@onready var journal_panel = $JournalPanel
@onready var quest_list_container = $JournalPanel/Panel/HBoxContainer/ScrollContainer/QuestList
@onready var title_label = $JournalPanel/Panel/HBoxContainer/VBoxContainer/TitleLabel
@onready var desc_label = $JournalPanel/Panel/HBoxContainer/VBoxContainer/DescLabel
@onready var progress_label = $JournalPanel/Panel/HBoxContainer/VBoxContainer/ProgressLabel

func _ready():
	journal_panel.visible = false
	
	if QuestManager.has_signal("quest_updated"):
		QuestManager.quest_updated.connect(refresh_journal)

func _input(event):
	if event.is_action_pressed("toggle_journal"):
		toggle_ui()
		get_viewport().set_input_as_handled()

func toggle_ui():
	if journal_panel.visible:
		journal_panel.visible = false
		GState.play()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		if GState.is_playing():
			journal_panel.visible = true
			refresh_journal()
			GState.journal()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func refresh_journal():
	for child in quest_list_container.get_children():
		child.queue_free()
	
	var quest_to_show = null
	
	for quest_id in QuestManager.quests:
		var q = QuestManager.quests[quest_id]
		
		if q.is_started or q.is_completed:
			var btn = Button.new()
			btn.text = q.title
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.flat = true 
			
			btn.pressed.connect(_on_quest_button_pressed.bind(q))
			
			quest_list_container.add_child(btn)
			
			
			if not q.is_completed:
				quest_to_show = q
			
			elif quest_to_show == null:
				quest_to_show = q
			
	if quest_to_show:
		_on_quest_button_pressed(quest_to_show)
	else:
		clear_details()

func _on_quest_button_pressed(quest: QuestResource):
	title_label.text = quest.title
	desc_label.text = quest.description
	
	# Reset lại màu
	if quest.is_completed:
		title_label.modulate = Color.GREEN
		progress_label.text = ">>> ĐÃ HOÀN THÀNH <<<"
	else:
		title_label.modulate = Color.CYAN
		
		var objectives_text = ""
		
		if quest.objectives.size() > 0:
			for obj in quest.objectives:
				var status_icon = "✅" if obj.is_completed else "⬜"
				
				objectives_text += "%s %s: %d / %d\n" % [
					status_icon, 
					obj.description, 
					obj.current_amount, 
					obj.target_amount
				]
		else:
			objectives_text = "Hãy thực hiện yêu cầu của NPC."
			
		progress_label.text = objectives_text

func clear_details():
	title_label.text = "Không có nhiệm vụ"
	desc_label.text = ""
	progress_label.text = ""
