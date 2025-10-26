extends Node

enum PLANT_VARIANT {NONE, WHEAT, CARROT, CORN}

var plants = [
	null,
	preload("res://Plant/plant_wheat.tscn"),
	preload("res://Plant/plant_carrot.tscn"),
	preload("res://Plant/plant_corn.tscn")
]

func get_plant_node(type):
	if plants[type] != null:
		var plant = plants[type].instantiate()
		return plant
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
		_:
			return PLANT_VARIANT.NONE
