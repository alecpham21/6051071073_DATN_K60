extends Node3D

@export var npc_scenes: Array[PackedScene]
@export var spawn_points_parent: Node3D
@export var target_points_parent: Node3D
@export var despawn_point: Marker3D
@export var max_npcs: int = 10
@export_range(0.0, 1.0) var wander_chance: float = 0.6

var spawn_rate_low: float = 0.3
var spawn_rate_peak: float = 0.9

var available_targets: Array[Marker3D] = []
var occupied_targets: Dictionary = {}
var current_npcs: Array = []

func _ready() -> void:
	for child in target_points_parent.get_children():
		if child is Marker3D:
			available_targets.append(child)
			occupied_targets[child] = null
	
	_initial_npc_placement()
	
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_spawn_tick)
	add_child(timer)
	timer.start()

func _initial_npc_placement() -> void:
	var hour = TimeManager.current_hour
	if hour >= 6 and hour < 17:
		var initial_count = randi_range(max_npcs / 2, max_npcs - 2)
		print("Initial placement: ", initial_count)
		for i in range(initial_count):
			spawn_npc(true, true)

func _on_spawn_tick() -> void:
	var hour = TimeManager.current_hour
	if hour >= 17 or hour < 5: return
	if current_npcs.size() >= max_npcs: return

	var chance = 0.0
	if hour >= 6 and hour < 7:
		chance = spawn_rate_peak
	elif (hour >= 5 and hour < 6) or (hour >= 7 and hour < 17):
		chance = spawn_rate_low
	
	if randf() < chance:
		spawn_npc(false)

func spawn_npc(at_target: bool = false, is_initial: bool = false) -> void:
	if npc_scenes.is_empty(): return
	var free_spots = _get_free_spots()
	if free_spots.is_empty(): return

	var target_spot = free_spots.pick_random()
	var npc = npc_scenes.pick_random().instantiate()
	add_child(npc)
	
	if at_target:
		npc.global_transform = target_spot.global_transform
	else:
		npc.global_position = spawn_points_parent.get_children().pick_random().global_position
	
	npc.setup_ai(target_spot, despawn_point, is_initial) 
	
	occupied_targets[target_spot] = npc
	current_npcs.append(npc)
	npc.tree_exiting.connect(func(): _on_npc_despawned(target_spot, npc))

func request_next_target(npc_ref, current_spot: Marker3D) -> Node3D:
	if randf() < wander_chance:
		var free_spots = _get_free_spots()
		if free_spots.size() > 0:
			var new_spot = free_spots.pick_random()
			occupied_targets[current_spot] = null
			occupied_targets[new_spot] = npc_ref
			return new_spot

	occupied_targets[current_spot] = null
	
	if current_npcs.size() <= max_npcs: 
		spawn_npc(false)
		
	return despawn_point

func _get_free_spots() -> Array:
	var list = []
	for spot in available_targets:
		if occupied_targets[spot] == null:
			list.append(spot)
	return list

func _on_npc_despawned(spot: Marker3D, npc_ref) -> void:
	if occupied_targets.has(spot) and occupied_targets[spot] == npc_ref:
		occupied_targets[spot] = null
	
	if npc_ref in current_npcs:
		current_npcs.erase(npc_ref)
		print("NPC đã rời map. Số lượng còn lại: ", current_npcs.size())
