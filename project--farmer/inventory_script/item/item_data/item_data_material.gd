extends ItemData
class_name ItemDataMaterial

enum MaterialType { 
	NONE,
	RAW_MATERIAL,
	COOK_MATERIAL,
	COOKED_MATERIAL
}
enum SellingType{
	GENERIC,
	FRUJT,
	VEGETABLE,
	FISH
}

@export var material_type: MaterialType = MaterialType.RAW_MATERIAL
@export var selling_type: SellingType = SellingType.GENERIC
@export var sell_price: int = 40
