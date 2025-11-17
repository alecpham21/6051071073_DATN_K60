extends ItemData
class_name ItemDataOutfit

enum OutfitType { HEAD, BODY, LEGS}

@export var outfit_type: OutfitType = OutfitType.BODY
@export var equip_mesh: Mesh
