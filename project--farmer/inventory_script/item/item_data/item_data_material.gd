extends ItemData
class_name ItemDataMaterial

enum MaterialType { 
	NONE,
	RAW_MATERIAL,
	COOK_MATERIAL,
	COOKED_MATERIAL
}

@export var material_type: MaterialType = MaterialType.RAW_MATERIAL
