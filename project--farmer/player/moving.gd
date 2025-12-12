extends GardeningState

@export var run_ani: AnimationSet

func _update(delta: float) -> void:
	super(delta)
	
	if can_run and Input.is_action_pressed("running"):
		if run_ani:
			run_ani.play(character.ani)
	else:
		if ani_set:
			ani_set.play(character.ani)
func check_dispatch():
	if character.velocity.length() < 0.3: 
		dispatch("idle")
	if limbo_hsm.can_till(): dispatch("till")
	if limbo_hsm.can_plant(): dispatch("plant")
	if limbo_hsm.can_harvest(): dispatch("harvest")
	if limbo_hsm.can_care(): dispatch("care")
	if Input.is_action_just_pressed("toggle_vehicle"): 
		if not Watcher.indoor:
			dispatch("bike")
