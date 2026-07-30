extends Node
class_name Bestiary

var name: String = "Bestiary"
var entries: Dictionary = {}
var discovered: Array = []

func _ready():
	entries["Ash Wraith"] = {
		"hp": 80, "damage": 12, "speed": 2.5, "pattern": "phase_cycle",
		"resistance": "Ember", "weakness": "Tide", "xp": 25,
		"description": "A drifting specter of cinder and sorrow."
	}
	entries["Hollow Stalker"] = {
		"hp": 60, "damage": 15, "speed": 3.5, "pattern": "stealth_ambush",
		"resistance": "Hollow", "weakness": "Chorus", "xp": 30,
		"description": "Invisible until it strikes from the void."
	}
	entries["Iron Drone"] = {
		"hp": 120, "damage": 10, "speed": 1.8, "pattern": "patrol_loop",
		"resistance": "Iron", "weakness": "Ember", "xp": 20,
		"description": "Automated sentry of the Ferro Compact."
	}
	entries["Tide Serpent"] = {
		"hp": 100, "damage": 18, "speed": 2.2, "pattern": "area_pulse",
		"resistance": "Tide", "weakness": "Root", "xp": 35,
		"description": "A serpent of flowing lattice energy."
	}
	entries["Chorus Knight"] = {
		"hp": 150, "damage": 20, "speed": 2.0, "pattern": "buff_ally",
		"resistance": "Chorus", "weakness": "Hollow", "xp": 40,
		"description": "Harmonic warrior that strengthens allies."
	}
	entries["Swarm Mite"] = {
		"hp": 30, "damage": 8, "speed": 4.0, "pattern": "swarm_split",
		"resistance": "Gale", "weakness": "Iron", "xp": 15,
		"description": "Splits into smaller mites when damaged."
	}

func discover(enemy_type: String):
	if entries.has(enemy_type) and enemy_type not in discovered:
		discovered.append(enemy_type)

func get_entry(enemy_type: String) -> Dictionary:
	return entries.get(enemy_type, {})
