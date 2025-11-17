class_name CharacterState
extends LimboState

#@export var state_name_res:StateNames
@export var transition_to:Dictionary[StringName, CharacterState]
@export var play_default_ani := true
@export var self_dispatch := false
@export var reset_ani := false
@export var phase := false
@export var halt := false
@export var ani_set : AnimationSet

var character : Character
var limbo_hsm : LimboPrimeHSM
var input : PlayerInput

func _setup() -> void:
	limbo_hsm = get_parent()
	character = agent as Character
	input = (character as Player).input
	for i:StringName in transition_to.keys():
		limbo_hsm.add_transition(self, transition_to[i], i)

func _enter() -> void:
	print("Entered ", self.name, " state.")
	if play_default_ani: ani_set.play(character.ani)

func _exit() -> void:
	#print("Exited state %s."%[self.name])
	if reset_ani: character.ani.play("RESET")

func self_dispatched() -> bool:
	return limbo_hsm.prev == self
