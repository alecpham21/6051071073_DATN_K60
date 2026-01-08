extends Control

@onready var progress_bar: TextureProgressBar = $TextureProgressBar
@onready var hide_timer: Timer = $HideTimer

var fade_tween: Tween

var pixels_per_stamina: float = 0.0

func _ready() -> void:
	modulate.a = 0 
	
	await get_tree().process_frame 
	
	if PlayerData.player and PlayerData.player.stats:
		var base_max = PlayerData.player.stats.base_max_stamina
		pixels_per_stamina = progress_bar.size.x / base_max
		
		_connect_stats(PlayerData.player.stats)
		
		#_on_stamina_update(PlayerData.player.stats.stamina, PlayerData.player.statsstats.get_max_stamina())

func _connect_stats(stats: CharacterStats):
	if not stats.stamina_changed.is_connected(_on_stamina_update):
		stats.stamina_changed.connect(_on_stamina_update)
	
	_on_stamina_update(stats.stamina, stats.get_max_stamina())

func _on_stamina_update(current_val: float, max_val: float):
	
	progress_bar.max_value = max_val
	progress_bar.value = current_val
	
	var new_width = max_val * pixels_per_stamina
	
	progress_bar.custom_minimum_size.x = new_width
	progress_bar.size.x = new_width 
	
	if current_val < max_val:
		_show_bar()
	else:
		if hide_timer.is_stopped():
			hide_timer.start()

func _show_bar():
	hide_timer.stop()
	
	if fade_tween: fade_tween.kill()
	
	modulate.a = 1.0

func _on_hide_timer_timeout() -> void:
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
