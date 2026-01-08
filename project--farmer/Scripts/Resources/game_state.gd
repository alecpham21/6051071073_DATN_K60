extends Resource
class_name GState

enum state_enum {
	PLAYING,
	UI,
	PAUSED,
	COOK,
	RECIPE,
	DIALOG,
	SHOP,
	JOURNAL,
	BUILD,
	COOP
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
static func is_shop() -> bool: return game_state == state_enum.SHOP
static func is_journal() -> bool: return game_state == state_enum.JOURNAL
static func is_build() -> bool: return game_state == state_enum.BUILD
static func is_coop() -> bool: return game_state == state_enum.COOP

static func play(): 
	_change_state(state_enum.PLAYING)

static func ui(): 
	_change_state(state_enum.UI)

static func pause(): 
	_change_state(state_enum.PAUSED)

static func cook(): 
	if !lock_state: _change_state(state_enum.COOK)

static func recipe(): 
	if !lock_state: _change_state(state_enum.RECIPE)

static func dialog(): 
	_change_state(state_enum.DIALOG)

static func shop(): 
	_change_state(state_enum.SHOP)

static func journal():
	_change_state(state_enum.JOURNAL)

static func build():
	_change_state(state_enum.BUILD)

static func coop():
	_change_state(state_enum.COOP)

static func _change_state(new_state: int):
	if game_state == new_state: return
	
	var old_state = game_state
	game_state = new_state
	
	if GameData:
		GameData.game_state_changed.emit(old_state, new_state)
