extends Resource
class_name ChickenData

@export var name: String = "Chicken"
@export var gender: LivestockEnums.Gender = LivestockEnums.Gender.FEMALE
@export var stage: LivestockEnums.Stage = LivestockEnums.Stage.BABY
@export var birthday: float = 0.0
@export var feed_count: int = 0
@export var egg_progress: float = 0.0

func get_max_feed() -> int:
	return 1 if gender == LivestockEnums.Gender.MALE else 2

func is_grown_up(current_time: float) -> bool:
	if stage == LivestockEnums.Stage.ADULT: return true
	return (current_time - birthday) >= (5 * 24 * 60)
