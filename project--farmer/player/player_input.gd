extends Node
class_name PlayerInput

@export var player: CharacterBody3D
@export var player_actions: PlayerActions
@export var limbo_hsm: LimboHSM

var blackboard: Blackboard
var interact_timer: float = 0.0
var is_interact_held: bool = false

func _ready() -> void:
	await get_tree().process_frame
	if limbo_hsm:
		blackboard = limbo_hsm.blackboard

func _process(delta: float) -> void:
	if not blackboard or not player_actions: return
	
	if Input.is_action_pressed("aim"): 
		blackboard.set_var(BBNames.direction_var, Vector3.ZERO)
		blackboard.set_var(BBNames.run_var, false)
		blackboard.set_var(BBNames.use_item_var, false)
		blackboard.set_var(BBNames.interact_var, false)
		blackboard.set_var(BBNames.toggle_vehicle_var, false)
		return
	
	if GState.is_journal() or GState.is_shop() or GState.is_dialog() or GState.is_ui():
		blackboard.set_var(BBNames.direction_var, Vector3.ZERO)
		blackboard.set_var(BBNames.run_var, false)
		blackboard.set_var(BBNames.use_item_var, false)
		is_interact_held = false 
		return

	var input_vec2 = Input.get_vector(
		player_actions.move_left, 
		player_actions.move_right, 
		player_actions.move_forward, 
		player_actions.move_backward
	)
	var input_vec3 = Vector3(input_vec2.x, 0, input_vec2.y)
	blackboard.set_var(BBNames.direction_var, input_vec3)

	var is_running = Input.is_action_pressed(player_actions.run) if player_actions.run else false
	blackboard.set_var(BBNames.run_var, is_running)

	var using_item = Input.is_action_pressed(player_actions.use_item) if player_actions.use_item else false
	blackboard.set_var(BBNames.use_item_var, using_item)

	if GState.is_journal() or GState.is_shop() or GState.is_dialog() or GState.is_ui():
		is_interact_held = false
		interact_timer = 0.0
		return
	
	if not GState.is_playing():
		is_interact_held = false
		interact_timer = 0.0
		return

	var interact_triggered = false
	
	if is_interact_held and player.carried_node == null:
		interact_timer += delta
		if interact_timer >= 0.4:
			interact_triggered = true
			is_interact_held = false 
			print("HOLD: Pick up triggered")

	blackboard.set_var(BBNames.interact_var, interact_triggered)
		
	if player_actions.toggle_vehicle and Input.is_action_just_pressed(player_actions.toggle_vehicle):
		blackboard.set_var(BBNames.toggle_vehicle_var, true)
	else:
		blackboard.set_var(BBNames.toggle_vehicle_var, false)

func _unhandled_input(event: InputEvent) -> void:
	if not player_actions or not player_actions.interact: return
	
	if event.is_action_pressed(player_actions.interact) and GState.is_playing():
		is_interact_held = true
		interact_timer = 0.0
		blackboard.set_var(BBNames.interact_var, false)

	if event.is_action_released(player_actions.interact):
		if is_interact_held:
			if player.carried_node != null:
				blackboard.set_var(BBNames.interact_var, true)
				print("TAP: Triggering PlaceDownState via HSM")
			
			elif interact_timer < 0.3:
				if player.current_interactable:
					if player.current_interactable.has_method("open_crate_inventory"):
						player.current_interactable.open_crate_inventory()
					else:
						player.interact()
			
			is_interact_held = false
