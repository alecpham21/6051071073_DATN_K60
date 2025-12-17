extends Resource
class_name GState

enum state_enum {
	PLAYING,
	UI,
	PAUSED,
	COOK,
	RECIPE,
	DIALOG
}

static var game_state:int = 0
static var lock_state:bool = false

static func is_playing() -> bool: return game_state == state_enum.PLAYING
static func is_ui() -> bool: return game_state == state_enum.UI
static func is_paused() -> bool: return game_state == state_enum.PAUSED
static func reset(): game_state = state_enum.PLAYING
static func is_cook() -> bool: return game_state == state_enum.COOK
static func is_recipe() -> bool: return game_state == state_enum.RECIPE
static func is_dialog() -> bool: return game_state == state_enum.DIALOG

static func play(): game_state = state_enum.PLAYING
static func ui(): game_state = state_enum.UI
static func pause(): game_state = state_enum.PAUSED
static func cook(): if !lock_state: game_state = state_enum.COOK
static func recipe(): if !lock_state: game_state = state_enum.RECIPE
static func dialog(): game_state = state_enum.DIALOG
