extends Resource
class_name TimerKit

static func generate_timer(duration:float, call:Callable, oneshot:bool = true) -> Timer:
	var tim:Timer = Timer.new()
	tim.wait_time = duration
	tim.autostart = true
	tim.one_shot = oneshot
	if oneshot: tim.timeout.connect(func(): tim.queue_free())
	tim.timeout.connect(call)
	return tim
