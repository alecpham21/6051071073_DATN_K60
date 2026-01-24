extends Node3D

@export var travel_time: float = 4.0
@export var landing_time: float = 1.5
@export var hover_height: float = 1.0

var target_marker: Marker3D
var depart_marker: Marker3D

var has_arrived: bool = false
var has_departed: bool = false
var is_active: bool = false

@onready var delivery_zone: Area3D = $DeliveryZone

func _ready():
	visible = false
	if delivery_zone:
		delivery_zone.monitoring = false
	TimeManager.tick.connect(_on_time_tick)

func _on_time_tick():
	var current_min = int(TimeManager.current_time)
	
	if QuestManager.active_contract_item == null:
		return
		
	if TimeManager.day == QuestManager.contract_deadline_day:
		if current_min >= 340 and current_min < 920 and not has_arrived:
			has_arrived = true
			arrive()
		
		if current_min >= 920 and not has_departed and has_arrived:
			has_departed = true
			depart()

func arrive():
	is_active = true
	target_marker = get_tree().current_scene.find_child("DeliveryMarker", true, false)
	
	if not target_marker:
		print("Truck Error: DeliveryMarker not found!")
		return
	
	visible = true
	
	var travel_pos = target_marker.global_position + Vector3(0, hover_height, 0)
	var travel_tween = create_tween()
	
	print("Truck: Flying to target coordinates...")
	travel_tween.tween_property(self, "global_position", travel_pos, travel_time)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	await travel_tween.finished
	
	print("Truck: Aligning and landing...")
	var land_tween = create_tween().set_parallel(true)
	
	land_tween.tween_property(self, "global_rotation", target_marker.global_rotation, landing_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	land_tween.tween_property(self, "global_position", target_marker.global_position, landing_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	await land_tween.finished
	
	if delivery_zone:
		delivery_zone.monitoring = true
	print("Truck: Landing complete. Ready for delivery.")

func depart():
	if not is_active: return
	is_active = false
	
	if delivery_zone:
		delivery_zone.monitoring = false
		
	depart_marker = get_tree().current_scene.find_child("DepartMarker", true, false)
	
	if not depart_marker:
		print("Truck Warning: DepartMarker not found! Using default exit.")
		_default_depart()
		return

	print("Truck: Lifting off...")
	var lift_tween = create_tween().set_parallel(true)
	var lift_pos = global_position + Vector3(0, hover_height, 0)
	
	lift_tween.tween_property(self, "global_position", lift_pos, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	lift_tween.tween_property(self, "global_rotation", depart_marker.global_rotation, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	await lift_tween.finished

	print("Truck: Departing to DepartMarker...")
	var depart_tween = create_tween()
	depart_tween.tween_property(self, "global_position", depart_marker.global_position, travel_time)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	await depart_tween.finished
	queue_free()

func _default_depart():
	var exit_pos = global_position + Vector3(0, 30, -10)
	var tween = create_tween()
	tween.tween_property(self, "global_position", exit_pos, travel_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()

func get_save_data() -> Dictionary:
	return {
		"has_arrived": has_arrived,
		"has_departed": has_departed,
		"is_active": is_active,
		"pos": var_to_str(global_position),
		"rot": var_to_str(global_rotation)
	}

func load_save_data(data: Dictionary):
	has_arrived = data.get("has_arrived", false)
	has_departed = data.get("has_departed", false)
	is_active = data.get("is_active", false)
	
	if data.has("pos"):
		global_position = str_to_var(data.pos)
		global_rotation = str_to_var(data.rot)
	
	if has_arrived and not has_departed:
		visible = true
		is_active = true
		if delivery_zone:
			delivery_zone.monitoring = true
		print("[DEBUG] Truck: Restored to port position instantly.")
