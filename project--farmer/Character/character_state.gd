class_name CharacterState
extends LimboState

#@export var state_name_res:StateNames
@export var state_name:StringName = ""
@export var transition_to:Dictionary[StringName, CharacterState]
@export var play_default_ani := true
@export var self_dispatch := false
@export var reset_ani := false
@export var phase := false
@export var halt := false
@export var ani_set : AnimationSet
@export var safe_guard:bool = false
@export var safe_guard_duration:float = 3

var character : Character
var limbo_hsm : LimboPrimeHSM
var input : PlayerInput
signal overtimed

func _setup() -> void:
	limbo_hsm = get_parent()
	character = agent as Character
	input = agent.get("input") 
	
	for i:StringName in transition_to.keys():
		limbo_hsm.add_transition(self, transition_to[i], i)
	if self_dispatch: 
		limbo_hsm.add_transition(self, self, "self")

func _enter() -> void:
	print("Entered ", self.name, " state.")
	# Thêm "and ani_set" để chắc chắn nó không bị Rỗng
	if play_default_ani and ani_set: ani_set.play(character.ani)
	if safe_guard: add_child(TimerKit.generate_timer(safe_guard_duration, func(): overtimed.emit(), true, true))

func _exit() -> void:
	#print("Exited state %s."%[self.name])
	if reset_ani: character.ani.play("RESET")

func check_dispatch(): pass

func self_dispatched() -> bool:
	return limbo_hsm.prev == self

func _update(delta: float) -> void:
	check_dispatch()
