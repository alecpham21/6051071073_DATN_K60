extends Control

@onready var container = $Background/Container
@onready var toggle_btn = $Background/Container/ToggleBtn
@onready var quest_list = $Background/Container/QuestList

var is_expanded: bool = false

func _ready():
	quest_list.visible = false
	_update_layout_state()
	
	toggle_btn.pressed.connect(_on_toggle_pressed)
	
	if QuestManager.has_signal("quest_updated"):
		QuestManager.quest_updated.connect(update_tracker)
	
	update_tracker()

func _on_toggle_pressed():
	is_expanded = !is_expanded
	quest_list.visible = is_expanded
	_update_layout_state()

func _update_layout_state():
	if is_expanded:
		toggle_btn.text = ">"
		container.move_child(toggle_btn, 0)
	else:
		toggle_btn.text = "<"

		container.move_child(toggle_btn, 1)

func update_tracker():
	await get_tree().process_frame
	
	for child in quest_list.get_children():
		child.queue_free()
	
	var count = 0
	
	# 2. Duyệt qua danh sách nhiệm vụ
	for quest_id in QuestManager.quests:
		var q = QuestManager.quests[quest_id]
		
		# Chỉ hiện những quest ĐANG LÀM (Chưa xong)
		if q.is_started and not q.is_completed:
			print("🖥️ Tracker đang vẽ quest: ", q.id)
			if count >= 3: break # Giới hạn hiện tối đa 3 nhiệm vụ để đỡ rối
			
			# --- A. TẠO TÊN NHIỆM VỤ (Màu Vàng cho nổi) ---
			var title_label = Label.new()
			title_label.text = "★ " + q.title
			title_label.add_theme_font_size_override("font_size", 16) # Chữ to hơn chút
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			title_label.modulate = Color.YELLOW
			quest_list.add_child(title_label)
			
			for obj in q.objectives:
				var obj_label = Label.new()
				var icon = "✅" if obj.is_completed else "⬜"
				
				obj_label.text = "%s %s: %d/%d" % [icon, obj.description, obj.current_amount, obj.target_amount]
				
				obj_label.add_theme_font_size_override("font_size", 14)
				obj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				obj_label.modulate = Color.WHITE
				
				quest_list.add_child(obj_label)
			
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 10)
			quest_list.add_child(spacer)
			
			count += 1
	
	if count == 0:
		var label = Label.new()
		label.text = "Không có nhiệm vụ"
		label.add_theme_font_size_override("font_size", 14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		quest_list.add_child(label)
	
	visible = true
