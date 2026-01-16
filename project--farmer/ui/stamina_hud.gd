extends Control

@onready var progress_bar: TextureProgressBar = $TextureProgressBar
@onready var debuff_bar: ColorRect = $DebuffBar
@onready var hide_timer: Timer = $HideTimer

var fade_tween: Tween
var pixels_per_stamina: float = 0.0

var cached_base_max: float = 100.0

func _ready() -> void:
	modulate.a = 0 
	
	await get_tree().process_frame 
	
	if PlayerData.player and PlayerData.player.stats:
		var stats = PlayerData.player.stats
		
		cached_base_max = stats.base_max_stamina
		
		pixels_per_stamina = progress_bar.size.x / cached_base_max
		
		_connect_stats(stats)

func _connect_stats(stats: CharacterStats):
	if not stats.stamina_changed.is_connected(_on_stamina_update):
		stats.stamina_changed.connect(_on_stamina_update)
	
	_on_stamina_update(stats.stamina, stats.get_max_stamina())

func _on_stamina_update(current_val: float, max_val: float):
	progress_bar.max_value = max_val
	progress_bar.value = current_val
	
	
	var real_width = max_val * pixels_per_stamina
	
	var base_width = cached_base_max * pixels_per_stamina
	
	
	progress_bar.custom_minimum_size.x = real_width
	progress_bar.size.x = real_width
	
	var background_width = maxf(real_width, base_width)
	
	if debuff_bar:
		debuff_bar.custom_minimum_size.x = background_width
		debuff_bar.size.x = background_width
	
	# -----------------------------
	
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
