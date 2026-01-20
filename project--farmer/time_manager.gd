extends Node

signal tick

var day: int = 1 

@export var tick_time: float = 0.1
var time_from_last_tick: float = 0.0

@export_group("Time Settings")
@export var current_time: float = 480.0 
@export var speed_multiplier: float = 5.0
@export var day_length_hours: int = 24

var current_hour: int:
	get:
		return int(current_time / 60.0)

var total_game_minutes: float

func _ready():
	total_game_minutes = day_length_hours * 60.0

func _process(delta):
	time_from_last_tick += delta
	if time_from_last_tick >= tick_time:
		time_from_last_tick = 0.0
		tick.emit()
		
	current_time += delta * speed_multiplier
	
	while current_time >= total_game_minutes:
		current_time -= total_game_minutes
		day += 1
		print("📅 Sang ngày thứ: ", day)
		if PlayerData.player and PlayerData.player.stats:
			PlayerData.player.stats.add_modifier("max_stamina", "no_sleep", -0.4)

func get_total_minutes_played() -> int:
	return (day - 1) * total_game_minutes + current_time
