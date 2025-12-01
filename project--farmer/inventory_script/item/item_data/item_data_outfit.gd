class_name ItemDataOutfit
extends ItemData

enum OutfitType { HEAD, BODY, LEGS }
enum BodyPart { BASE, FEETS, LEGS, LOWER_BODY, UPPER_BODY }

@export var outfit_type: OutfitType = OutfitType.BODY
@export var equip_mesh: Mesh
@export var hidden_body_parts: Array[BodyPart] = []


@export var max_dirt_level: float = 100.0
