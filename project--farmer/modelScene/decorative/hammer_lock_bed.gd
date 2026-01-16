extends Node3D

@export var anim_player: AnimationPlayer
@export var anim_name: String = "HammerBed_Swing"
@export var marker: Marker3D

@onready var interact_area: InteractArea = $InteractArea

func _ready() -> void:
	if interact_area:
		interact_area.interacted.connect(_on_interacted)

func interact(player: Character):
	_start_resting(player)

func _on_interacted():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_start_resting(player)
	else:
		print("DEBUG: [Hammock] No player found in group")

func _start_resting(player: Character):
	var hsm = player.get_node_or_null("LimboHSM")
	if not hsm: return
	
	var rest_state = hsm.get_node_or_null("RestingState")
	
	if rest_state:
		if hsm.get_active_state() == rest_state:
			hsm.dispatch("idle")
			if anim_player: 
				anim_player.stop()
			print("DEBUG: [Hammock] Player is getting up")
			return
		
		rest_state.hammock_marker = marker
		if anim_player and anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		
		hsm.dispatch("rest")
		print("DEBUG: [Hammock] Player is lying down")
