extends Node
class_name FactionManager

var display_name: String = "FactionManager"
var reputations: Dictionary = {}
var factions: Dictionary = {}

func _ready():
	factions["Luminous Concord"] = {"archetype": "diplomatic", "home": "VeyraPrime"}
	factions["Ashborn Remnant"] = {"archetype": "martial", "home": "Ashduin"}
	factions["Hollow Choir"] = {"archetype": "mystic", "home": "HollowAnchor"}
	factions["Ferro Compact"] = {"archetype": "industrial", "home": "IronMeridian"}
	factions["Tidebound"] = {"archetype": "nomadic", "home": "TwoRivers"}
	factions["Ashborn"] = {"archetype": "exile", "home": "HushMarches"}
	for f in factions.keys():
		reputations[f] = 0

func modify_reputation(faction: String, delta: int):
	if reputations.has(faction):
		reputations[faction] = clamp(reputations[faction] + delta, -100, 100)

func get_reputation(faction: String) -> int:
	return reputations.get(faction, 0)

func get_standing(faction: String) -> String:
	var rep = get_reputation(faction)
	if rep >= 80: return "Revered"
	if rep >= 50: return "Honored"
	if rep >= 20: return "Friendly"
	if rep >= -20: return "Neutral"
	if rep >= -50: return "Unfriendly"
	if rep >= -80: return "Hostile"
	return "Hated"
