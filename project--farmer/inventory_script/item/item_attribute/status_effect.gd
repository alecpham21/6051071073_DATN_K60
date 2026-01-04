extends Resource
class_name StatusEffect

@export var effect_id: String = "buff_effect"

@export_enum("max_stamina", "restore_speed") var stat_type: String = "max_stamina"

@export var value: float = 0.0

@export var duration: float = 0.0
