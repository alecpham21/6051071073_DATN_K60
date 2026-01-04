class_name ItemDataConsumable
extends ItemDataMaterial

@export var heal_value: int = 10 

@export var effects: Array[StatusEffect] = []

func use(target) -> void:
	# if target.has_method("heal"): target.heal(heal_value)
	# apply Buff/Debuff
	if target.get("stats"):
		for effect in effects:
			_apply_effect(target, effect)

# logic add buff
func _apply_effect(target, effect: StatusEffect):
	# func add_modifier of CharacterStats
	target.stats.add_modifier(effect.stat_type, effect.effect_id, effect.value)
	print("🍷 Used %s: %s [%s]" % [name, effect.effect_id, effect.value])
	
	# duration > 0
	if effect.duration > 0:
		var timer = target.get_tree().create_timer(effect.duration)
		
		timer.timeout.connect(func():
			if target and target.stats:
				target.stats.remove_modifier(effect.stat_type, effect.effect_id)
				print("🕒 Timeout %s" % effect.effect_id)
		)
		
