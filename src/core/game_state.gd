extends RefCounted
class_name GameState

var rng: RandomNumberGenerator
var entities: Array = []
var player: Actor = null
var current_system: String = "VeyraPrime"
var current_year: int = 706
var play_time: float = 0.0
var discovered_systems: Array = []
var active_quests: Array = []
var completed_quests: Array = []
var world_events: Array = []
var event_history: Array = []

func _init(seed_val: int = 0):
	rng = RandomNumberGenerator.new()
	if seed_val == 0:
		seed_val = randi()
	rng.seed = seed_val
	discovered_systems.append("VeyraPrime")

func add_entity(entity):
	entities.append(entity)
	if entity is Actor and entity.is_player:
		player = entity

func remove_entity(entity):
	entities.erase(entity)
	if entity == player:
		player = null

func update(dt: float):
	play_time += dt
	for e in entities:
		if e.has_method("update"):
			e.update(dt)
