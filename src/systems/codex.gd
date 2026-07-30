extends Node
class_name Codex

var name: String = "Codex"
var entries: Dictionary = {}
var unlocked: Array = []

func _ready():
	entries["era_0"] = {"title": "The Shattering", "year": 0, "text": "The lattice fractured. Stars went dark."}
	entries["era_1"] = {"title": "First Resonance", "year": 89, "text": "The first attuned discovered they could hear the lattice."}
	entries["era_2"] = {"title": "Concord Founding", "year": 234, "text": "The Luminous Concord united the scattered colonies."}
	entries["era_3"] = {"title": "Hollow War", "year": 412, "text": "The Choir emerged from the void. Billions lost."}
	entries["era_4"] = {"title": "Iron Pact", "year": 567, "text": "The Ferro Compact seized the Meridian foundries."}
	entries["era_5"] = {"title": "Current Era", "year": 706, "text": "You stand at the edge of known space."}

func unlock(entry_id: String):
	if entries.has(entry_id) and entry_id not in unlocked:
		unlocked.append(entry_id)

func is_unlocked(entry_id: String) -> bool:
	return entry_id in unlocked

func get_entry(entry_id: String) -> Dictionary:
	return entries.get(entry_id, {})
