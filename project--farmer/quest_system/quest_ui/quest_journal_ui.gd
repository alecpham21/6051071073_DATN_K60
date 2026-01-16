extends CanvasLayer

@onready var journal_panel = $JournalPanel

@onready var type_tabs = $JournalPanel/Panel/MainVBox/TypeTabBar

@onready var quest_list_container = $JournalPanel/Panel/MainVBox/ContentHBox/ScrollContainer/QuestList

@onready var title_label = $JournalPanel/Panel/MainVBox/ContentHBox/DetailsVBox/TitleLabel
@onready var desc_label = $JournalPanel/Panel/MainVBox/ContentHBox/DetailsVBox/DescLabel
@onready var progress_label = $JournalPanel/Panel/MainVBox/ContentHBox/DetailsVBox/ProgressLabel

var current_tab_filter: int = 0 

func _ready():
	journal_panel.visible = false
	
	if type_tabs:
		type_tabs.clear_tabs()
		type_tabs.add_tab("MAIN")      
		type_tabs.add_tab("FARMING")   
		type_tabs.add_tab("LIVESTOCK") 
		type_tabs.add_tab("SIDE")      
		
		type_tabs.current_tab = 0
		type_tabs.tab_changed.connect(_on_tab_changed)
	
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

func _on_tab_changed(tab_idx: int):
	current_tab_filter = tab_idx
	refresh_journal()
	clear_details()

func refresh_journal():
	# Xóa danh sách cũ
	for child in quest_list_container.get_children():
		child.queue_free()
	
	var first_quest = null
	var has_quest = false
	
	for quest_id in QuestManager.quests:
		var q = QuestManager.quests[quest_id]
		
		# Lọc theo Tab
		if int(q.quest_type) != current_tab_filter:
			continue
			
		if q.is_started or q.is_completed:
			has_quest = true
			var btn = Button.new()
			
			var prefix = "✔ " if q.is_completed else "➤ "
			btn.text = prefix + q.title
			
			# Canh lề trái cho chữ đẹp hơn
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.flat = true 
			
			if q.is_completed:
				btn.modulate = Color.GREEN
				btn.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			else:
				btn.add_theme_color_override("font_color", Color.WHITE)
			
			btn.pressed.connect(_on_quest_button_pressed.bind(q))
			quest_list_container.add_child(btn)
			
			if not q.is_completed and first_quest == null:
				first_quest = q
			elif first_quest == null:
				first_quest = q
	
	if not has_quest:
		var empty_lbl = Label.new()
		empty_lbl.text = "(Empty)"
		empty_lbl.modulate = Color(1, 1, 1, 0.5)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quest_list_container.add_child(empty_lbl)
				
	if first_quest:
		_on_quest_button_pressed(first_quest)
	else:
		clear_details()

func _on_quest_button_pressed(quest: QuestResource):
	title_label.text = quest.title
	desc_label.text = quest.description
	
	match quest.quest_type:
		QuestResource.QuestType.MAIN: title_label.modulate = Color(1, 0.8, 0.2)
		QuestResource.QuestType.FARMING: title_label.modulate = Color(0.4, 0.9, 0.4)
		QuestResource.QuestType.LIVESTOCK: title_label.modulate = Color(0.9, 0.6, 0.3)
		_: title_label.modulate = Color(0.4, 0.8, 1)
	
	if quest.is_completed:
		title_label.modulate = Color.GREEN
		progress_label.text = ">>> COMPLETED <<<"
	else:
		var txt = ""
		if quest.objectives.size() > 0:
			for obj in quest.objectives:
				var icon = "✅" if obj.is_completed else "⬜"
				txt += "%s %s: %d / %d\n" % [icon, obj.description, obj.current_amount, obj.target_amount]
		else:
			txt = "Follow instructions."
		progress_label.text = txt

func clear_details():
	title_label.text = "Select a Quest..."
	title_label.modulate = Color.WHITE
	desc_label.text = ""
	progress_label.text = ""
