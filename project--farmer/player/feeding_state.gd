extends MainState
class_name FeedingState

@export_group("Animations")
@export var feed_ani: AnimationSet

const FEED_VFX = preload("res://Scene/vfx/feed_scatter.tscn")

func _enter() -> void:
	super()
	var item = HotBar.active_item
	
	if item is ItemDataUsable and ("feed" in item.name.to_lower() or "seed" in item.name.to_lower()):
		character.is_busy = true
		character.velocity = Vector3.ZERO
		
		if feed_ani: 
			feed_ani.play(character.ani)
		
		get_tree().create_timer(0.3).timeout.connect(func():
			if character.is_busy:
				spawn_feed_effect()
		)
		
		character.ani.animation_finished.connect(func(a):
			apply_feeding()
			dispatch("idle")
		, CONNECT_ONE_SHOT)
	else:
		dispatch("idle")

func spawn_feed_effect() -> void:
	var vfx = FEED_VFX.instantiate()
	get_tree().root.add_child(vfx)
	
	var forward = -character.global_transform.basis.z 
	var spawn_pos = character.global_position + (forward * 0.8)
	spawn_pos.y += 0.2
	
	vfx.global_position = spawn_pos
	vfx.global_rotation = character.global_rotation


func apply_feeding() -> void:
	var areas = character.interact_area.get_overlapping_areas()
	var machine: LivestockMachine = null
	
	for a in areas:
		machine = _find_livestock_machine(a)
		if machine: break
	
	if machine:
		if machine.feed_livestock(HotBar.active_item):
			print("✅ Cho ăn thành công vào: ", machine.name)
			_consume_active_item()
	else:
		print("❌ Không tìm thấy máy nào trong vùng để cho ăn!")

func _find_livestock_machine(node: Node) -> LivestockMachine:
	var curr = node
	while curr != null:
		if curr is LivestockMachine:
			return curr
		curr = curr.get_parent()
	return null

func _consume_active_item() -> void:
	var index = PlayerData.player_inventory_data.slot_datas.find(HotBar.active_slot)
	if index != -1:
		PlayerData.player_inventory_data.actual_use_slot_data(index)
