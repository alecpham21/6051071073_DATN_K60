extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var anim = $AnimationPlayer

func _ready():
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_scene(target_path: String, spawn_pos: Vector3):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	get_tree().paused = true
	
	anim.play("fade_in")
	await anim.animation_finished
	
	PlayerData.next_spawn_position = spawn_pos
	PlayerData.used_spawn_position = (spawn_pos != Vector3.ZERO)
	
	await get_tree().create_timer(0.5, true, false, true).timeout
	get_tree().change_scene_to_file(target_path)

func reveal_scene():

	get_tree().paused = false 
	
	await get_tree().create_timer(0.2).timeout 
	
	anim.play("fade_out")
	await anim.animation_finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_sleep_transition():
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	anim.play("fade_in")
	await anim.animation_finished
	
	await get_tree().create_timer(1.0).timeout 
	
	anim.play("fade_out")
	await anim.animation_finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
