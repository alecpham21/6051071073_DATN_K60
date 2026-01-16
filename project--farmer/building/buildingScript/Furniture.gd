extends Node3D

@export_group("Animation Settings")
@export var furniture_anim_player: AnimationPlayer
@export var furniture_anim_name: String = ""
@export var player_pose_ani: AnimationSet

@export_group("Rest Stats")
@export var stamina_multiplier: float = 1.5

@export_group("Setup")
@export var marker: Marker3D

@onready var interact_area: InteractArea = $InteractArea

func _ready() -> void:
	if interact_area:
		interact_area.interacted.connect(_on_interacted)

func interact(player: Character):
	_handle_rest_logic(player)

func _on_interacted():
	var player = get_tree().get_first_node_in_group("player")
	if player: _handle_rest_logic(player)

func _handle_rest_logic(player: Character):
	var hsm = player.get_node_or_null("LimboHSM")
	var rest_state = hsm.get_node_or_null("RestingState") as RestingState
	
	if rest_state:
		if hsm.get_active_state() == rest_state:
			hsm.dispatch("idle")
			if furniture_anim_player: furniture_anim_player.stop()
			return
		
		rest_state.target_marker = marker
		rest_state.target_ani = player_pose_ani
		rest_state.stamina_regen_multiplier = stamina_multiplier
		
		if furniture_anim_player and furniture_anim_player.has_animation(furniture_anim_name):
			furniture_anim_player.play(furniture_anim_name)
		
		hsm.dispatch("rest")
		print("DEBUG: [Furniture] Custom rest triggered")
