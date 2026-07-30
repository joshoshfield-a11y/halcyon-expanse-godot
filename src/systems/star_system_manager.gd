extends Node
class_name StarSystemManager

var name: String = "StarSystemManager"
var systems: Dictionary = {}
var current_system: String = "VeyraPrime"

func _ready():
	systems["VeyraPrime"] = {"biome": "temperate", "neighbors": ["Ashduin", "TwoRivers"], "danger": 1}
	systems["Ashduin"] = {"biome": "volcanic", "neighbors": ["VeyraPrime", "HollowAnchor"], "danger": 2}
	systems["TwoRivers"] = {"biome": "river", "neighbors": ["VeyraPrime", "HushMarches"], "danger": 1}
	systems["HollowAnchor"] = {"biome": "void", "neighbors": ["Ashduin", "IronMeridian"], "danger": 3}
	systems["HushMarches"] = {"biome": "marsh", "neighbors": ["TwoRivers", "ChorusDeep"], "danger": 2}
	systems["IronMeridian"] = {"biome": "industrial", "neighbors": ["HollowAnchor", "ChorusDeep"], "danger": 2}
	systems["ChorusDeep"] = {"biome": "crystal", "neighbors": ["HushMarches", "IronMeridian"], "danger": 3}
	systems["BareMeridian"] = {"biome": "barren", "neighbors": ["VeyraPrime"], "danger": 1}
	systems["GreyReef"] = {"biome": "reef", "neighbors": ["TwoRivers"], "danger": 2}

func get_available_warp_targets(system_name: String = "") -> Array:
	var sys = system_name if system_name != "" else current_system
	if systems.has(sys):
		return systems[sys]["neighbors"].duplicate()
	return []

func warp(target_name: String) -> bool:
	var targets = get_available_warp_targets()
	if target_name in targets:
		current_system = target_name
		return true
	return false

func get_system_data(name: String) -> Dictionary:
	return systems.get(name, {})
