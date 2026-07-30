extends Node
class_name GameEngine

@export var tick_rate: int = 30
var dt: float = 1.0 / 30.0
var subsystems: Dictionary = {}
var bus: EventBus
var state: GameState
var running: bool = false
var frame: int = 0

func _ready():
	bus = EventBus.new()
	state = GameState.new()
	print("[Engine] Initialized")

func register(subsystem):
	subsystem.engine = self
	subsystems[subsystem.name] = subsystem
	add_child(subsystem)
	return subsystem

func step():
	frame += 1
	for sub in subsystems.values():
		if sub.has_method("update"):
			sub.update(dt)
	state.update(dt)
	bus.flush()

func _process(delta):
	if running:
		step()
