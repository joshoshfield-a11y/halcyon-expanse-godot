extends RefCounted
class_name SkinDB

const SKINS: Dictionary = {
	"Ember":   {"body": Color(0.95, 0.35, 0.1),  "glow": Color(0.9, 0.45, 0.1),  "accent": Color(0.18, 0.2, 0.26)},
	"Frost":   {"body": Color(0.35, 0.65, 0.95), "glow": Color(0.4, 0.85, 1.0),  "accent": Color(0.12, 0.16, 0.24)},
	"Verdant": {"body": Color(0.3, 0.75, 0.35),  "glow": Color(0.45, 1.0, 0.4),  "accent": Color(0.12, 0.2, 0.14)},
	"Royal":   {"body": Color(0.55, 0.3, 0.85),  "glow": Color(0.75, 0.4, 1.0),  "accent": Color(0.16, 0.12, 0.24)},
	"Onyx":    {"body": Color(0.14, 0.14, 0.18), "glow": Color(1.0, 0.75, 0.2),  "accent": Color(0.06, 0.06, 0.08)},
}
const PATH: String = "user://halcyon.cfg"

static func current() -> String:
	var cfg = ConfigFile.new()
	if cfg.load(PATH) == OK:
		var s = str(cfg.get_value("player", "skin", "Ember"))
		if SKINS.has(s):
			return s
	return "Ember"

static func select(skin_id: String):
	if not SKINS.has(skin_id):
		return
	var cfg = ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("player", "skin", skin_id)
	cfg.save(PATH)

static func palette(skin_id: String) -> Dictionary:
	return SKINS.get(skin_id, SKINS["Ember"])
