class_name CharacterStats
extends Resource

signal stamina_depleted
signal stamina_changed(new_val, max_val)
signal modifier_changed(name, value)

@export_group("Attributes")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var harvesting_speed : float = 2.5
@export var cooking_speed: float = 5.0
@export var fishing_speed: float = 5.0
@export var charisma: float = 5.0

@export_group("Stamina System")
@export var base_max_stamina: float = 100.0
@export var base_restore_speed: float = 15.0
@export var run_cost_per_sec: float = 10.0
@export var action_cost: float = 15.0

@export var stamina: float = 100.0:
	set(val):
		var current_limit = get_max_stamina()
		var old_val = stamina
		
		stamina = clampf(val, 0.0, current_limit)
		
		if old_val > 0 and stamina <= 0:
			stamina_depleted.emit()
		
		stamina_changed.emit(stamina, current_limit)


var max_stamina_modifiers: Dictionary = {}
var restore_speed_modifiers: Dictionary = {}

func _init():
	stamina = base_max_stamina

func get_max_stamina() -> float:
	var total_mod = 0.0
	for mod in max_stamina_modifiers.values():
		total_mod += mod
	return base_max_stamina * maxf(0.1, (1.0 + total_mod))

func get_restore_speed() -> float:
	var total_mod = 0.0
	for mod in restore_speed_modifiers.values():
		total_mod += mod
	return base_restore_speed * maxf(0.0, (1.0 + total_mod))

func has_stamina(amount: float) -> bool:
	return stamina >= amount

func add_modifier(stat_type: String, id: String, value: float):
	
	if stat_type == "max_stamina":
		max_stamina_modifiers[id] = value
		var current_max = get_max_stamina()
		if stamina > current_max: stamina = current_max
		stamina_changed.emit(stamina, current_max)
		
	elif stat_type == "restore_speed":
		restore_speed_modifiers[id] = value
	
	modifier_changed.emit(id, value)
	print("➕ Added Modifier [%s]: %s" % [id, value])

func remove_modifier(stat_type: String, id: String):
	if stat_type == "max_stamina":
		max_stamina_modifiers.erase(id)
		stamina_changed.emit(stamina, get_max_stamina())
		
	elif stat_type == "restore_speed":
		restore_speed_modifiers.erase(id)
		
	print("➖ Removed Modifier [%s]" % id)

func clear_all_debuffs():
	remove_modifier("max_stamina", "exhaustion")
	remove_modifier("restore_speed", "exhaustion")
	overexertion_count = 0

var overexertion_count: int = 0
var overexertion_limit: int = 3

func report_force_work():
	if max_stamina_modifiers.has("exhaustion"): return
	
	overexertion_count += 1
	print("⚠️ Over-exertion warning: ", overexertion_count)
	
	if overexertion_count >= overexertion_limit:
		add_modifier("max_stamina", "exhaustion", -0.3)
		add_modifier("restore_speed", "exhaustion", -0.5)

func consume(amount: float):
	stamina -= amount

func regenerate(amount: float):
	var limit = get_max_stamina()
	if stamina < limit:
		stamina += amount

func sleep_recovery(sleep_hour: int):
	clear_all_debuffs()
	
	if sleep_hour >= 0 and sleep_hour < 3:
		add_modifier("max_stamina", "late_sleep", -0.2)
		add_modifier("restore_speed", "late_sleep", -0.1)
		print("🌙 Ngủ hơi muộn: Giảm nhẹ stamina")
		
	elif sleep_hour >= 3 and sleep_hour < 6:
		add_modifier("max_stamina", "too_late_sleep", -0.4)
		print("💀 Ngủ quá muộn: Giảm mạnh stamina")
		
	stamina = get_max_stamina()
