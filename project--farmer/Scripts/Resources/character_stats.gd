class_name CharacterStats
extends Resource

signal stamina_depleted

@export var walk_speed: float = 5
@export var harvesting_speed : float = 2.5
@export var run_speed: float = 7
@export var cooking_speed: float = 5
@export var fishing_speed: float = 5
@export var sta_restore_speed: float = 5
@export var charisma: float = 5

@export var stamina : int = 20 :
	set(val):
		var was_positive = stamina > 0 
		stamina = val
		if stamina <= 0 and was_positive:
			stamina_depleted.emit()
