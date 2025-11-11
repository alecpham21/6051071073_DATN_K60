extends Resource
class_name GState

enum state_enum {
	PLAYING,
	UI,
	PAUSED
}

static var game_state:int = 0

static func is_playing() -> bool: return game_state == state_enum.PLAYING
static func is_ui() -> bool: return game_state == state_enum.UI
static func is_paused() -> bool: return game_state == state_enum.PAUSED

static func play(): game_state = state_enum.PLAYING
static func ui(): game_state = state_enum.UI
static func pause(): game_state = state_enum.PAUSED
