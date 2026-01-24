extends Node

signal tick

var day: int = 1 

@export var tick_time: float = 0.1
var time_from_last_tick: float = 0.0

@export_group("Time Settings")
@export var current_time: float = 480.0 
@export var speed_multiplier: float = 20.0
@export var day_length_hours: int = 24
 
var is_sleeping: bool = false 

var current_hour: int:
	get:
		return int(current_time / 60.0)

var total_game_minutes: float

func _ready():
	total_game_minutes = day_length_hours * 60.0

func _process(delta):
	if is_sleeping: return
	time_from_last_tick += delta
	if time_from_last_tick >= tick_time:
		time_from_last_tick = 0.0
		tick.emit()
		
	current_time += delta * speed_multiplier
	
	check_new_day()

func check_new_day():
	while current_time >= total_game_minutes:
		current_time -= total_game_minutes
		day += 1
		print("📅 Day: ", day)
		
		if not is_sleeping:
			if PlayerData.player and PlayerData.player.stats:
				print("🚫 No sleep! (Penalty Applied)")
				PlayerData.player.stats.add_modifier("max_stamina", "no_sleep", -0.4)

func get_total_minutes_played() -> int:
	return (day - 1) * total_game_minutes + current_time
