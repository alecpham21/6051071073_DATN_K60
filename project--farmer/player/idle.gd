extends MainState
class_name IdleState


@export var idle_ani: AnimationSet
@export var hold_ani: AnimationSet
var local_holding: bool

func _enter() -> void:
	super()
	character.velocity = Vector3.ZERO
	
	local_holding = limbo_hsm.long_tool
	_play_proper_idle()

func _update(delta: float) -> void:
	super(delta)
	
	if character.velocity.length() > 0.1:
		dispatch("move")
		return

	if local_holding != limbo_hsm.long_tool:
		dispatch("self")
		
	if limbo_hsm.cook: 
		dispatch("cook")
	
	check_tool_transitions()

func _play_proper_idle() -> void:
	if local_holding and hold_ani:
		hold_ani.play(character.ani)
	elif idle_ani:
		idle_ani.play(character.ani)
