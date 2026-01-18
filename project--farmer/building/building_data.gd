extends Resource
class_name BuildingData


enum BuildingCategory {
	HOUSE,
	FARM,
	DECORATION,
	STRUCTURE,
	QUEST
}

@export_group("Identity")
@export var id: String = "building_id"
@export var name: String = "Building Name"
@export var category: BuildingCategory = BuildingCategory.HOUSE

@export_group("Requirements")
@export var required_item: ItemData
@export var item_cost: int = 0

@export_group("Visuals")
@export var icon: Texture2D
@export var scene: PackedScene
@export var size: Vector2i = Vector2i(2, 2)
@export var offset: Vector3 = Vector3(0, 0, 0)
@export var scale: Vector3 = Vector3(1, 1, 1)
