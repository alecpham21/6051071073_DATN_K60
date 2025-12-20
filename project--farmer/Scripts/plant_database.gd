extends Node

enum PLANT_VARIANT {NONE, WHEAT, CARROT, CORN, CABBAGE, SONION}

var plants = [
	null,
	preload("res://Plant/plant_wheat.tscn"),
	preload("res://Plant/plant_carrot.tscn"),
	preload("res://Plant/plant_corn.tscn"),
	preload("res://Plant/plant_cabbage.tscn"),
	preload("res://Plant/plant_spring_onion.tscn")
]

func get_plant_scene(type):
	if type >= 0 and type < plants.size():
		return plants[type]
	else:
		return null

func get_variant_from_seed(seed_name: String) -> PLANT_VARIANT:
	match seed_name:
		"wheat_seed":
			return PLANT_VARIANT.WHEAT
		"carrot_seed":
			return PLANT_VARIANT.CARROT
		"corn_seed":
			return PLANT_VARIANT.CORN
		"cabbage_seed":
			return PLANT_VARIANT.CABBAGE
		"spring_onion_seed":
			return PLANT_VARIANT.SONION
		_:
			return PLANT_VARIANT.NONE
