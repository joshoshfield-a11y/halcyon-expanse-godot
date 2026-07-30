extends RefCounted
class_name EventBus

var _subs: Dictionary = {}
var _queue: Array = []

func subscribe(event_type: String, callback: Callable):
	if not _subs.has(event_type):
		_subs[event_type] = []
	_subs[event_type].append(callback)

func emit(event_type: String, payload = null):
	_queue.append({"type": event_type, "payload": payload})

func flush():
	while _queue.size() > 0:
		var evt = _queue.pop_front()
		var cbs = _subs.get(evt["type"], [])
		for cb in cbs:
			cb.call(evt["payload"])
