extends MainState
class_name CookingState

@export_group("Animation Sets")
@export var pan_aniset: AnimationSet
@export var cutting_aniset: AnimationSet

@export_group("Visual Props")
@export var pan_prop: Node3D
@export var knife_prop: Node3D 

var active: bool = false

func _enter() -> void:
	super()
	
	limbo_hsm.cook = false
	
	# 2. Chọn AnimationSet dựa trên cook_mode
	var mode = limbo_hsm.cook_mode
	
	if mode == LimboPrimeHSM.COOK_MODE.STOVE:
		if pan_prop: pan_prop.visible = true
		if pan_aniset: pan_aniset.play(character.ani)
		
	elif mode == LimboPrimeHSM.COOK_MODE.BOARD:
		if knife_prop: knife_prop.visible = true
		if cutting_aniset: cutting_aniset.play(character.ani)
	
	# 3. Kết nối signal khi animation chạy xong -> Về Idle
	if not character.ani.animation_finished.is_connected(_on_animation_finished):
		character.ani.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
		
	get_tree().create_timer(3.0).timeout.connect(func(): if active: dispatch("idle"), CONNECT_ONE_SHOT)

func _on_animation_finished(_anim_name: String):
	dispatch("idle")

func _exit() -> void:
	super()
	if pan_prop: pan_prop.visible = false
	if knife_prop: knife_prop.visible = false
