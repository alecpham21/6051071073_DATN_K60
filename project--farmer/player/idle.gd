extends GardeningState

@export var idle_ani:AnimationSet
@export var hold_ani:AnimationSet
var local_holding:bool

func _enter() -> void:
	super()
	character.velocity = Vector3.ZERO
	local_holding = limbo_hsm.long_tool
	if limbo_hsm.long_tool: hold_ani.play(character.ani)
	else: idle_ani.play(character.ani)

func _update(delta: float) -> void:
	super(delta)

func check_dispatch():
	if !(character.velocity).is_zero_approx(): dispatch("move")
	if limbo_hsm.can_till(): dispatch("till")
	if limbo_hsm.can_plant(): dispatch("plant")
	if limbo_hsm.can_harvest(): dispatch("harvest")
	if limbo_hsm.can_care(): dispatch("care")
	if local_holding != limbo_hsm.long_tool:
		dispatch("self")
	if Input.is_action_just_pressed("toggle_vehicle"): 
		if not Watcher.indoor:
			dispatch("bike")
	if limbo_hsm.cook: dispatch("cook")
