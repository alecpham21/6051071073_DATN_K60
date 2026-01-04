extends MainState
class_name TiredState

@export var tired_run_ani: AnimationSet
@export var tired_farm_ani: AnimationSet

func _enter() -> void:
	super()
	print("😫 IM TIRED!")
	
	character.is_busy = true 
	character.velocity = Vector3.ZERO
	
	var cause = blackboard.get_var("tired_cause", "run")
	
	var anim_to_play = tired_run_ani
	
	if cause == "farm":
		if tired_farm_ani: anim_to_play = tired_farm_ani
	else:
		if tired_run_ani: anim_to_play = tired_run_ani
	
	if anim_to_play:
		anim_to_play.play(character.ani)
		await character.ani.animation_finished
	else:
		await get_tree().create_timer(2.0).timeout
	
	character.stats.stamina = 5.0
	
	dispatch("idle")

func _exit() -> void:
	super()
	character.is_busy = false
